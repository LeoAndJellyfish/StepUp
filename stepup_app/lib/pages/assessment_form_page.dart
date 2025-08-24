import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../theme/app_theme.dart';
import '../models/assessment_item.dart';
import '../models/category.dart';
import '../models/subcategory.dart';
import '../models/level.dart';
import '../models/tag.dart';
import '../services/assessment_item_dao.dart';
import '../services/category_dao.dart';
import '../services/subcategory_dao.dart';
import '../services/level_dao.dart';
import '../services/tag_dao.dart';
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
  final _participantCountController = TextEditingController(text: '1');
  final _awardLevelController = TextEditingController();
  final _remarksController = TextEditingController();
  
  final AssessmentItemDao _assessmentItemDao = AssessmentItemDao();
  final CategoryDao _categoryDao = CategoryDao();
  final SubcategoryDao _subcategoryDao = SubcategoryDao();
  final LevelDao _levelDao = LevelDao();
  final TagDao _tagDao = TagDao();
  final EventBus _eventBus = EventBus();
  
  List<Category> _categories = [];
  List<Subcategory> _subcategories = [];
  List<Level> _levels = [];
  List<Tag> _tags = [];
  
  int? _selectedCategoryId;
  int? _selectedSubcategoryId;
  int? _selectedLevelId;
  List<int> _selectedTagIds = [];
  
  DateTime _selectedDate = DateTime.now();
  bool _isAwarded = false;
  bool _isCollective = false;
  bool _isLeader = false;
  
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
      final levels = await _levelDao.getAllLevels();
      final tags = await _tagDao.getAllTags();
      
      if (isEditing) {
        final item = await _assessmentItemDao.getItemById(widget.itemId!);
        if (item != null) {
          _currentItem = item;
          _titleController.text = item.title;
          _descriptionController.text = item.description;
          _scoreController.text = item.score.toString();
          _durationController.text = item.duration.toString();
          _participantCountController.text = item.participantCount.toString();
          _awardLevelController.text = item.awardLevel ?? '';
          _remarksController.text = item.remarks ?? '';
          
          _selectedCategoryId = item.categoryId;
          _selectedSubcategoryId = item.subcategoryId;
          _selectedLevelId = item.levelId;
          _selectedDate = item.activityDate;
          _isAwarded = item.isAwarded;
          _isCollective = item.isCollective;
          _isLeader = item.isLeader;
          
          // 加载条目的标签
          if (item.id != null) {
            final itemTags = await _tagDao.getTagsByAssessmentItemId(item.id!);
            _selectedTagIds = itemTags.map((tag) => tag.id!).toList();
          }
          
          // 如果有选中的分类，加载对应的子分类
          if (_selectedCategoryId != null) {
            final subcategories = await _subcategoryDao.getSubcategoriesByCategoryId(_selectedCategoryId!);
            _subcategories = subcategories;
          }
        }
      }
      
      setState(() {
        _categories = categories;
        _levels = levels;
        _tags = tags;
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
                    // 活动名称
                    TextFormField(
                      controller: _titleController,
                      decoration: const InputDecoration(
                        labelText: '活动名称 *',
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
                    
                    // 活动描述
                    TextFormField(
                      controller: _descriptionController,
                      decoration: const InputDecoration(
                        labelText: '活动描述',
                        hintText: '请输入活动描述',
                      ),
                      maxLines: 3,
                    ),
                    const SizedBox(height: AppTheme.spacing16),
                    
                    // 主分类
                    DropdownButtonFormField<int>(
                      initialValue: _selectedCategoryId,
                      decoration: const InputDecoration(
                        labelText: '主分类 *',
                        hintText: '请选择主分类',
                      ),
                      items: _categories.map((category) {
                        return DropdownMenuItem<int>(
                          value: category.id,
                          child: Text('${category.name} (${category.code})'),
                        );
                      }).toList(),
                      onChanged: (value) {
                        setState(() {
                          _selectedCategoryId = value;
                          _selectedSubcategoryId = null; // 重置子分类
                          _subcategories = [];
                        });
                        if (value != null) {
                          _loadSubcategories(value);
                        }
                      },
                      validator: (value) {
                        if (value == null) {
                          return '请选择主分类';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: AppTheme.spacing16),
                    
                    // 子分类
                    if (_subcategories.isNotEmpty) ...[
                      DropdownButtonFormField<int>(
                        initialValue: _selectedSubcategoryId,
                        decoration: const InputDecoration(
                          labelText: '子分类',
                          hintText: '请选择子分类',
                        ),
                        items: _subcategories.map((subcategory) {
                          return DropdownMenuItem<int>(
                            value: subcategory.id,
                            child: Text('${subcategory.name} (${subcategory.code})'),
                          );
                        }).toList(),
                        onChanged: (value) {
                          setState(() {
                            _selectedSubcategoryId = value;
                          });
                        },
                      ),
                      const SizedBox(height: AppTheme.spacing16),
                    ],
                    
                    // 活动级别
                    DropdownButtonFormField<int>(
                      initialValue: _selectedLevelId,
                      decoration: const InputDecoration(
                        labelText: '活动级别 *',
                        hintText: '请选择活动级别',
                      ),
                      items: _levels.map((level) {
                        return DropdownMenuItem<int>(
                          value: level.id,
                          child: Text('${level.name} (系数: ${level.scoreMultiplier})'),
                        );
                      }).toList(),
                      onChanged: (value) {
                        setState(() {
                          _selectedLevelId = value;
                        });
                        _calculateScore(); // 自动计算分数
                      },
                      validator: (value) {
                        if (value == null) {
                          return '请选择活动级别';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: AppTheme.spacing16),
                    
                    // 得分
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
                    
                    // 时长/次数
                    TextFormField(
                      controller: _durationController,
                      decoration: const InputDecoration(
                        labelText: '时长/次数',
                        hintText: '请输入时长或次数',
                        suffixText: '小时/次',
                      ),
                      keyboardType: TextInputType.number,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return '请输入时长或次数';
                        }
                        if (double.tryParse(value) == null) {
                          return '请输入有效的数字';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: AppTheme.spacing16),
                    
                    // 活动日期
                    InkWell(
                      onTap: _selectDate,
                      child: InputDecorator(
                        decoration: const InputDecoration(
                          labelText: '活动日期 *',
                          suffixIcon: Icon(Icons.calendar_today),
                        ),
                        child: Text(
                          '${_selectedDate.year}-${_selectedDate.month.toString().padLeft(2, '0')}-${_selectedDate.day.toString().padLeft(2, '0')}',
                        ),
                      ),
                    ),
                    const SizedBox(height: AppTheme.spacing16),
                    
                    // 获奖状态
                    SwitchListTile(
                      title: const Text('是否获奖'),
                      subtitle: Text(_isAwarded ? '该活动已获奖' : '该活动未获奖'),
                      value: _isAwarded,
                      onChanged: (value) {
                        setState(() {
                          _isAwarded = value;
                          if (!value) {
                            _awardLevelController.clear();
                          }
                        });
                      },
                    ),
                    
                    // 获奖等级
                    if (_isAwarded) ...[
                      const SizedBox(height: AppTheme.spacing8),
                      TextFormField(
                        controller: _awardLevelController,
                        decoration: const InputDecoration(
                          labelText: '获奖等级',
                          hintText: '如：一等奖、二等奖、三等奖等',
                        ),
                        validator: (value) {
                          if (_isAwarded && (value == null || value.isEmpty)) {
                            return '请输入获奖等级';
                          }
                          return null;
                        },
                      ),
                    ],
                    const SizedBox(height: AppTheme.spacing16),
                    
                    // 是否代表集体
                    SwitchListTile(
                      title: const Text('是否代表集体'),
                      subtitle: Text(_isCollective ? '代表集体参加' : '个人参加'),
                      value: _isCollective,
                      onChanged: (value) {
                        setState(() {
                          _isCollective = value;
                        });
                      },
                    ),
                    
                    // 是否为负责人
                    SwitchListTile(
                      title: const Text('是否为负责人'),
                      subtitle: Text(_isLeader ? '担任负责人' : '普通参与者'),
                      value: _isLeader,
                      onChanged: (value) {
                        setState(() {
                          _isLeader = value;
                        });
                      },
                    ),
                    const SizedBox(height: AppTheme.spacing16),
                    
                    // 参与人数
                    TextFormField(
                      controller: _participantCountController,
                      decoration: const InputDecoration(
                        labelText: '参与人数',
                        hintText: '请输入参与人数',
                        suffixText: '人',
                      ),
                      keyboardType: TextInputType.number,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return '请输入参与人数';
                        }
                        final count = int.tryParse(value);
                        if (count == null || count < 1) {
                          return '参与人数必须为正整数';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: AppTheme.spacing16),
                    
                    // 活动标签
                    _buildTagsSection(),
                    const SizedBox(height: AppTheme.spacing16),
                    
                    // 备注
                    TextFormField(
                      controller: _remarksController,
                      decoration: const InputDecoration(
                        labelText: '备注',
                        hintText: '请输入备注信息',
                      ),
                      maxLines: 3,
                    ),
                    const SizedBox(height: AppTheme.spacing32),
                  ],
                ),
              ),
            ),
    );
  }

  // 构建标签选择区域
  Widget _buildTagsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          '活动标签',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: AppTheme.spacing8),
        if (_tags.isEmpty)
          const Text(
            '暂无可用标签',
            style: TextStyle(color: Colors.grey),
          )
        else
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _tags.map((tag) {
              final isSelected = _selectedTagIds.contains(tag.id);
              return FilterChip(
                label: Text(tag.name),
                selected: isSelected,
                onSelected: (selected) {
                  setState(() {
                    if (selected) {
                      _selectedTagIds.add(tag.id!);
                    } else {
                      _selectedTagIds.remove(tag.id);
                    }
                  });
                },
              );
            }).toList(),
          ),
      ],
    );
  }

  // 加载子分类
  Future<void> _loadSubcategories(int categoryId) async {
    try {
      final subcategories = await _subcategoryDao.getSubcategoriesByCategoryId(categoryId);
      setState(() {
        _subcategories = subcategories;
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('加载子分类失败: $e')),
        );
      }
    }
  }

  // 自动计算分数
  void _calculateScore() {
    // 这里可以根据级别系数自动计算分数
    // 目前先保持手动输入
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
          subcategoryId: _selectedSubcategoryId,
          levelId: _selectedLevelId,
          score: double.parse(_scoreController.text),
          duration: double.parse(_durationController.text),
          activityDate: _selectedDate,
          isAwarded: _isAwarded,
          awardLevel: _isAwarded ? _awardLevelController.text.trim() : null,
          isCollective: _isCollective,
          isLeader: _isLeader,
          participantCount: int.parse(_participantCountController.text),
          remarks: _remarksController.text.trim(),
          createdAt: _currentItem?.createdAt ?? now,
          updatedAt: now,
        );
        
        int itemId;
        if (isEditing) {
          await _assessmentItemDao.updateItem(item);
          itemId = item.id!;
        } else {
          itemId = await _assessmentItemDao.insertItem(item);
        }
        
        // 保存标签关联
        if (_selectedTagIds.isNotEmpty) {
          await _tagDao.setTagsForAssessmentItem(itemId, _selectedTagIds);
        } else {
          // 清空所有标签
          await _tagDao.setTagsForAssessmentItem(itemId, []);
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
    _participantCountController.dispose();
    _awardLevelController.dispose();
    _remarksController.dispose();
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