import 'package:flutter/material.dart';
import 'dart:io';
import 'package:url_launcher/url_launcher.dart';
import '../theme/app_theme.dart';

/// 图片预览页面
/// 支持全屏查看、缩放、旋转等功能
class ImagePreviewPage extends StatefulWidget {
  final String imagePath;
  final String? title;

  const ImagePreviewPage({
    super.key,
    required this.imagePath,
    this.title,
  });

  @override
  State<ImagePreviewPage> createState() => _ImagePreviewPageState();
}

class _ImagePreviewPageState extends State<ImagePreviewPage> {
  final TransformationController _transformationController = TransformationController();
  
  @override
  void dispose() {
    _transformationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black.withValues(alpha: 0.5),
        foregroundColor: Colors.white,
        title: Text(
          widget.title ?? '图片预览',
          style: const TextStyle(color: Colors.white),
        ),
        actions: [
          IconButton(
            onPressed: _openWithExternalApp,
            icon: const Icon(Icons.open_in_new, color: Colors.white),
            tooltip: '使用外部应用打开',
          ),
          IconButton(
            onPressed: _resetZoom,
            icon: const Icon(Icons.zoom_out_map, color: Colors.white),
            tooltip: '重置缩放',
          ),
        ],
      ),
      body: Center(
        child: Hero(
          tag: widget.imagePath,
          child: InteractiveViewer(
            transformationController: _transformationController,
            minScale: 0.5,
            maxScale: 5.0,
            child: _buildImage(),
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _resetZoom,
        backgroundColor: Colors.white.withValues(alpha: 0.2),
        foregroundColor: Colors.white,
        child: const Icon(Icons.zoom_out_map),
      ),
    );
  }

  Widget _buildImage() {
    final file = File(widget.imagePath);
    
    if (!file.existsSync()) {
      return Container(
        padding: const EdgeInsets.all(AppTheme.spacing32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.broken_image,
              size: 64,
              color: Colors.white.withValues(alpha: 0.6),
            ),
            const SizedBox(height: AppTheme.spacing16),
            Text(
              '图片文件不存在',
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.8),
                fontSize: 16,
              ),
            ),
            const SizedBox(height: AppTheme.spacing8),
            Text(
              widget.imagePath,
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.6),
                fontSize: 12,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }

    return Image.file(
      file,
      fit: BoxFit.contain,
      errorBuilder: (context, error, stackTrace) {
        return Container(
          padding: const EdgeInsets.all(AppTheme.spacing32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.error_outline,
                size: 64,
                color: Colors.white.withValues(alpha: 0.6),
              ),
              const SizedBox(height: AppTheme.spacing16),
              Text(
                '无法加载图片',
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.8),
                  fontSize: 16,
                ),
              ),
              const SizedBox(height: AppTheme.spacing8),
              Text(
                '错误: $error',
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.6),
                  fontSize: 12,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        );
      },
    );
  }

  /// 使用外部应用打开图片
  Future<void> _openWithExternalApp() async {
    try {
      final file = File(widget.imagePath);
      if (!file.existsSync()) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('图片文件不存在，无法打开'),
              backgroundColor: Colors.red,
            ),
          );
        }
        return;
      }

      // 使用 file:// URL 方案打开文件
      final uri = Uri.file(widget.imagePath);
      
      if (await canLaunchUrl(uri)) {
        final success = await launchUrl(
          uri,
          mode: LaunchMode.externalApplication,
        );
        
        if (!success) {
          throw Exception('无法启动外部应用');
        }
        
        if (mounted) {
          final fileName = widget.imagePath.split('/').last.split('\\').last;
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('已使用外部应用打开: $fileName'),
              backgroundColor: Colors.green,
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
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _resetZoom() {
    _transformationController.value = Matrix4.identity();
  }
}