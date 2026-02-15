import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:file_picker/file_picker.dart';
import '../services/ai_document_analysis_service.dart';
import '../services/ai_config_service.dart';
import '../services/category_dao.dart';
import '../services/subcategory_dao.dart';
import '../services/classification_scheme_dao.dart';
import '../models/category.dart';
import '../models/subcategory.dart';
import '../models/classification_scheme.dart';
import '../theme/app_theme.dart';

class DocumentAnalysisPage extends StatefulWidget {
  const DocumentAnalysisPage({super.key});

  @override
  State<DocumentAnalysisPage> createState() => _DocumentAnalysisPageState();
}

class _DocumentAnalysisPageState extends State<DocumentAnalysisPage> {
  final AIDocumentAnalysisService _analysisService = AIDocumentAnalysisService();
  final AIConfigService _configService = AIConfigService();
  final CategoryDao _categoryDao = CategoryDao();
  final SubcategoryDao _subcategoryDao = SubcategoryDao();
  final ClassificationSchemeDao _schemeDao = ClassificationSchemeDao();

  bool _isLoading = false;
  bool _isAIConfigured = false;
  String? _selectedFilePath;
  String? _selectedFileName;
  DocumentAnalysisResult? _analysisResult;
  String? _error;
  List<Category> _existingCategories = [];

  @override
  void initState() {
    super.initState();
    _checkAIConfig();
    _loadExistingCategories();
  }

  Future<void> _checkAIConfig() async {
    final isConfigured = await _configService.isConfigured();
    final isEnabled = await _configService.isEnabled();
    if (mounted) {
      setState(() {
        _isAIConfigured = isConfigured && isEnabled;
      });
    }
  }

  Future<void> _loadExistingCategories() async {
    try {
      final categories = await _categoryDao.getAllCategories();
      if (mounted) {
        setState(() {
          _existingCategories = categories;
        });
      }
    } catch (e) {
      debugPrint('加载现有分类失败: $e');
    }
  }

