import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import 'dart:math' as math;

class LoadingWidget extends StatelessWidget {
  final String? message;
  final double size;

  const LoadingWidget({
    super.key,
    this.message,
    this.size = 24.0,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            width: size,
            height: size,
            child: const CircularProgressIndicator(),
          ),
          if (message != null) ...[
            const SizedBox(height: AppTheme.spacing16),
            Text(
              message!,
              style: AppTheme.bodyMedium,
              textAlign: TextAlign.center,
            ),
          ],
        ],
      ),
    );
  }
}

class MemphisLoadingWidget extends StatefulWidget {
  final String? message;
  final double size;

  const MemphisLoadingWidget({
    super.key,
    this.message,
    this.size = 48.0,
  });

  @override
  State<MemphisLoadingWidget> createState() => _MemphisLoadingWidgetState();
}

class _MemphisLoadingWidgetState extends State<MemphisLoadingWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          AnimatedBuilder(
            animation: _controller,
            builder: (context, child) {
              return Transform.rotate(
                angle: _controller.value * 2 * math.pi,
                child: SizedBox(
                  width: widget.size,
                  height: widget.size,
                  child: CustomPaint(
                    painter: _MemphisLoadingPainter(),
                  ),
                ),
              );
            },
          ),
          if (widget.message != null) ...[
            const SizedBox(height: AppTheme.spacing16),
            Text(
              widget.message!,
              style: AppTheme.bodyMedium,
              textAlign: TextAlign.center,
            ),
          ],
        ],
      ),
    );
  }
}

class _MemphisLoadingPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3
      ..strokeCap = StrokeCap.round;

    final colors = [
      AppTheme.memphisPink,
      AppTheme.memphisBlue,
      AppTheme.memphisYellow,
      AppTheme.memphisGreen,
    ];

    final rect = Rect.fromLTWH(0, 0, size.width, size.height);
    final sweepAngle = math.pi / 2;

    for (var i = 0; i < 4; i++) {
      paint.color = colors[i];
      canvas.drawArc(
        rect,
        i * sweepAngle,
        sweepAngle - 0.2,
        false,
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class EmptyStateWidget extends StatelessWidget {
  final IconData icon;
  final String title;
  final String? subtitle;
  final Widget? action;

  const EmptyStateWidget({
    super.key,
    required this.icon,
    required this.title,
    this.subtitle,
    this.action,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppTheme.spacing32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 64,
              color: theme.colorScheme.outline,
            ),
            const SizedBox(height: AppTheme.spacing16),
            Text(
              title,
              style: AppTheme.titleLarge.copyWith(
                color: theme.colorScheme.onSurface,
              ),
              textAlign: TextAlign.center,
            ),
            if (subtitle != null) ...[
              const SizedBox(height: AppTheme.spacing8),
              Text(
                subtitle!,
                style: AppTheme.bodyMedium.copyWith(
                  color: theme.colorScheme.outline,
                ),
                textAlign: TextAlign.center,
              ),
            ],
            if (action != null) ...[
              const SizedBox(height: AppTheme.spacing24),
              action!,
            ],
          ],
        ),
      ),
    );
  }
}

class MemphisEmptyStateWidget extends StatefulWidget {
  final IconData icon;
  final String title;
  final String? subtitle;
  final Widget? action;

  const MemphisEmptyStateWidget({
    super.key,
    required this.icon,
    required this.title,
    this.subtitle,
    this.action,
  });

  @override
  State<MemphisEmptyStateWidget> createState() =>
      _MemphisEmptyStateWidgetState();
}

