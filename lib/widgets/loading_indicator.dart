import 'package:flutter/material.dart';
import '../utils/theme.dart';

/// Modern circular loading indicator with animated gradient.
class LoadingIndicator extends StatefulWidget {
  final double size;
  final Color? color;
  final String? label;
  final bool showLabel;

  const LoadingIndicator({
    super.key,
    this.size = 50,
    this.color,
    this.label,
    this.showLabel = true,
  });

  @override
  State<LoadingIndicator> createState() => _LoadingIndicatorState();
}

class _LoadingIndicatorState extends State<LoadingIndicator>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(
          width: widget.size,
          height: widget.size,
          child: Stack(
            children: [
              // Background circle
              Container(
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: (widget.color ?? AppTheme.primaryColor)
                      .withValues(alpha: 0.1),
                ),
              ),
              // Rotating gradient border
              RotationTransition(
                turns: _controller,
                child: Container(
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: Colors.transparent,
                      width: 3,
                    ),
                  ),
                  child: ShaderMask(
                    shaderCallback: (rect) {
                      return SweepGradient(
                        colors: [
                          (widget.color ?? AppTheme.primaryColor)
                              .withValues(alpha: 0),
                          (widget.color ?? AppTheme.primaryColor)
                              .withValues(alpha: 0.3),
                          (widget.color ?? AppTheme.primaryColor),
                          (widget.color ?? AppTheme.primaryColor),
                        ],
                        stops: const [0, 0.3, 0.7, 1],
                      ).createShader(rect);
                    },
                    blendMode: BlendMode.srcIn,
                    child: Container(
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: Colors.white,
                          width: 3,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              // Center dot
              Center(
                child: Container(
                  width: 10,
                  height: 10,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: widget.color ?? AppTheme.primaryColor,
                  ),
                ),
              ),
            ],
          ),
        ),
        if (widget.showLabel && widget.label != null) ...[
          const SizedBox(height: 12),
          Text(
            widget.label!,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: AppTheme.textSecondary,
            ),
          ),
        ],
      ],
    );
  }
}

/// Minimal circular loading with pulsing effect.
class PulsingLoader extends StatefulWidget {
  final double size;
  final Color? color;

  const PulsingLoader({
    super.key,
    this.size = 50,
    this.color,
  });

  @override
  State<PulsingLoader> createState() => _PulsingLoaderState();
}

class _PulsingLoaderState extends State<PulsingLoader>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    )..repeat();
    _animation = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ScaleTransition(
      scale: _animation.drive(
        Tween<double>(begin: 0.8, end: 1.2),
      ),
      child: Container(
        width: widget.size,
        height: widget.size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: (widget.color ?? AppTheme.primaryColor)
              .withValues(alpha: 0.3),
        ),
        child: Center(
          child: Container(
            width: widget.size * 0.6,
            height: widget.size * 0.6,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: widget.color ?? AppTheme.primaryColor,
            ),
          ),
        ),
      ),
    );
  }
}

/// Animated dots loader (3 bouncing dots).
class DotsLoader extends StatefulWidget {
  final Color? color;
  final double dotSize;

  const DotsLoader({
    super.key,
    this.color,
    this.dotSize = 8,
  });

  @override
  State<DotsLoader> createState() => _DotsLoaderState();
}

class _DotsLoaderState extends State<DotsLoader>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(3, (i) {
        final delay = i * 0.15;
        return ScaleTransition(
          scale: Tween<double>(begin: 0.6, end: 1).animate(
            CurvedAnimation(
              parent: _controller,
              curve: Interval(
                delay,
                delay + 0.5,
                curve: Curves.easeInOut,
              ),
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: Container(
              width: widget.dotSize,
              height: widget.dotSize,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: widget.color ?? AppTheme.primaryColor,
              ),
            ),
          ),
        );
      }),
    );
  }
}

/// Loading state widget with centered indicator and optional message.
class LoadingState extends StatelessWidget {
  final String? message;
  final Color? color;
  final double indicatorSize;
  final bool showMessage;

