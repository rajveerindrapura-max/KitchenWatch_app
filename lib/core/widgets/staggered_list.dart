import 'package:flutter/material.dart';

class StaggeredListItem extends StatelessWidget {
  final int index;
  final Widget child;
  final Duration baseDelay;
  final Duration duration;

  const StaggeredListItem({
    super.key,
    required this.index,
    required this.child,
    this.baseDelay = const Duration(milliseconds: 40),
    this.duration = const Duration(milliseconds: 350),
  });

  @override
  Widget build(BuildContext context) {
    final disableAnimations = MediaQuery.maybeOf(context)?.disableAnimations ?? false;

    if (disableAnimations) {
      return child;
    }

    final delay = baseDelay * index.clamp(0, 10);

    return TweenAnimationBuilder<double>(
      tween: Tween<double>(begin: 0.0, end: 1.0),
      duration: duration + delay,
      curve: Curves.easeOutCubic,
      builder: (context, value, staticChild) {
        // Only start fading in after proportion of delay
        final delayedValue = (value * (duration + delay).inMilliseconds - delay.inMilliseconds) /
            duration.inMilliseconds;
        final clampedValue = delayedValue.clamp(0.0, 1.0);

        return Opacity(
          opacity: clampedValue,
          child: Transform.translate(
            offset: Offset(0, 14 * (1.0 - clampedValue)),
            child: staticChild,
          ),
        );
      },
      child: child,
    );
  }
}
