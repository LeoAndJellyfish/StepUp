import 'package:flutter/material.dart';
import 'dart:io';
import 'package:url_launcher/url_launcher.dart';
import '../theme/app_theme.dart';
import '../services/file_manager.dart';

/// 文档预览页面
/// 支持文本文件预览和文档信息显示
class DocumentPreviewPage extends StatefulWidget {
  final String documentPath;
  final String? title;

  const DocumentPreviewPage({
    super.key,
    required this.documentPath,
    this.title,
  });

  @override
  State<DocumentPreviewPage> createState() => _DocumentPreviewPageState();
}

class _DocumentPreviewPageState extends State<DocumentPreviewPage> {
  final FileManager _fileManager = FileManager();
  String? _textContent;
  bool _isLoading = true;
  String? _error;
  double _fileSize = 0.0;

  @override
  void initState() {
    super.initState();
    _loadDocument();
  }

  Future<void> _loadDocument() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      // 获取文件大小
      _fileSize = await _fileManager.getFileSize(widget.documentPath);

      // 只预览文本文件
      if (_fileManager.getFileExtension(widget.documentPath) == '.txt') {
        final file = File(widget.documentPath);
        if (await file.exists()) {
          _textContent = await file.readAsString();
        } else {
          _error = '文件不存在';
        }
      }
    } catch (e) {
      _error = '加载文档失败: $e';
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title ?? '文档预览'),
        actions: [
          IconButton(
            onPressed: _showDocumentInfo,
            icon: const Icon(Icons.info_outline),
            tooltip: '文档信息',
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? _buildErrorWidget()
              : _buildDocumentContent(),
    );
  }

  Widget _buildErrorWidget() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppTheme.spacing32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline,
              size: 64,
              color: Theme.of(context).colorScheme.error,
            ),
            const SizedBox(height: AppTheme.spacing16),
            Text(
              _error!,
              style: AppTheme.titleMedium.copyWith(
                color: Theme.of(context).colorScheme.error,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppTheme.spacing16),
            FilledButton.icon(
              onPressed: _loadDocument,
              icon: const Icon(Icons.refresh),
              label: const Text('重新加载'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDocumentContent() {
    final extension = _fileManager.getFileExtension(widget.documentPath);
    final fileName = _fileManager.getFileName(widget.documentPath);
    final fileType = _fileManager.getFileTypeDescription(widget.documentPath);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppTheme.spacing16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 文档信息卡片
          Card(
            child: Padding(
              padding: const EdgeInsets.all(AppTheme.spacing16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        _getFileIcon(extension),
                        size: 32,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                      const SizedBox(width: AppTheme.spacing12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              fileName,
                              style: AppTheme.titleMedium,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: AppTheme.spacing4),
                            Text(
                              fileType,
                              style: AppTheme.bodyMedium.copyWith(
                                color: Theme.of(context).colorScheme.outline,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppTheme.spacing12),
                  Row(
                    children: [
                      Icon(
                        Icons.storage,
                        size: 16,
                        color: Theme.of(context).colorScheme.outline,
                      ),
                      const SizedBox(width: AppTheme.spacing4),
                      Text(
                        '文件大小: ${_fileSize.toStringAsFixed(2)} MB',
                        style: AppTheme.bodySmall.copyWith(
                          color: Theme.of(context).colorScheme.outline,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: AppTheme.spacing16),

          // 文档内容预览
          if (_textContent != null) ...[
            Card(
              child: Padding(
                padding: const EdgeInsets.all(AppTheme.spacing16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '文档内容',
                      style: AppTheme.titleMedium,
                    ),
                    const SizedBox(height: AppTheme.spacing12),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(AppTheme.spacing12),
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
                        borderRadius: BorderRadius.circular(AppTheme.radiusSmall),
                      ),
                      child: Text(
                        _textContent!,
                        style: AppTheme.bodyMedium.copyWith(
                          fontFamily: 'monospace',
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ] else ...[
            Card(
              child: Padding(
                padding: const EdgeInsets.all(AppTheme.spacing16),
                child: Column(
                  children: [
                    Icon(
                      Icons.preview,
                      size: 48,
                      color: Theme.of(context).colorScheme.outline,
                    ),
                    const SizedBox(height: AppTheme.spacing12),
                    Text(
                      '此文档类型不支持预览',
                      style: AppTheme.titleMedium.copyWith(
                        color: Theme.of(context).colorScheme.outline,
                      ),
                    ),
                    const SizedBox(height: AppTheme.spacing8),
                    Text(
                      '支持预览的格式：TXT文本文件',
                      style: AppTheme.bodySmall.copyWith(
                        color: Theme.of(context).colorScheme.outline,
                      ),
                    ),
                    const SizedBox(height: AppTheme.spacing16),
                    FilledButton.icon(
                      onPressed: _openWithExternalApp,
                      icon: const Icon(Icons.open_in_new),
                      label: const Text('使用外部应用打开'),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  /// 使用外部应用打开文件
  Future<void> _openWithExternalApp() async {
    try {
      final file = File(widget.documentPath);
      if (!await file.exists()) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('文件不存在，无法打开'),
              duration: Duration(seconds: 2),
            ),
          );
        }
        return;
      }

      final uri = Uri.file(widget.documentPath);
      
      if (await canLaunchUrl(uri)) {
        final success = await launchUrl(
          uri,
          mode: LaunchMode.externalApplication,
        );
        
        if (!success) {
          throw Exception('无法启动外部应用');
        }
        
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('已使用外部应用打开: ${_fileManager.getFileName(widget.documentPath)}'),
              duration: const Duration(seconds: 2),
            ),
          );
        }
      } else {
        throw Exception('系统不支持打开此类型的文件');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('打开失败: $e'),
            duration: const Duration(seconds: 2),
          ),
        );
      }
    }
  }

  IconData _getFileIcon(String extension) {
    switch (extension) {
      case '.pdf':
        return Icons.picture_as_pdf;
      case '.doc':
      case '.docx':
        return Icons.description;
      case '.txt':
        return Icons.text_snippet;
      default:
        return Icons.insert_drive_file;
    }
  }

  void _showDocumentInfo() {
    final fileName = _fileManager.getFileName(widget.documentPath);
    final fileType = _fileManager.getFileTypeDescription(widget.documentPath);
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('文档信息'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildInfoRow('文件名', fileName),
            _buildInfoRow('文件类型', fileType),
            _buildInfoRow('文件大小', '${_fileSize.toStringAsFixed(2)} MB'),
            _buildInfoRow('文件路径', widget.documentPath),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('关闭'),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppTheme.spacing8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: AppTheme.labelMedium.copyWith(
              color: Theme.of(context).colorScheme.outline,
            ),
          ),
          const SizedBox(height: AppTheme.spacing4),
          Text(
            value,
            style: AppTheme.bodyMedium,
          ),
        ],
      ),
    );
  }
}