  const LoadingState({
    super.key,
    this.message = 'Memuat...',
    this.color,
    this.indicatorSize = 50,
    this.showMessage = true,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          LoadingIndicator(
            size: indicatorSize,
            color: color,
            showLabel: false,
          ),
          if (showMessage && message != null) ...[
            const SizedBox(height: 12),
            Text(
              message!,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: AppTheme.textSecondary,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

/// Shimmer loading skeleton for content placeholder.
class ShimmerLoader extends StatefulWidget {
  final double height;
  final double? width;
  final BorderRadius borderRadius;

  const ShimmerLoader({
    super.key,
    this.height = 16,
    this.width,
    BorderRadius? borderRadius,
  }) : borderRadius = borderRadius ??
            const BorderRadius.all(Radius.circular(8));

  @override
  State<ShimmerLoader> createState() => _ShimmerLoaderState();
}

class _ShimmerLoaderState extends State<ShimmerLoader>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    )..repeat();
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
        return ShaderMask(
          shaderCallback: (rect) {
            return LinearGradient(
              begin: Alignment.centerLeft,
              end: Alignment.centerRight,
              colors: const [
                Colors.transparent,
                Colors.white54,
                Colors.transparent,
              ],
              stops: [
                _controller.value - 0.3,
                _controller.value,
                _controller.value + 0.3,
              ],
            ).createShader(rect);
          },
          blendMode: BlendMode.lighten,
          child: Container(
            width: widget.width ?? double.infinity,
            height: widget.height,
            decoration: BoxDecoration(
              color: Colors.grey.shade300,
              borderRadius: widget.borderRadius,
            ),
          ),
        );
      },
    );
  }
}

/// Custom list tile shimmer loader with multiple lines.
class ShimmerListTile extends StatelessWidget {
  final BorderRadius borderRadius;

  const ShimmerListTile({
    super.key,
    BorderRadius? borderRadius,
  }) : borderRadius =
            borderRadius ?? const BorderRadius.all(Radius.circular(12));

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: borderRadius,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              // Avatar placeholder
              ShimmerLoader(
                width: 40,
                height: 40,
                borderRadius: BorderRadius.circular(8),
              ),
              const SizedBox(width: 12),
              // Title and subtitle
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    ShimmerLoader(
                      height: 12,
                      width: 120,
                      borderRadius: BorderRadius.circular(4),
                    ),
                    const SizedBox(height: 6),
                    ShimmerLoader(
                      height: 10,
                      width: 80,
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ],
                ),
              ),
              // Right placeholder
              ShimmerLoader(
                width: 50,
                height: 12,
                borderRadius: BorderRadius.circular(4),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// Loading overlay that covers the entire screen.
class LoadingOverlay extends StatelessWidget {
  final bool isLoading;
  final Widget child;
  final String? message;
  final Color? backgroundColor;

  const LoadingOverlay({
    super.key,
    required this.isLoading,
    required this.child,
    this.message,
    this.backgroundColor,
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        child,
        if (isLoading)
          Container(
            color: (backgroundColor ?? Colors.black).withValues(alpha: 0.3),
            child: Center(
              child: LoadingState(
                message: message,
                showMessage: message != null,
              ),
            ),
          ),
      ],
    );
  }
}

/// Animated bottom sheet loading indicator.
class BottomSheetLoading extends StatelessWidget {
  final String? message;
  final Color? color;

  const BottomSheetLoading({
    super.key,
    this.message = 'Sedang memproses...',
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Theme.of(context).scaffoldBackgroundColor,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Drag handle
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.grey.shade300,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 24),
          LoadingIndicator(
            size: 60,
            color: color,
            label: message,
            showLabel: true,
          ),
        ],
      ),
    );
  }
}

/// Extension to easily show loading dialogs.
extension LoadingDialog on BuildContext {
  /// Show a simple loading dialog
  Future<void> showLoadingDialog({
    String? message,
    bool barrierDismissible = false,
  }) async {
    return showDialog(
      context: this,
      barrierDismissible: barrierDismissible,
      builder: (_) => PopScope(
        canPop: barrierDismissible,
        child: Dialog(
          backgroundColor: Colors.transparent,
          elevation: 0,
          child: LoadingState(message: message),
        ),
      ),
    );
  }

  /// Hide loading dialog
  void hideLoadingDialog() {
    if (mounted) {
      Navigator.pop(this);
    }
  }
}