  Future<void> _pickDocument() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['pdf'],
      );

      if (result != null && result.files.isNotEmpty) {
        final file = result.files.first;
        if (file.path != null) {
          setState(() {
            _selectedFilePath = file.path;
            _selectedFileName = file.name;
            _analysisResult = null;
            _error = null;
          });
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('选择文件失败: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _analyzeDocument() async {
    if (_selectedFilePath == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('请先选择一个PDF文件')),
      );
      return;
    }

    if (!_isAIConfigured) {
      _showConfigDialog();
      return;
    }

    setState(() {
      _isLoading = true;
      _error = null;
      _analysisResult = null;
    });

    try {
      final result = await _analysisService.analyzeDocument(
        filePath: _selectedFilePath!,
        existingCategories: _existingCategories,
      );

      if (mounted) {
        setState(() {
          _analysisResult = result;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString();
          _isLoading = false;
        });
      }
    }
  }

  void _showConfigDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.warning_amber, color: Colors.orange),
            SizedBox(width: 8),
            Text('AI服务未配置'),
          ],
        ),
        content: const Text('请先在设置页面配置 DeepSeek API Key 后再使用文档分析功能。'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('取消'),
          ),
          FilledButton(
            onPressed: () {
              Navigator.pop(context);
              context.push('/settings');
            },
            child: const Text('前往设置'),
          ),
        ],
      ),
    );
  }

  Future<void> _applyCategories() async {
    if (_analysisResult == null) return;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('确认导入分类'),
        content: Text(
          '将根据识别结果创建 ${_analysisResult!.suggestedCategories.length} 个分类及其子分类。\n\n'
          '接下来可以选择创建新的分类方案，或将分类添加到现有方案中。',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('取消'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('继续'),
          ),
        ],
      ),
    );

    if (confirmed != true || !mounted) return;

    // 询问用户是否创建新的分类方案
    final createScheme = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('选择导入方式'),
        content: const Text(
          '是否将识别的分类创建为新的分类方案？\n\n'
          '• 创建新方案：便于管理和切换不同分类标准\n'
          '• 仅创建分类：添加到当前激活的方案中',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('添加到当前方案'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('创建新方案'),
          ),
        ],
      ),
    );

    if (!mounted) return;

    setState(() => _isLoading = true);

    try {
      int? schemeId;
      
      // 如果用户选择创建新方案
      if (createScheme == true) {
        final schemeName = await showDialog<String>(
          context: context,
          builder: (context) {
            final controller = TextEditingController(
              text: _selectedFileName?.replaceAll('.pdf', '') ?? 'AI识别方案',
            );
            return AlertDialog(
              title: const Text('命名分类方案'),
              content: TextField(
                controller: controller,
                decoration: const InputDecoration(
                  labelText: '方案名称',
                  hintText: '请输入分类方案名称',
                ),
                autofocus: true,
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('取消'),
                ),
                FilledButton(
                  onPressed: () => Navigator.pop(context, controller.text.trim()),
                  child: const Text('确认'),
                ),
              ],
            );
          },
        );

        if (schemeName != null && schemeName.isNotEmpty) {
          final scheme = ClassificationScheme(
            name: schemeName,
            code: 'AI_${DateTime.now().millisecondsSinceEpoch}',
            description: '通过AI识别文档「${_selectedFileName ?? '未知文件'}」创建的分类方案',
            isActive: false,
            isDefault: false,
            source: 'ai',
            createdAt: DateTime.now(),
            updatedAt: DateTime.now(),
          );
          schemeId = await _schemeDao.insertScheme(scheme);
        }
      } else {
        // 添加到当前激活的方案
        final activeScheme = await _schemeDao.getActiveScheme();
        if (activeScheme != null) {
          schemeId = activeScheme.id;
        }
      }

      int createdCategories = 0;
      int createdSubcategories = 0;

      for (final categorySuggestion in _analysisResult!.suggestedCategories) {
        final category = Category(
          schemeId: schemeId,
          name: categorySuggestion.name,
          code: categorySuggestion.code,
          description: categorySuggestion.description,
          color: categorySuggestion.color,
          icon: categorySuggestion.icon,
          createdAt: DateTime.now(),
        );

        final categoryId = await _categoryDao.insertCategory(category);
        createdCategories++;

        for (final subcategorySuggestion in categorySuggestion.subcategories) {
          final subcategory = Subcategory(
            categoryId: categoryId,
            name: subcategorySuggestion.name,
            code: subcategorySuggestion.code,
            description: subcategorySuggestion.description,
            createdAt: DateTime.now(),
          );

          await _subcategoryDao.insertSubcategory(subcategory);
          createdSubcategories++;
        }
      }

      if (mounted) {
        String message;
        if (schemeId != null) {
          message = '已创建新方案，包含 $createdCategories 个分类和 $createdSubcategories 个子分类';
        } else {
          message = '已导入 $createdCategories 个分类和 $createdSubcategories 个子分类';
        }
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(message),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 3),
          ),
        );

        await _loadExistingCategories();
        
        // 返回 true 表示创建成功
        if (mounted) {
          context.pop(true);
          return;
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('应用分类失败: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('AI分类识别'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
      ),
      body: _isLoading
          ? const Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 16),
                  Text('正在分析文档，请稍候...'),
                ],
              ),
            )
          : SingleChildScrollView(
              padding: const EdgeInsets.all(AppTheme.spacing16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _buildIntroCard(),
                  const SizedBox(height: AppTheme.spacing16),
                  _buildFilePickerCard(),
                  if (_error != null) ...[
                    const SizedBox(height: AppTheme.spacing16),
                    _buildErrorCard(),
                  ],
                  if (_analysisResult != null) ...[
                    const SizedBox(height: AppTheme.spacing16),
                    _buildResultCard(),
                  ],
                ],
              ),
            ),
    );
  }

  Widget _buildIntroCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppTheme.spacing16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppTheme.primaryColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(
                    Icons.auto_awesome,
                    color: AppTheme.primaryColor,
                  ),
                ),
                const SizedBox(width: 12),
                const Expanded(
                  child: Text(
                    'AI分类识别',
                    style: AppTheme.titleLarge,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            const Text(
              '上传综测文件（PDF格式），AI将自动识别文件中的分类体系并生成对应的分类结构。\n\n'
              '功能说明：\n'
              '• 智能识别综测文件中的分类体系\n'
              '• 自动生成分类和子分类\n'
              '• 支持一键导入到系统',
              style: AppTheme.bodyMedium,
            ),
            if (!_isAIConfigured) ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.orange.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.orange),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.warning_amber, color: Colors.orange, size: 20),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        '请先配置 DeepSeek API Key',
                        style: AppTheme.bodySmall.copyWith(color: Colors.orange),
                      ),
                    ),
                    TextButton(
                      onPressed: () => context.push('/settings'),
                      child: const Text('去配置'),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildFilePickerCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppTheme.spacing16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              '选择文件',
              style: AppTheme.titleMedium,
            ),
            const SizedBox(height: 12),
            if (_selectedFilePath == null)
              InkWell(
                onTap: _pickDocument,
                borderRadius: BorderRadius.circular(12),
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    border: Border.all(
                      color: AppTheme.memphisBlack.withValues(alpha: 0.3),
                      width: 1.5,
                    ),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    children: [
                      Icon(
                        Icons.upload_file,
                        size: 48,
                        color: AppTheme.memphisBlack.withValues(alpha: 0.5),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        '点击选择PDF文件',
                        style: AppTheme.bodyMedium.copyWith(
                          color: AppTheme.memphisBlack.withValues(alpha: 0.7),
                        ),
                      ),
                    ],
                  ),
                ),
              )
            else
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppTheme.accentBlue.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: AppTheme.accentBlue),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.picture_as_pdf, color: Colors.red),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        _selectedFileName ?? '已选择文件',
                        style: AppTheme.bodyMedium,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () {
                        setState(() {
                          _selectedFilePath = null;
                          _selectedFileName = null;
                          _analysisResult = null;
                          _error = null;
                        });
                      },
                    ),
                  ],
                ),
              ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: _pickDocument,
                    icon: const Icon(Icons.folder_open),
                    label: const Text('选择文件'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: FilledButton.icon(
                    onPressed: (_selectedFilePath != null && _isAIConfigured) ? _analyzeDocument : null,
                    icon: const Icon(Icons.analytics),
                    label: const Text('开始分析'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorCard() {
    return Card(
      color: Colors.red.withValues(alpha: 0.1),
      child: Padding(
        padding: const EdgeInsets.all(AppTheme.spacing16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.error_outline, color: Colors.red),
                const SizedBox(width: 8),
                const Text(
                  '分析失败',
                  style: AppTheme.titleMedium,
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              _error ?? '未知错误',
              style: AppTheme.bodySmall.copyWith(color: Colors.red),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildResultCard() {
    final result = _analysisResult!;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppTheme.spacing16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.green.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(Icons.check_circle, color: Colors.green),
                ),
                const SizedBox(width: 12),
                const Expanded(
                  child: Text(
                    '分析结果',
                    style: AppTheme.titleLarge,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            _buildResultSection('文档标题', result.documentTitle),
            const SizedBox(height: 12),
            _buildResultSection('文档摘要', result.documentSummary),
            if (result.analysisNotes.isNotEmpty) ...[
              const SizedBox(height: 12),
              _buildResultSection('分析说明', result.analysisNotes),
            ],
            const SizedBox(height: 24),
            const Text(
              '建议的分类',
              style: AppTheme.titleMedium,
            ),
            const SizedBox(height: 12),
            ...result.suggestedCategories.map((category) => _buildCategoryCard(category)),
            const SizedBox(height: 24),
            FilledButton.icon(
              onPressed: _applyCategories,
              icon: const Icon(Icons.check),
              label: const Text('导入分类'),
              style: FilledButton.styleFrom(
                minimumSize: const Size(double.infinity, 48),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildResultSection(String title, String content) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: AppTheme.labelMedium.copyWith(
            color: AppTheme.memphisBlack.withValues(alpha: 0.6),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          content,
          style: AppTheme.bodyMedium,
        ),
      ],
    );
  }

  Widget _buildCategoryCard(CategorySuggestion category) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Color(
          int.parse(category.color.substring(1), radix: 16) + 0xFF000000,
        ).withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Color(
            int.parse(category.color.substring(1), radix: 16) + 0xFF000000,
          ),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Color(
                    int.parse(category.color.substring(1), radix: 16) + 0xFF000000,
                  ),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  category.code,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  category.name,
                  style: AppTheme.titleSmall,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            category.description,
            style: AppTheme.bodySmall.copyWith(
              color: AppTheme.memphisBlack.withValues(alpha: 0.7),
            ),
          ),
          if (category.subcategories.isNotEmpty) ...[
            const SizedBox(height: 8),
            const Text(
              '子分类：',
              style: TextStyle(fontWeight: FontWeight.w600, fontSize: 12),
            ),
            const SizedBox(height: 4),
            Wrap(
              spacing: 8,
              runSpacing: 4,
              children: category.subcategories.map((sub) {
                return Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(4),
                    border: Border.all(
                      color: AppTheme.memphisBlack.withValues(alpha: 0.2),
                    ),
                  ),
                  child: Text(
                    '${sub.code} ${sub.name}',
                    style: const TextStyle(fontSize: 11),
                  ),
                );
              }).toList(),
            ),
          ],
          if (category.reasoning.isNotEmpty) ...[
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.5),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(
                    Icons.lightbulb_outline,
                    size: 14,
                    color: AppTheme.memphisBlack.withValues(alpha: 0.5),
                  ),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      category.reasoning,
                      style: TextStyle(
                        fontSize: 11,
                        color: AppTheme.memphisBlack.withValues(alpha: 0.6),
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}
