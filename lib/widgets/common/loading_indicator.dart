import 'package:flutter/material.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';

/// Common loading indicator widget used throughout the app
class LoadingIndicator extends StatelessWidget {
  final String? message;
  final Color? color;
  final double size;
  final bool showMessage;
  final LoadingType type;

  const LoadingIndicator({
    Key? key,
    this.message,
    this.color,
    this.size = 50.0,
    this.showMessage = true,
    this.type = LoadingType.circle,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final Color indicatorColor = color ?? Theme.of(context).primaryColor;

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          _buildLoadingWidget(indicatorColor),
          if (showMessage && message != null) ...[
            const SizedBox(height: 16),
            Text(
              message!,
              style: Theme.of(
                context,
              ).textTheme.bodyMedium?.copyWith(color: Colors.grey[600]),
              textAlign: TextAlign.center,
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildLoadingWidget(Color color) {
    switch (type) {
      case LoadingType.circle:
        return SpinKitCircle(color: color, size: size);
      case LoadingType.pulse:
        return SpinKitPulse(color: color, size: size);
      case LoadingType.wave:
        return SpinKitWave(color: color, size: size);
      case LoadingType.dots:
        return SpinKitThreeBounce(color: color, size: size * 0.6);
      case LoadingType.ring:
        return SpinKitRing(color: color, size: size);
      case LoadingType.fading:
        return SpinKitFadingCube(color: color, size: size);
    }
  }
}

/// Different types of loading animations
enum LoadingType { circle, pulse, wave, dots, ring, fading }

/// Small loading indicator for inline use
class SmallLoadingIndicator extends StatelessWidget {
  final Color? color;
  final double size;

  const SmallLoadingIndicator({Key? key, this.color, this.size = 20.0})
    : super(key: key);

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: CircularProgressIndicator(
        color: color ?? Theme.of(context).primaryColor,
        strokeWidth: 2.0,
      ),
    );
  }
}

/// Loading overlay that can be shown over other widgets
class LoadingOverlay extends StatelessWidget {
  final bool isLoading;
  final Widget child;
  final String? message;
  final Color? backgroundColor;
  final LoadingType type;

  const LoadingOverlay({
    Key? key,
    required this.isLoading,
    required this.child,
    this.message,
    this.backgroundColor,
    this.type = LoadingType.circle,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        child,
        if (isLoading)
          Container(
            color: backgroundColor ?? Colors.black.withOpacity(0.3),
            child: LoadingIndicator(message: message, type: type),
          ),
      ],
    );
  }
}

/// Button with loading state
class LoadingButton extends StatelessWidget {
  final bool isLoading;
  final VoidCallback? onPressed;
  final String text;
  final String? loadingText;
  final IconData? icon;
  final Color? backgroundColor;
  final Color? textColor;
  final double? width;
  final double height;

  const LoadingButton({
    Key? key,
    required this.isLoading,
    required this.onPressed,
    required this.text,
    this.loadingText,
    this.icon,
    this.backgroundColor,
    this.textColor,
    this.width,
    this.height = 48.0,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: width,
      height: height,
      child: ElevatedButton(
        onPressed: isLoading ? null : onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: backgroundColor ?? Theme.of(context).primaryColor,
          foregroundColor: textColor ?? Colors.white,
          disabledBackgroundColor:
              backgroundColor?.withOpacity(0.6) ??
              Theme.of(context).primaryColor.withOpacity(0.6),
        ),
        child: isLoading
            ? Row(
                mainAxisAlignment: MainAxisAlignment.center,
                mainAxisSize: MainAxisSize.min,
                children: [
                  const SmallLoadingIndicator(color: Colors.white),
                  if (loadingText != null) ...[
                    const SizedBox(width: 8),
                    Text(loadingText!),
                  ],
                ],
              )
            : Row(
                mainAxisAlignment: MainAxisAlignment.center,
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (icon != null) ...[Icon(icon), const SizedBox(width: 8)],
                  Text(text),
                ],
              ),
      ),
    );
  }
}

/// Progress indicator with percentage
class ProgressIndicator extends StatelessWidget {
  final double progress;
  final String? label;
  final Color? color;
  final Color? backgroundColor;
  final double height;
  final bool showPercentage;

  const ProgressIndicator({
    Key? key,
    required this.progress,
    this.label,
    this.color,
    this.backgroundColor,
    this.height = 8.0,
    this.showPercentage = true,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final progressColor = color ?? Theme.of(context).primaryColor;
    final bgColor = backgroundColor ?? Colors.grey[300];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (label != null || showPercentage)
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              if (label != null)
                Text(label!, style: Theme.of(context).textTheme.bodySmall),
              if (showPercentage)
                Text(
                  '${(progress * 100).round()}%',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: progressColor,
                  ),
                ),
            ],
          ),
        if (label != null || showPercentage) const SizedBox(height: 4),
        Container(
          height: height,
          decoration: BoxDecoration(
            color: bgColor,
            borderRadius: BorderRadius.circular(height / 2),
          ),
          child: FractionallySizedBox(
            alignment: Alignment.centerLeft,
            widthFactor: progress.clamp(0.0, 1.0),
            child: Container(
              decoration: BoxDecoration(
                color: progressColor,
                borderRadius: BorderRadius.circular(height / 2),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

/// Skeleton loading placeholder
class SkeletonLoader extends StatefulWidget {
  final double? width;
  final double height;
  final BorderRadius? borderRadius;
  final Color? baseColor;
  final Color? highlightColor;

  const SkeletonLoader({
    Key? key,
    this.width,
    required this.height,
    this.borderRadius,
    this.baseColor,
    this.highlightColor,
  }) : super(key: key);

  @override
  State<SkeletonLoader> createState() => _SkeletonLoaderState();
}

class _SkeletonLoaderState extends State<SkeletonLoader>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    )..repeat();
    _animation = Tween<double>(begin: 0.0, end: 1.0).animate(_controller);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final baseColor = widget.baseColor ?? Colors.grey[300]!;
    final highlightColor = widget.highlightColor ?? Colors.grey[100]!;

    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        return Container(
          width: widget.width,
          height: widget.height,
          decoration: BoxDecoration(
            borderRadius: widget.borderRadius ?? BorderRadius.circular(4),
            gradient: LinearGradient(
              colors: [baseColor, highlightColor, baseColor],
              stops: [
                (_animation.value - 0.3).clamp(0.0, 1.0),
                _animation.value,
                (_animation.value + 0.3).clamp(0.0, 1.0),
              ],
              begin: Alignment.centerLeft,
              end: Alignment.centerRight,
            ),
          ),
        );
      },
    );
  }
}

/// List of skeleton items
class SkeletonList extends StatelessWidget {
  final int itemCount;
  final double itemHeight;
  final EdgeInsetsGeometry? padding;

  const SkeletonList({
    Key? key,
    required this.itemCount,
    this.itemHeight = 80.0,
    this.padding,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      padding: padding,
      itemCount: itemCount,
      itemBuilder: (context, index) {
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 4.0),
          child: Row(
            children: [
              SkeletonLoader(
                width: 60,
                height: 60,
                borderRadius: BorderRadius.circular(8),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SkeletonLoader(
                      width: double.infinity,
                      height: 16,
                      borderRadius: BorderRadius.circular(4),
                    ),
                    const SizedBox(height: 8),
                    SkeletonLoader(
                      width: 200,
                      height: 14,
                      borderRadius: BorderRadius.circular(4),
                    ),
                    const SizedBox(height: 8),
                    SkeletonLoader(
                      width: 150,
                      height: 12,
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
