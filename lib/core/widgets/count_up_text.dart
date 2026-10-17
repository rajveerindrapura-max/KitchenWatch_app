import 'package:flutter/material.dart';

class CountUpText extends StatelessWidget {
  final num value;
  final TextStyle? style;
  final Duration duration;
  final String Function(num value) formatter;

  const CountUpText({
    super.key,
    required this.value,
    required this.formatter,
    this.style,
    this.duration = const Duration(milliseconds: 900),
  });

  @override
  Widget build(BuildContext context) {
    final disableAnimations = MediaQuery.maybeOf(context)?.disableAnimations ?? false;

    if (disableAnimations) {
      return Text(formatter(value), style: style);
    }

    return TweenAnimationBuilder<double>(
      tween: Tween<double>(begin: 0.0, end: value.toDouble()),
      duration: duration,
      curve: Curves.easeOutCubic,
      builder: (context, currentValue, child) {
        return Text(
          formatter(currentValue),
          style: style,
        );
      },
    );
  }
}
