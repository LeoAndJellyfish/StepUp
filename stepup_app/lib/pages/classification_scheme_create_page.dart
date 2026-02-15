import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../models/classification_scheme.dart';
import '../services/classification_scheme_dao.dart';
import '../theme/app_theme.dart';

class ClassificationSchemeCreatePage extends StatefulWidget {
  const ClassificationSchemeCreatePage({super.key});

  @override
  State<ClassificationSchemeCreatePage> createState() => _ClassificationSchemeCreatePageState();
}

class _ClassificationSchemeCreatePageState extends State<ClassificationSchemeCreatePage> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _codeController = TextEditingController();
  final _descriptionController = TextEditingController();
  final ClassificationSchemeDao _schemeDao = ClassificationSchemeDao();

  bool _isLoading = false;

  @override
  void dispose() {
    _nameController.dispose();
    _codeController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _createScheme() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final scheme = ClassificationScheme(
        name: _nameController.text.trim(),
        code: _codeController.text.trim().isEmpty
            ? 'SCHEME_${DateTime.now().millisecondsSinceEpoch}'
            : _codeController.text.trim(),
        description: _descriptionController.text.trim(),
        isActive: false,
        isDefault: false,
        source: 'manual',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      await _schemeDao.insertScheme(scheme);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('分类方案创建成功'),
            backgroundColor: Colors.green,
          ),
        );
        context.pop(true);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('创建失败: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('创建分类方案'),
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => context.pop(),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppTheme.spacing16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Card(
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
                              Icons.edit_note,
                              color: AppTheme.primaryColor,
                            ),
                          ),
                          const SizedBox(width: 12),
                          const Expanded(
                            child: Text(
                              '手动创建分类方案',
                              style: AppTheme.titleLarge,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        '创建一个新的分类方案，稍后可以在方案详情中添加具体的分类和子分类。',
                        style: AppTheme.bodyMedium,
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: AppTheme.spacing16),
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(
                  labelText: '方案名称',
                  hintText: '请输入方案名称',
                  prefixIcon: Icon(Icons.label),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return '请输入方案名称';
                  }
                  return null;
                },
              ),
              const SizedBox(height: AppTheme.spacing16),
              TextFormField(
                controller: _codeController,
                decoration: const InputDecoration(
                  labelText: '方案代码',
                  hintText: '可选，用于标识方案',
                  prefixIcon: Icon(Icons.code),
                  helperText: '留空将自动生成',
                ),
              ),
              const SizedBox(height: AppTheme.spacing16),
              TextFormField(
                controller: _descriptionController,
                decoration: const InputDecoration(
                  labelText: '方案描述',
                  hintText: '可选，描述该方案的用途',
                  prefixIcon: Icon(Icons.description),
                ),
                maxLines: 3,
              ),
              const SizedBox(height: AppTheme.spacing24),
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: _isLoading ? null : _createScheme,
                  child: _isLoading
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                          ),
                        )
                      : const Text('创建方案'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
