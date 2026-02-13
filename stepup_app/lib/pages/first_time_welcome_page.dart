import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../models/user.dart';
import '../services/user_dao.dart';
import '../theme/app_theme.dart';
import 'dart:math' as math;

class FirstTimeWelcomePage extends StatefulWidget {
  const FirstTimeWelcomePage({super.key});

  @override
  State<FirstTimeWelcomePage> createState() => _FirstTimeWelcomePageState();
}

class _FirstTimeWelcomePageState extends State<FirstTimeWelcomePage>
    with TickerProviderStateMixin {
  final TextEditingController _nameController = TextEditingController();
  final UserDao _userDao = UserDao();
  bool _isLoading = false;
  String? _errorMessage;

  late AnimationController _mainController;
  late AnimationController _floatingController;
  late Animation<double> _fadeAnimation;
  late Animation<double> _slideAnimation;
  late Animation<double> _scaleAnimation;
  late Animation<double> _iconRotationAnimation;

  @override
  void initState() {
    super.initState();
    _mainController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );

    _floatingController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 3000),
    )..repeat(reverse: true);

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _mainController,
        curve: const Interval(0.0, 0.4, curve: Curves.easeOut),
      ),
    );

    _slideAnimation = Tween<double>(begin: 50.0, end: 0.0).animate(
      CurvedAnimation(
        parent: _mainController,
        curve: const Interval(0.0, 0.6, curve: Curves.easeOutCubic),
      ),
    );

    _scaleAnimation = Tween<double>(begin: 0.8, end: 1.0).animate(
      CurvedAnimation(
        parent: _mainController,
        curve: const Interval(0.0, 0.5, curve: Curves.elasticOut),
      ),
    );

    _iconRotationAnimation = Tween<double>(begin: -0.1, end: 0.1).animate(
      CurvedAnimation(
        parent: _floatingController,
        curve: Curves.easeInOutSine,
      ),
    );

    _mainController.forward();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _mainController.dispose();
    _floatingController.dispose();
    super.dispose();
  }

  Future<void> _saveUserName() async {
    if (_nameController.text.trim().isEmpty) {
      setState(() {
        _errorMessage = '请输入您的姓名';
      });
      return;
    }

    try {
      setState(() {
        _isLoading = true;
        _errorMessage = null;
      });

      final now = DateTime.now();
      final user = User(
        name: _nameController.text.trim(),
        studentId: '',
        email: '',
        phone: '',
        major: '',
        grade: 1,
        createdAt: now,
        updatedAt: now,
      );

      await _userDao.addUser(user);

      if (mounted) {
        context.go('/home');
      }
    } catch (e) {
      setState(() {
        _errorMessage = '保存失败: $e';
        _isLoading = false;
      });
    }
  }

  Future<void> _skipAndContinue() async {
    try {
      setState(() {
        _isLoading = true;
      });

      final now = DateTime.now();
      final user = User(
        name: '用户',
        studentId: '',
        email: '',
        phone: '',
        major: '',
        grade: 1,
        createdAt: now,
        updatedAt: now,
      );

      await _userDao.addUser(user);

      if (mounted) {
        context.go('/home');
      }
    } catch (e) {
      setState(() {
        _errorMessage = '创建用户失败: $e';
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      body: Stack(
        children: [
          _buildBackgroundDecorations(),
          SingleChildScrollView(
            padding: const EdgeInsets.all(24.0),
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 400),
                child: AnimatedBuilder(
                  animation: _mainController,
                  builder: (context, child) {
                    return Transform.translate(
                      offset: Offset(0, _slideAnimation.value),
                      child: Opacity(
                        opacity: _fadeAnimation.value,
                        child: child,
                      ),
                    );
                  },
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      const SizedBox(height: 64),
                      _buildAnimatedLogo(),
                      const SizedBox(height: 24),
                      _buildAnimatedTitle(),
                      const SizedBox(height: 8),
                      _buildAnimatedSubtitle(),
                      const SizedBox(height: 40),
                      if (_errorMessage != null) _buildErrorMessage(),
                      _buildAnimatedTextField(),
                      const SizedBox(height: 24),
                      _buildAnimatedButton(),
                      const SizedBox(height: 16),
                      _buildSkipButton(),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBackgroundDecorations() {
    return Positioned.fill(
      child: IgnorePointer(
        child: AnimatedBuilder(
          animation: _mainController,
          builder: (context, child) {
            return Opacity(
              opacity: _fadeAnimation.value * 0.3,
              child: Stack(
                children: [
                  _buildFloatingShape(
                    top: 80,
                    left: 30,
                    size: 60,
                    color: AppTheme.memphisPink,
                    shape: _ShapeType.circle,
                    delay: 0,
                  ),
                  _buildFloatingShape(
                    top: 150,
                    right: 40,
                    size: 40,
                    color: AppTheme.memphisYellow,
                    shape: _ShapeType.triangle,
                    delay: 200,
                  ),
                  _buildFloatingShape(
                    bottom: 120,
                    left: 50,
                    size: 50,
                    color: AppTheme.memphisBlue,
                    shape: _ShapeType.diamond,
                    delay: 400,
                  ),
                  _buildFloatingShape(
                    bottom: 80,
                    right: 60,
                    size: 35,
                    color: AppTheme.memphisGreen,
                    shape: _ShapeType.circle,
                    delay: 600,
                  ),
                  _buildFloatingShape(
                    top: 250,
                    left: 20,
                    size: 25,
                    color: AppTheme.memphisPurple,
                    shape: _ShapeType.cross,
                    delay: 800,
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildFloatingShape({
    double? top,
    double? bottom,
    double? left,
    double? right,
    required double size,
    required Color color,
    required _ShapeType shape,
    required int delay,
  }) {
    return Positioned(
      top: top,
      bottom: bottom,
      left: left,
      right: right,
      child: TweenAnimationBuilder<double>(
        tween: Tween(begin: 0.0, end: 1.0),
        duration: Duration(milliseconds: 800 + delay),
        curve: Curves.elasticOut,
        builder: (context, value, child) {
          return Transform.scale(
            scale: value,
            child: AnimatedBuilder(
              animation: _floatingController,
              builder: (context, child) {
                final offset = math.sin(
                  _floatingController.value * math.pi * 2 + delay * 0.01,
                ) * 10;
                return Transform.translate(
                  offset: Offset(0, offset),
                  child: child,
                );
              },
              child: _buildShape(shape, size, color),
            ),
          );
        },
      ),
    );
  }

  Widget _buildShape(_ShapeType shape, double size, Color color) {
    switch (shape) {
      case _ShapeType.circle:
        return Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
            border: Border.all(color: AppTheme.memphisBlack, width: 1.5),
          ),
        );
      case _ShapeType.triangle:
        return CustomPaint(
          size: Size(size, size),
          painter: _TrianglePainter(color),
        );
      case _ShapeType.diamond:
        return Transform.rotate(
          angle: math.pi / 4,
          child: Container(
            width: size * 0.7,
            height: size * 0.7,
            decoration: BoxDecoration(
              color: color,
              border: Border.all(color: AppTheme.memphisBlack, width: 1.5),
            ),
          ),
        );
      case _ShapeType.cross:
        return Icon(
          Icons.add,
          size: size,
          color: color,
        );
    }
  }

  Widget _buildAnimatedLogo() {
    return AnimatedBuilder(
      animation: _mainController,
      builder: (context, child) {
        return Transform.scale(
          scale: _scaleAnimation.value,
          child: AnimatedBuilder(
            animation: _floatingController,
            builder: (context, child) {
              return Transform.rotate(
                angle: _iconRotationAnimation.value,
                child: child,
              );
            },
            child: Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    AppTheme.memphisPink,
                    AppTheme.memphisYellow,
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(30),
                border: Border.all(
                  color: AppTheme.memphisBlack,
                  width: 2,
                ),
                boxShadow: [
                  BoxShadow(
                    color: AppTheme.memphisBlack.withValues(alpha: 0.2),
                    offset: const Offset(6, 6),
                    blurRadius: 0,
                  ),
                ],
              ),
              child: Hero(
                tag: 'app_logo',
                child: Icon(
                  Icons.trending_up,
                  size: 60,
                  color: Colors.white,
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildAnimatedTitle() {
    return AnimatedBuilder(
      animation: _mainController,
      builder: (context, child) {
        return Transform.translate(
          offset: Offset(0, 20 * (1 - _fadeAnimation.value)),
          child: Opacity(
            opacity: _fadeAnimation.value,
            child: child,
          ),
        );
      },
      child: Text(
        '欢迎使用 StepUp',
        style: AppTheme.headlineLarge,
        textAlign: TextAlign.center,
      ),
    );
  }

  Widget _buildAnimatedSubtitle() {
    return AnimatedBuilder(
      animation: _mainController,
      builder: (context, child) {
        return Transform.translate(
          offset: Offset(0, 15 * (1 - Curves.easeOut.transform(
            _mainController.value.clamp(0.2, 0.6) - 0.2,
          ))),
          child: Opacity(
            opacity: Curves.easeOut.transform(
              _mainController.value.clamp(0.2, 0.6) - 0.2,
            ),
            child: child,
          ),
        );
      },
      child: Text(
        '请告诉我们您的姓名，让我们更好地为您服务',
        style: AppTheme.bodyMedium,
        textAlign: TextAlign.center,
      ),
    );
  }

  Widget _buildErrorMessage() {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.0, end: 1.0),
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeOut,
      builder: (context, value, child) {
        return Transform.scale(
          scale: value,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            margin: const EdgeInsets.only(bottom: 16),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.errorContainer,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: Theme.of(context).colorScheme.error,
                width: 1.5,
              ),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.error_outline,
                  color: Theme.of(context).colorScheme.error,
                  size: 20,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    _errorMessage!,
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.error,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildAnimatedTextField() {
    return AnimatedBuilder(
      animation: _mainController,
      builder: (context, child) {
        return Transform.translate(
          offset: Offset(0, 20 * (1 - Curves.easeOut.transform(
            _mainController.value.clamp(0.3, 0.7) - 0.3,
          ))),
          child: Opacity(
            opacity: Curves.easeOut.transform(
              _mainController.value.clamp(0.3, 0.7) - 0.3,
            ),
            child: child,
          ),
        );
      },
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: AppTheme.memphisBlack.withValues(alpha: 0.1),
              offset: const Offset(4, 4),
              blurRadius: 0,
            ),
          ],
        ),
        child: TextField(
          controller: _nameController,
          decoration: InputDecoration(
            labelText: '姓名',
            hintText: '请输入您的姓名',
            prefixIcon: const Icon(Icons.person),
            filled: true,
            fillColor: Theme.of(context).colorScheme.surface,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: const BorderSide(
                color: AppTheme.memphisBlack,
                width: 1.5,
              ),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: const BorderSide(
                color: AppTheme.memphisBlack,
                width: 1.5,
              ),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: BorderSide(
                color: Theme.of(context).colorScheme.primary,
                width: 2,
              ),
            ),
          ),
          textInputAction: TextInputAction.done,
          onSubmitted: (_) => _saveUserName(),
        ),
      ),
    );
  }

  Widget _buildAnimatedButton() {
    return AnimatedBuilder(
      animation: _mainController,
      builder: (context, child) {
        return Transform.translate(
          offset: Offset(0, 20 * (1 - Curves.easeOut.transform(
            _mainController.value.clamp(0.4, 0.8) - 0.4,
          ))),
          child: Opacity(
            opacity: Curves.easeOut.transform(
              _mainController.value.clamp(0.4, 0.8) - 0.4,
            ),
            child: child,
          ),
        );
      },
      child: SizedBox(
        width: double.infinity,
        child: _MemphisAnimatedButton(
          onPressed: _isLoading ? null : _saveUserName,
          backgroundColor: AppTheme.memphisPink,
          child: _isLoading
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Colors.white,
                  ),
                )
              : const Text(
                  '开始使用',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                  ),
                ),
        ),
      ),
    );
  }

  Widget _buildSkipButton() {
    return AnimatedBuilder(
      animation: _mainController,
      builder: (context, child) {
        return Opacity(
          opacity: Curves.easeOut.transform(
            _mainController.value.clamp(0.5, 0.9) - 0.5,
          ),
          child: child,
        );
      },
      child: TextButton(
        onPressed: _isLoading ? null : _skipAndContinue,
        style: TextButton.styleFrom(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
        ),
        child: const Text('跳过，稍后设置'),
      ),
    );
  }
}

enum _ShapeType { circle, triangle, diamond, cross }

class _TrianglePainter extends CustomPainter {
  final Color color;

  _TrianglePainter(this.color);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;

    final path = Path()
      ..moveTo(size.width / 2, 0)
      ..lineTo(size.width, size.height)
      ..lineTo(0, size.height)
      ..close();

    canvas.drawPath(path, paint);

    final borderPaint = Paint()
      ..color = AppTheme.memphisBlack
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;

    canvas.drawPath(path, borderPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _MemphisAnimatedButton extends StatefulWidget {
  final VoidCallback? onPressed;
  final Widget child;
  final Color? backgroundColor;

  const _MemphisAnimatedButton({
    required this.onPressed,
    required this.child,
    this.backgroundColor,
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
    final bgColor = widget.backgroundColor ?? AppTheme.primaryColor;

    return GestureDetector(
      onTapDown: widget.onPressed != null
          ? (_) => _controller.forward()
          : null,
      onTapUp: widget.onPressed != null
          ? (_) {
              _controller.reverse();
              widget.onPressed?.call();
            }
          : null,
      onTapCancel: widget.onPressed != null
          ? () => _controller.reverse()
          : null,
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, child) {
          return Transform.scale(
            scale: _scaleAnimation.value,
            child: Container(
              decoration: BoxDecoration(
                color: bgColor,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: AppTheme.memphisBlack,
                  width: 1.5,
                ),
                boxShadow: [
                  BoxShadow(
                    color: AppTheme.memphisBlack.withValues(alpha: 0.3),
                    offset: _shadowAnimation.value,
                    blurRadius: 0,
                  ),
                ],
              ),
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
              child: Center(child: widget.child),
            ),
          );
        },
      ),
    );
  }
}