class _MemphisEmptyStateWidgetState extends State<MemphisEmptyStateWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fadeAnimation;
  late Animation<double> _scaleAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.0, 0.6, curve: Curves.easeOut),
      ),
    );

    _scaleAnimation = Tween<double>(begin: 0.5, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.0, 0.6, curve: Curves.elasticOut),
      ),
    );

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.2),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOutCubic,
    ));

    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppTheme.spacing32),
        child: AnimatedBuilder(
          animation: _controller,
          builder: (context, child) {
            return FadeTransition(
              opacity: _fadeAnimation,
              child: SlideTransition(
                position: _slideAnimation,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Transform.scale(
                      scale: _scaleAnimation.value,
                      child: Container(
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: AppTheme.memphisPink.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(24),
                          border: Border.all(
                            color: AppTheme.memphisPink,
                            width: 2,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: AppTheme.memphisPink.withValues(alpha: 0.2),
                              offset: const Offset(4, 4),
                              blurRadius: 0,
                            ),
                          ],
                        ),
                        child: Icon(
                          widget.icon,
                          size: 64,
                          color: AppTheme.memphisPink,
                        ),
                      ),
                    ),
                    const SizedBox(height: AppTheme.spacing16),
                    Text(
                      widget.title,
                      style: AppTheme.titleLarge.copyWith(
                        color: theme.colorScheme.onSurface,
                        fontWeight: FontWeight.w700,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    if (widget.subtitle != null) ...[
                      const SizedBox(height: AppTheme.spacing8),
                      Text(
                        widget.subtitle!,
                        style: AppTheme.bodyMedium.copyWith(
                          color: theme.colorScheme.outline,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                    if (widget.action != null) ...[
                      const SizedBox(height: AppTheme.spacing24),
                      widget.action!,
                    ],
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

class ErrorStateWidget extends StatelessWidget {
  final String title;
  final String? subtitle;
  final VoidCallback? onRetry;

  const ErrorStateWidget({
    super.key,
    required this.title,
    this.subtitle,
    this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppTheme.spacing32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.error_outline,
              size: 64,
              color: theme.colorScheme.error,
            ),
            const SizedBox(height: AppTheme.spacing16),
            Text(
              title,
              style: AppTheme.titleLarge.copyWith(
                color: theme.colorScheme.onSurface,
              ),
              textAlign: TextAlign.center,
            ),
            if (subtitle != null) ...[
              const SizedBox(height: AppTheme.spacing8),
              Text(
                subtitle!,
                style: AppTheme.bodyMedium.copyWith(
                  color: theme.colorScheme.outline,
                ),
                textAlign: TextAlign.center,
              ),
            ],
            if (onRetry != null) ...[
              const SizedBox(height: AppTheme.spacing24),
              FilledButton.icon(
                onPressed: onRetry,
                icon: const Icon(Icons.refresh),
                label: const Text('重试'),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class MemphisErrorStateWidget extends StatefulWidget {
  final String title;
  final String? subtitle;
  final VoidCallback? onRetry;

  const MemphisErrorStateWidget({
    super.key,
    required this.title,
    this.subtitle,
    this.onRetry,
  });

  @override
  State<MemphisErrorStateWidget> createState() =>
      _MemphisErrorStateWidgetState();
}

class _MemphisErrorStateWidgetState extends State<MemphisErrorStateWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _shakeAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );

    _shakeAnimation = TweenSequence<double>([
      TweenSequenceItem(tween: Tween(begin: 0, end: 10), weight: 1),
      TweenSequenceItem(tween: Tween(begin: 10, end: -10), weight: 2),
      TweenSequenceItem(tween: Tween(begin: -10, end: 10), weight: 2),
      TweenSequenceItem(tween: Tween(begin: 10, end: -5), weight: 2),
      TweenSequenceItem(tween: Tween(begin: -5, end: 0), weight: 1),
    ]).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOutCubic,
    ));

    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppTheme.spacing32),
        child: AnimatedBuilder(
          animation: _controller,
          builder: (context, child) {
            return Transform.translate(
              offset: Offset(_shakeAnimation.value, 0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.red.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(
                        color: Colors.red,
                        width: 2,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.red.withValues(alpha: 0.2),
                          offset: const Offset(4, 4),
                          blurRadius: 0,
                        ),
                      ],
                    ),
                    child: const Icon(
                      Icons.error_outline,
                      size: 64,
                      color: Colors.red,
                    ),
                  ),
                  const SizedBox(height: AppTheme.spacing16),
                  Text(
                    widget.title,
                    style: AppTheme.titleLarge.copyWith(
                      color: theme.colorScheme.onSurface,
                      fontWeight: FontWeight.w700,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  if (widget.subtitle != null) ...[
                    const SizedBox(height: AppTheme.spacing8),
                    Text(
                      widget.subtitle!,
                      style: AppTheme.bodyMedium.copyWith(
                        color: theme.colorScheme.outline,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                  if (widget.onRetry != null) ...[
                    const SizedBox(height: AppTheme.spacing24),
                    _MemphisAnimatedButton(
                      onPressed: widget.onRetry!,
                      icon: Icons.refresh,
                      label: '重试',
                      backgroundColor: Colors.red,
                    ),
                  ],
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}

class StatsCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  final Color? color;
  final VoidCallback? onTap;

  const StatsCard({
    super.key,
    required this.title,
    required this.value,
    required this.icon,
    this.color,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cardColor = color ?? theme.colorScheme.primary;

    return Card(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppTheme.radiusLarge),
        child: Padding(
          padding: const EdgeInsets.all(AppTheme.spacing16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: [
                  Icon(
                    icon,
                    color: cardColor,
                    size: 20,
                  ),
                  const Spacer(),
                  if (onTap != null)
                    Icon(
                      Icons.arrow_forward_ios,
                      size: 12,
                      color: theme.colorScheme.outline,
                    ),
                ],
              ),
              const SizedBox(height: AppTheme.spacing8),
              Flexible(
                child: Text(
                  value,
                  style: AppTheme.titleLarge.copyWith(
                    color: theme.colorScheme.onSurface,
                    fontWeight: FontWeight.bold,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(height: AppTheme.spacing4),
              Flexible(
                child: Text(
                  title,
                  style: AppTheme.bodySmall.copyWith(
                    color: theme.colorScheme.outline,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class MemphisStatsCard extends StatefulWidget {
  final String title;
  final String value;
  final IconData icon;
  final Color? color;
  final VoidCallback? onTap;

  const MemphisStatsCard({
    super.key,
    required this.title,
    required this.value,
    required this.icon,
    this.color,
    this.onTap,
  });

  @override
  State<MemphisStatsCard> createState() => _MemphisStatsCardState();
}

class _MemphisStatsCardState extends State<MemphisStatsCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _hoverController;
  late Animation<double> _scaleAnimation;
  late Animation<double> _shadowAnimation;
  bool _isHovered = false;
  bool _isPressed = false;

  @override
  void initState() {
    super.initState();
    _hoverController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 200),
    );
    _scaleAnimation = Tween<double>(begin: 1.0, end: 1.02).animate(
      CurvedAnimation(parent: _hoverController, curve: Curves.easeOutCubic),
    );
    _shadowAnimation = Tween<double>(begin: 4.0, end: 6.0).animate(
      CurvedAnimation(parent: _hoverController, curve: Curves.easeOutCubic),
    );
  }

  @override
  void dispose() {
    _hoverController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cardColor = widget.color ?? AppTheme.memphisPink;

    return MouseRegion(
      onEnter: (_) {
        setState(() => _isHovered = true);
        _hoverController.forward();
      },
      onExit: (_) {
        setState(() => _isHovered = false);
        _hoverController.reverse();
      },
      child: GestureDetector(
        onTapDown: widget.onTap != null
            ? (_) => setState(() => _isPressed = true)
            : null,
        onTapUp: widget.onTap != null
            ? (_) {
                setState(() => _isPressed = false);
                widget.onTap?.call();
              }
            : null,
        onTapCancel:
            widget.onTap != null ? () => setState(() => _isPressed = false) : null,
        child: AnimatedBuilder(
          animation: _hoverController,
          builder: (context, child) {
            return Transform.scale(
              scale: _isPressed ? 0.98 : _scaleAnimation.value,
              child: Container(
                padding: const EdgeInsets.all(AppTheme.spacing16),
                decoration: BoxDecoration(
                  color: theme.cardColor,
                  borderRadius: BorderRadius.circular(AppTheme.radiusLarge),
                  border: Border.all(
                    color: AppTheme.memphisBlack,
                    width: 1.5,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: cardColor.withValues(alpha: _isHovered ? 0.4 : 0.2),
                      offset: Offset(_shadowAnimation.value, _shadowAnimation.value),
                      blurRadius: 0,
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: cardColor.withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: cardColor,
                              width: 1.5,
                            ),
                          ),
                          child: Icon(
                            widget.icon,
                            color: cardColor,
                            size: 18,
                          ),
                        ),
                        const Spacer(),
                        if (widget.onTap != null)
                          Icon(
                            Icons.arrow_forward_ios,
                            size: 12,
                            color: theme.colorScheme.outline,
                          ),
                      ],
                    ),
                    const SizedBox(height: AppTheme.spacing12),
                    Text(
                      widget.value,
                      style: AppTheme.titleLarge.copyWith(
                        color: theme.colorScheme.onSurface,
                        fontWeight: FontWeight.w700,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: AppTheme.spacing4),
                    Text(
                      widget.title,
                      style: AppTheme.bodySmall.copyWith(
                        color: theme.colorScheme.outline,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

class CustomDivider extends StatelessWidget {
  final double? height;
  final double? thickness;
  final Color? color;

  const CustomDivider({
    super.key,
    this.height,
    this.thickness,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      height: height ?? 1,
      color: color ?? theme.colorScheme.outline.withValues(alpha: 0.2),
      width: double.infinity,
    );
  }
}

class MemphisDivider extends StatelessWidget {
  final double height;
  final Color? color;
  final double dashWidth;
  final double dashSpacing;

  const MemphisDivider({
    super.key,
    this.height = 2,
    this.color,
    this.dashWidth = 8,
    this.dashSpacing = 4,
  });

  @override
  Widget build(BuildContext context) {
    final dividerColor = color ?? AppTheme.memphisBlack;

    return LayoutBuilder(
      builder: (context, constraints) {
        final dashCount =
            (constraints.maxWidth / (dashWidth + dashSpacing)).floor();
        return Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: List.generate(dashCount, (index) {
            return Container(
              width: dashWidth,
              height: height,
              decoration: BoxDecoration(
                color: index % 3 == 0
                    ? dividerColor
                    : index % 3 == 1
                        ? AppTheme.memphisPink
                        : AppTheme.memphisBlue,
                borderRadius: BorderRadius.circular(1),
              ),
            );
          }),
        );
      },
    );
  }
}

class CustomFAB extends StatelessWidget {
  final VoidCallback onPressed;
  final IconData icon;
  final String? tooltip;
  final bool isExtended;
  final String? label;

  const CustomFAB({
    super.key,
    required this.onPressed,
    required this.icon,
    this.tooltip,
    this.isExtended = false,
    this.label,
  });

  @override
  Widget build(BuildContext context) {
    if (isExtended && label != null) {
      return FloatingActionButton.extended(
        onPressed: onPressed,
        icon: Icon(icon),
        label: Text(label!),
        tooltip: tooltip,
      );
    }

    return FloatingActionButton(
      onPressed: onPressed,
      tooltip: tooltip,
      child: Icon(icon),
    );
  }
}

class MemphisFAB extends StatefulWidget {
  final VoidCallback onPressed;
  final IconData icon;
  final String? tooltip;
  final Color? backgroundColor;

  const MemphisFAB({
    super.key,
    required this.onPressed,
    required this.icon,
    this.tooltip,
    this.backgroundColor,
  });

  @override
  State<MemphisFAB> createState() => _MemphisFABState();
}

class _MemphisFABState extends State<MemphisFAB>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  late Animation<double> _rotationAnimation;
  late Animation<Offset> _shadowAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 150),
    );
    _scaleAnimation = Tween<double>(begin: 1.0, end: 0.9).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic),
    );
    _rotationAnimation = Tween<double>(begin: 0, end: 0.1).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic),
    );
    _shadowAnimation = Tween<Offset>(
      begin: const Offset(4, 4),
      end: const Offset(2, 2),
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bgColor = widget.backgroundColor ?? AppTheme.memphisPink;

    return GestureDetector(
      onTapDown: (_) => _controller.forward(),
      onTapUp: (_) {
        _controller.reverse();
        widget.onPressed();
      },
      onTapCancel: () => _controller.reverse(),
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, child) {
          return Transform.scale(
            scale: _scaleAnimation.value,
            child: Transform.rotate(
              angle: _rotationAnimation.value * math.pi,
              child: Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  color: bgColor,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: AppTheme.memphisBlack,
                    width: 1.5,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: bgColor.withValues(alpha: 0.4),
                      offset: _shadowAnimation.value,
                      blurRadius: 0,
                    ),
                  ],
                ),
                child: Icon(
                  widget.icon,
                  color: Colors.white,
                  size: 24,
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

class DeleteConfirmDialog extends StatelessWidget {
  final String title;
  final String content;
  final VoidCallback onConfirm;
  final VoidCallback? onCancel;
  final String confirmText;
  final String cancelText;

  const DeleteConfirmDialog({
    super.key,
    this.title = '确认删除',
    required this.content,
    required this.onConfirm,
    this.onCancel,
    this.confirmText = '删除',
    this.cancelText = '取消',
  });

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(title),
      content: Text(content),
      actions: [
        TextButton(
          onPressed: onCancel ?? () => Navigator.of(context).pop(),
          child: Text(cancelText),
        ),
        FilledButton(
          onPressed: () {
            Navigator.of(context).pop();
            onConfirm();
          },
          style: FilledButton.styleFrom(
            backgroundColor: Colors.red,
          ),
          child: Text(confirmText),
        ),
      ],
    );
  }

  // ignore: unused_element
  static void show(
    BuildContext context, {
    String title = '确认删除',
    required String content,
    required VoidCallback onConfirm,
    VoidCallback? onCancel,
    String confirmText = '删除',
    String cancelText = '取消',
  }) {
    showDialog(
      context: context,
      builder: (context) => DeleteConfirmDialog(
        title: title,
        content: content,
        onConfirm: onConfirm,
        onCancel: onCancel,
        confirmText: confirmText,
        cancelText: cancelText,
      ),
    );
  }
}

class MemphisDeleteConfirmDialog extends StatefulWidget {
  final String title;
  final String content;
  final VoidCallback onConfirm;
  final VoidCallback? onCancel;
  final String confirmText;
  final String cancelText;

  const MemphisDeleteConfirmDialog({
    super.key,
    this.title = '确认删除',
    required this.content,
    required this.onConfirm,
    this.onCancel,
    this.confirmText = '删除',
    this.cancelText = '取消',
  });

  @override
  State<MemphisDeleteConfirmDialog> createState() =>
      _MemphisDeleteConfirmDialogState();
}

class _MemphisDeleteConfirmDialogState
    extends State<MemphisDeleteConfirmDialog>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  late Animation<double> _shakeAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );
    _scaleAnimation = Tween<double>(begin: 0.8, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.elasticOut),
    );
    _shakeAnimation = TweenSequence<double>([
      TweenSequenceItem(tween: Tween(begin: 0, end: 5), weight: 1),
      TweenSequenceItem(tween: Tween(begin: 5, end: -5), weight: 2),
      TweenSequenceItem(tween: Tween(begin: -5, end: 3), weight: 1),
      TweenSequenceItem(tween: Tween(begin: 3, end: 0), weight: 1),
    ]).animate(CurvedAnimation(
      parent: _controller,
      curve: const Interval(0.0, 0.5, curve: Curves.easeOutCubic),
    ));
    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Transform.scale(
          scale: _scaleAnimation.value,
          child: Transform.translate(
            offset: Offset(_shakeAnimation.value, 0),
            child: Dialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
                side: const BorderSide(
                  color: AppTheme.memphisBlack,
                  width: 2,
                ),
              ),
              child: Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: Theme.of(context).dialogTheme.backgroundColor ?? Theme.of(context).canvasColor,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.red.withValues(alpha: 0.2),
                      offset: const Offset(6, 6),
                      blurRadius: 0,
                    ),
                  ],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.red.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: Colors.red,
                          width: 2,
                        ),
                      ),
                      child: const Icon(
                        Icons.warning_amber_rounded,
                        size: 48,
                        color: Colors.red,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      widget.title,
                      style: AppTheme.titleLarge.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      widget.content,
                      style: AppTheme.bodyMedium,
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 24),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        _MemphisAnimatedButton(
                          onPressed: () {
                            Navigator.of(context).pop();
                            widget.onCancel?.call();
                          },
                          label: widget.cancelText,
                          backgroundColor: Colors.grey,
                        ),
                        _MemphisAnimatedButton(
                          onPressed: () {
                            Navigator.of(context).pop();
                            widget.onConfirm();
                          },
                          label: widget.confirmText,
                          backgroundColor: Colors.red,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  // ignore: unused_element
  static void show(
    BuildContext context, {
    String title = '确认删除',
    required String content,
    required VoidCallback onConfirm,
    VoidCallback? onCancel,
    String confirmText = '删除',
    String cancelText = '取消',
  }) {
    showDialog(
      context: context,
      builder: (context) => MemphisDeleteConfirmDialog(
        title: title,
        content: content,
        onConfirm: onConfirm,
        onCancel: onCancel,
        confirmText: confirmText,
        cancelText: cancelText,
      ),
    );
  }
}

class _MemphisAnimatedButton extends StatefulWidget {
  final VoidCallback onPressed;
  final IconData? icon;
  final String label;
  final Color backgroundColor;

  const _MemphisAnimatedButton({
    required this.onPressed,
    this.icon,
    required this.label,
    required this.backgroundColor,
  });

  @override
  State<_MemphisAnimatedButton> createState() => _MemphisAnimatedButtonState();
}

class _MemphisAnimatedButtonState extends State<_MemphisAnimatedButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  late Animation<Offset> _shadowAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 100),
    );
    _scaleAnimation = Tween<double>(begin: 1.0, end: 0.95).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic),
    );
    _shadowAnimation = Tween<Offset>(
      begin: const Offset(4, 4),
      end: const Offset(2, 2),
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => _controller.forward(),
      onTapUp: (_) {
        _controller.reverse();
        widget.onPressed();
      },
      onTapCancel: () => _controller.reverse(),
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, child) {
          return Transform.scale(
            scale: _scaleAnimation.value,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              decoration: BoxDecoration(
                color: widget.backgroundColor,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: AppTheme.memphisBlack,
                  width: 1.5,
                ),
                boxShadow: [
                  BoxShadow(
                    color: widget.backgroundColor.withValues(alpha: 0.4),
                    offset: _shadowAnimation.value,
                    blurRadius: 0,
                  ),
                ],
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (widget.icon != null) ...[
                    Icon(
                      widget.icon,
                      size: 18,
                      color: Colors.white,
                    ),
                    const SizedBox(width: 8),
                  ],
                  Text(
                    widget.label,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w700,
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

void showQuickSnackBar(BuildContext context, String message, {Color? backgroundColor}) {
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      content: Text(message),
      duration: const Duration(seconds: 2),
      backgroundColor: backgroundColor,
    ),
  );
}
