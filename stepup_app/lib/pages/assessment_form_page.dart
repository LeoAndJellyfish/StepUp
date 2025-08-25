import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:file_picker/file_picker.dart';
import 'package:image_picker/image_picker.dart';
import '../theme/app_theme.dart';
import '../models/assessment_item.dart';
import '../models/category.dart';
import '../models/subcategory.dart';
import '../models/level.dart';
import '../models/tag.dart';
import '../models/file_attachment.dart';
import '../services/assessment_item_dao.dart';
import '../services/category_dao.dart';
import '../services/subcategory_dao.dart';
import '../services/level_dao.dart';
import '../services/tag_dao.dart';
import '../services/file_attachment_dao.dart';
import '../services/file_manager.dart';
import '../services/assessment_deletion_service.dart';
import '../services/event_bus.dart';
import '../widgets/common_widgets.dart';

class AssessmentFormPage extends StatefulWidget {
  final int? itemId;

  const AssessmentFormPage({super.key, this.itemId});

  @override
  State<AssessmentFormPage> createState() => _AssessmentFormPageState();
}

class _AssessmentFormPageState extends State<AssessmentFormPage> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _durationController = TextEditingController();
  final _participantCountController = TextEditingController(text: '1');
  final _awardLevelController = TextEditingController();
  final _remarksController = TextEditingController();
  
  final AssessmentItemDao _assessmentItemDao = AssessmentItemDao();
  final CategoryDao _categoryDao = CategoryDao();
  final SubcategoryDao _subcategoryDao = SubcategoryDao();
  final LevelDao _levelDao = LevelDao();
  final TagDao _tagDao = TagDao();
  final FileAttachmentDao _fileAttachmentDao = FileAttachmentDao();
  final FileManager _fileManager = FileManager();
  final AssessmentItemDeletionService _deletionService = AssessmentItemDeletionService();
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
  
  // 证明材料相关 - 支持多文件
  List<FileAttachment> _attachments = [];
  // 跟踪新上传但未保存的文件，用于在取消时清理
  final Set<String> _unsavedFilePaths = {};
  final ImagePicker _imagePicker = ImagePicker();
  
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
            
            // 加载文件附件
            final attachments = await _fileAttachmentDao.getAttachmentsByItemId(item.id!);
            _attachments = attachments;
            // 注意：编辑模式下的现有文件不加入未保存列表
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
    return PopScope(
      canPop: _unsavedFilePaths.isEmpty,
      onPopInvokedWithResult: (bool didPop, Object? result) {
        // 如果有未保存的文件并且实际没有返回，显示确认对话框
        if (!didPop && _unsavedFilePaths.isNotEmpty) {
          _showDiscardConfirmDialog();
        }
      },
      child: Scaffold(
        appBar: AppBar(
          title: Text(isEditing ? '编辑条目' : '添加条目'),
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: _handleBackPress,
          ),
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
                          child: Text('${level.name} (${level.code})'),
                        );
                      }).toList(),
                      onChanged: (value) {
                        setState(() {
                          _selectedLevelId = value;
                        });
                        _calculateScore(); // 自动计算功能已删除
                      },
                      validator: (value) {
                        if (value == null) {
                          return '请选择活动级别';
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
                    
                    // 证明材料
                    _buildProofMaterialsSection(),
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

  // 构建证明材料上传区域
  Widget _buildProofMaterialsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Text(
              '证明材料',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w500,
              ),
            ),
            const Spacer(),
            Text(
              '已上传 ${_attachments.length} 个文件',
              style: TextStyle(
                fontSize: 12,
                color: Theme.of(context).colorScheme.outline,
              ),
            ),
          ],
        ),
        const SizedBox(height: AppTheme.spacing8),
        
        // 上传按钮区域
        Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                onPressed: _pickImage,
                icon: const Icon(Icons.add_photo_alternate, size: 18),
                label: const Text('添加图片'),
              ),
            ),
            const SizedBox(width: AppTheme.spacing8),
            Expanded(
              child: OutlinedButton.icon(
                onPressed: _pickFile,
                icon: const Icon(Icons.upload_file, size: 18),
                label: const Text('添加文件'),
              ),
            ),
          ],
        ),
        const SizedBox(height: AppTheme.spacing8),
        
        // 文件列表
        if (_attachments.isNotEmpty) ...[
          Card(
            child: Padding(
              padding: const EdgeInsets.all(AppTheme.spacing12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '已上传的文件',
                    style: TextStyle(
                      fontWeight: FontWeight.w500,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                  ),
                  const SizedBox(height: AppTheme.spacing8),
                  ..._attachments.map((attachment) => _buildAttachmentItem(attachment)),
                ],
              ),
            ),
          ),
        ] else ...[
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(AppTheme.spacing16),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.3),
                style: BorderStyle.solid,
              ),
            ),
            child: Column(
              children: [
                Icon(
                  Icons.cloud_upload_outlined,
                  size: 48,
                  color: Theme.of(context).colorScheme.outline,
                ),
                const SizedBox(height: AppTheme.spacing8),
                Text(
                  '暂无证明材料',
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.outline,
                  ),
                ),
                const SizedBox(height: AppTheme.spacing4),
                Text(
                  '支持格式：图片(JPG、PNG、GIF)、文档(PDF、Word、文本)',
                  style: TextStyle(
                    fontSize: 12,
                    color: Theme.of(context).colorScheme.outline,
                  ),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }
  
  // 构建文件附件项
  Widget _buildAttachmentItem(FileAttachment attachment) {
    final theme = Theme.of(context);
    
    return Container(
      margin: const EdgeInsets.only(bottom: AppTheme.spacing8),
      padding: const EdgeInsets.all(AppTheme.spacing8),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Icon(
            _getFileIcon(attachment),
            size: 20,
            color: attachment.isImage ? Colors.green : Colors.blue,
          ),
          const SizedBox(width: AppTheme.spacing8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  attachment.fileName,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Row(
                  children: [
                    Text(
                      attachment.isImage ? '图片' : '文档',
                      style: TextStyle(
                        fontSize: 11,
                        color: theme.colorScheme.outline,
                      ),
                    ),
                    Text(
                      ' • ${attachment.formattedFileSize}',
                      style: TextStyle(
                        fontSize: 11,
                        color: theme.colorScheme.outline,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: () => _previewAttachment(attachment),
            icon: const Icon(Icons.visibility, size: 16),
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
            tooltip: '预览',
          ),
          IconButton(
            onPressed: () => _removeAttachment(attachment),
            icon: const Icon(Icons.close, size: 16),
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
            tooltip: '移除',
          ),
        ],
      ),
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

  // 自动计算功能已删除，将来由AI处理
  void _calculateScore() {
    // 该功能已删除，将来由AI根据评分标准自动计分
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

  // 选择证明图片
  Future<void> _pickImage() async {
    try {
      final XFile? image = await _imagePicker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1920,
        maxHeight: 1080,
        imageQuality: 85,
      );
      
      if (image != null) {
        final fileInfo = await _fileManager.copyFileWithInfo(image.path);
        final attachment = FileAttachment(
          assessmentItemId: 0, // 伴在保存时设置
          fileName: fileInfo['fileName'],
          filePath: fileInfo['filePath'],
          fileType: fileInfo['fileType'],
          fileSize: fileInfo['fileSize'],
          mimeType: fileInfo['mimeType'],
          uploadedAt: DateTime.now(),
        );
        
        setState(() {
          _attachments.add(attachment);
          // 记录新上传的文件，用于可能的清理
          _unsavedFilePaths.add(attachment.filePath);
        });
        
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('图片上传成功: ${attachment.fileName}')),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('选择图片失败: $e')),
        );
      }
    }
  }

  // 选择证明文件
  Future<void> _pickFile() async {
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['pdf', 'doc', 'docx', 'txt', 'rtf'],
        allowMultiple: true, // 支持多文件选择
      );
      
      if (result != null) {
        for (final file in result.files) {
          if (file.path != null) {
            final fileInfo = await _fileManager.copyFileWithInfo(file.path!);
            final attachment = FileAttachment(
              assessmentItemId: 0, // 伴在保存时设置
              fileName: fileInfo['fileName'],
              filePath: fileInfo['filePath'],
              fileType: fileInfo['fileType'],
              fileSize: fileInfo['fileSize'],
              mimeType: fileInfo['mimeType'],
              uploadedAt: DateTime.now(),
            );
            
            setState(() {
              _attachments.add(attachment);
              // 记录新上传的文件，用于可能的清理
              _unsavedFilePaths.add(attachment.filePath);
            });
          }
        }
        
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('文件上传成功: ${result.files.length} 个文件')),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('选择文件失败: $e')),
        );
      }
    }
  }

  // 移除文件附件
  void _removeAttachment(FileAttachment attachment) {
    setState(() {
      _attachments.remove(attachment);
      // 从未保存列表中移除
      _unsavedFilePaths.remove(attachment.filePath);
    });
    
    // 如果文件已经上传到应用目录，则删除文件
    _fileManager.deleteFile(attachment.filePath);
    
    // 显示删除成功通知
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('已移除文件: ${attachment.fileName}')),
      );
    }
  }

  // 预览文件附件
  void _previewAttachment(FileAttachment attachment) {
    if (attachment.isImage) {
      context.push(
        '/image-preview?path=${Uri.encodeComponent(attachment.filePath)}&title=${Uri.encodeComponent(attachment.fileName)}',
      );
    } else {
      context.push(
        '/document-preview?path=${Uri.encodeComponent(attachment.filePath)}&title=${Uri.encodeComponent(attachment.fileName)}',
      );
    }
  }

  // 获取文件图标
  IconData _getFileIcon(FileAttachment attachment) {
    if (attachment.isImage) {
      return Icons.image;
    }
    
    switch (attachment.fileExtension) {
      case 'pdf':
        return Icons.picture_as_pdf;
      case 'doc':
      case 'docx':
        return Icons.description;
      case 'txt':
        return Icons.text_snippet;
      default:
        return Icons.insert_drive_file;
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
          duration: double.parse(_durationController.text),
          activityDate: _selectedDate,
          isAwarded: _isAwarded,
          awardLevel: _isAwarded ? _awardLevelController.text.trim() : null,
          isCollective: _isCollective,
          isLeader: _isLeader,
          participantCount: int.parse(_participantCountController.text),
          imagePath: null, // 不再使用单一文件路径
          filePath: null, // 不再使用单一文件路径
          remarks: _remarksController.text.trim(),
          createdAt: _currentItem?.createdAt ?? now,
          updatedAt: now,
        );
        
        int itemId;
        if (isEditing) {
          await _assessmentItemDao.updateItem(item);
          itemId = item.id!;
          
          // 获取旧的文件附件并删除物理文件
          final oldAttachments = await _fileAttachmentDao.getAttachmentsByItemId(itemId);
          for (final oldAttachment in oldAttachments) {
            await _fileManager.deleteFile(oldAttachment.filePath);
          }
          
          // 删除旧的文件附件记录
          await _fileAttachmentDao.deleteAttachmentsByItemId(itemId);
        } else {
          itemId = await _assessmentItemDao.insertItem(item);
        }
        
        // 保存文件附件
        if (_attachments.isNotEmpty) {
          final attachmentsToSave = _attachments.map((attachment) => 
            attachment.copyWith(assessmentItemId: itemId)
          ).toList();
          
          await _fileAttachmentDao.insertAttachments(attachmentsToSave);
        }
        
        // 保存标签关联
        if (_selectedTagIds.isNotEmpty) {
          await _tagDao.setTagsForAssessmentItem(itemId, _selectedTagIds);
        } else {
          // 清空所有标签
          await _tagDao.setTagsForAssessmentItem(itemId, []);
        }
        
        if (mounted) {
          // 清空未保存文件列表，因为已经成功保存
          _unsavedFilePaths.clear();
          
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
    // 清理未保存的文件
    _cleanupUnsavedFiles();
    
    // 清理控制器
    _titleController.dispose();
    _descriptionController.dispose();
    _durationController.dispose();
    _participantCountController.dispose();
    _awardLevelController.dispose();
    _remarksController.dispose();
    super.dispose();
  }

  /// 处理返回按钮点击
  void _handleBackPress() {
    // 如果有未保存的文件，显示确认对话框
    if (_unsavedFilePaths.isNotEmpty) {
      _showDiscardConfirmDialog();
    } else {
      // 没有未保存文件，直接返回
      context.pop();
    }
  }

  /// 显示放弃更改确认对话框
  void _showDiscardConfirmDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('放弃更改'),
        content: Text(
          '您已上传了 ${_unsavedFilePaths.length} 个文件但尚未保存。\n'
          '放弃更改将会删除这些文件，确定要继续吗？'
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('继续编辑'),
          ),
          FilledButton(
            onPressed: () {
              Navigator.of(context).pop();
              // 清理文件并返回
              _cleanupUnsavedFiles();
              context.pop();
            },
            style: FilledButton.styleFrom(
              backgroundColor: Colors.orange,
            ),
            child: const Text('放弃更改'),
          ),
        ],
      ),
    );
  }

  /// 清理未保存的文件
  void _cleanupUnsavedFiles() {
    for (final filePath in _unsavedFilePaths) {
      _fileManager.deleteFile(filePath);
    }
    _unsavedFilePaths.clear();
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
      // 使用删除服务完整删除条目及其所有文件
      await _deletionService.deleteAssessmentItem(_currentItem!.id!);
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('已删除条目「${_currentItem!.title}」及其所有证明材料')),
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