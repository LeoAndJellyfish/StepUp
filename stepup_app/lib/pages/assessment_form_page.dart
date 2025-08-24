import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../theme/app_theme.dart';
import '../models/assessment_item.dart';
import '../models/category.dart';
import '../services/assessment_item_dao.dart';
import '../services/category_dao.dart';
import '../services/event_bus.dart';
import '../widgets/common_widgets.dart';

class AssessmentFormPage extends StatefulWidget {
  final int? itemId;

  const AssessmentFormPage({Key? key, this.itemId}) : super(key: key);

  @override
  State<AssessmentFormPage> createState() => _AssessmentFormPageState();
}

class _AssessmentFormPageState extends State<AssessmentFormPage> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _scoreController = TextEditingController();
  final _durationController = TextEditingController();
  
  final AssessmentItemDao _assessmentItemDao = AssessmentItemDao();
  final CategoryDao _categoryDao = CategoryDao();
  final EventBus _eventBus = EventBus();
  
  List<Category> _categories = [];
  int? _selectedCategoryId;
  DateTime _selectedDate = DateTime.now();
  bool _isLoading = true;
  bool _isSaving = false;
  AssessmentItem? _currentItem;

  bool get isEditing => widget.itemId != null;

  @override
  void initState() {
    super.initState();
    _loadData();
  }
  
  Future<void> _loadData() async {
    try {
      final categories = await _categoryDao.getAllCategories();
      
      if (isEditing) {
        final item = await _assessmentItemDao.getItemById(widget.itemId!);
        if (item != null) {
          _currentItem = item;
          _titleController.text = item.title;
          _descriptionController.text = item.description;
          _scoreController.text = item.score.toString();
          _durationController.text = item.duration.toString();
          _selectedCategoryId = item.categoryId;
          _selectedDate = item.activityDate;
        }
      }
      
      setState(() {
        _categories = categories;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('加载数据失败: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(isEditing ? '编辑条目' : '添加条目'),
        actions: [
          if (isEditing) ...[
            IconButton(
              onPressed: _isSaving ? null : () => _showDeleteConfirmDialog(),
              icon: const Icon(Icons.delete, color: Colors.red),
              tooltip: '删除条目',
            ),
          ],
          TextButton(
            onPressed: _isSaving ? null : _saveItem,
            child: _isSaving
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Text('保存'),
          ),
        ],
      ),
      body: _isLoading
          ? const LoadingWidget(message: '加载中...')
          : Form(
              key: _formKey,
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(AppTheme.spacing16),
                child: Column(
                  children: [
                    TextFormField(
                      controller: _titleController,
                      decoration: const InputDecoration(
                        labelText: '活动名称',
                        hintText: '请输入活动名称',
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return '请输入活动名称';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: AppTheme.spacing16),
                    TextFormField(
                      controller: _descriptionController,
                      decoration: const InputDecoration(
                        labelText: '活动描述',
                        hintText: '请输入活动描述',
                      ),
                      maxLines: 3,
                    ),
                    const SizedBox(height: AppTheme.spacing16),
                    DropdownButtonFormField<int>(
                      value: _selectedCategoryId,
                      decoration: const InputDecoration(
                        labelText: '分类',
                        hintText: '请选择分类',
                      ),
                      items: _categories.map((category) {
                        return DropdownMenuItem<int>(
                          value: category.id,
                          child: Text(category.name),
                        );
                      }).toList(),
                      onChanged: (value) {
                        setState(() {
                          _selectedCategoryId = value;
                        });
                      },
                      validator: (value) {
                        if (value == null) {
                          return '请选择分类';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: AppTheme.spacing16),
                    TextFormField(
                      controller: _scoreController,
                      decoration: const InputDecoration(
                        labelText: '得分',
                        hintText: '请输入得分',
                        suffixText: '分',
                      ),
                      keyboardType: TextInputType.number,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return '请输入得分';
                        }
                        if (double.tryParse(value) == null) {
                          return '请输入有效的数字';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: AppTheme.spacing16),
                    TextFormField(
                      controller: _durationController,
                      decoration: const InputDecoration(
                        labelText: '时长',
                        hintText: '请输入时长',
                        suffixText: '小时',
                      ),
                      keyboardType: TextInputType.number,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return '请输入时长';
                        }
                        if (double.tryParse(value) == null) {
                          return '请输入有效的数字';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: AppTheme.spacing16),
                    InkWell(
                      onTap: _selectDate,
                      child: InputDecorator(
                        decoration: const InputDecoration(
                          labelText: '活动日期',
                          suffixIcon: Icon(Icons.calendar_today),
                        ),
                        child: Text(
                          '${_selectedDate.year}-${_selectedDate.month.toString().padLeft(2, '0')}-${_selectedDate.day.toString().padLeft(2, '0')}',
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
    );
  }

  Future<void> _selectDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
      });
    }
  }

  Future<void> _saveItem() async {
    if (_formKey.currentState!.validate()) {
      setState(() {
        _isSaving = true;
      });
      
      try {
        final now = DateTime.now();
        final item = AssessmentItem(
          id: _currentItem?.id,
          title: _titleController.text.trim(),
          description: _descriptionController.text.trim(),
          categoryId: _selectedCategoryId!,
          score: double.parse(_scoreController.text),
          duration: double.parse(_durationController.text),
          activityDate: _selectedDate,
          createdAt: _currentItem?.createdAt ?? now,
          updatedAt: now,
        );
        
        if (isEditing) {
          await _assessmentItemDao.updateItem(item);
        } else {
          await _assessmentItemDao.insertItem(item);
        }
        
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(isEditing ? '更新成功' : '添加成功')),
          );
          // 触发数据变更事件
          _eventBus.emit(AppEvent.assessmentItemChanged);
          context.pop(true); // 返回true表示有数据变更
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('保存失败: $e')),
          );
        }
      } finally {
        if (mounted) {
          setState(() {
            _isSaving = false;
          });
        }
      }
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _scoreController.dispose();
    _durationController.dispose();
    super.dispose();
  }

  // 显示删除确认对话框
  void _showDeleteConfirmDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('确认删除'),
        content: Text('确定要删除条目「${_currentItem?.title}」吗？此操作不可撤销。'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('取消'),
          ),
          FilledButton(
            onPressed: () async {
              Navigator.of(context).pop();
              await _deleteItem();
            },
            style: FilledButton.styleFrom(
              backgroundColor: Colors.red,
            ),
            child: const Text('删除'),
          ),
        ],
      ),
    );
  }

  // 删除条目
  Future<void> _deleteItem() async {
    if (_currentItem?.id == null) return;
    
    setState(() {
      _isSaving = true;
    });
    
    try {
      await _assessmentItemDao.deleteItem(_currentItem!.id!);
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('已删除条目「${_currentItem!.title}」')),
        );
        // 触发数据变更事件
        _eventBus.emit(AppEvent.assessmentItemChanged);
        context.pop(true); // 返回true表示有数据变更
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('删除失败: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSaving = false;
        });
      }
    }
  }
}