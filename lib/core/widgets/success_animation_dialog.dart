import 'package:flutter/material.dart';
import '../constants/app_colors.dart';
import '../constants/app_dimensions.dart';
import '../constants/app_typography.dart';
import '../utils/haptic_feedback_util.dart';

class SuccessAnimationDialog extends StatefulWidget {
  final String title;
  final String? subtitle;

  const SuccessAnimationDialog({
    super.key,
    required this.title,
    this.subtitle,
  });

  static Future<void> show(
    BuildContext context, {
    required String title,
    String? subtitle,
  }) {
    HapticUtil.medium();
    return showDialog(
      context: context,
      barrierDismissible: true,
      builder: (context) => SuccessAnimationDialog(
        title: title,
        subtitle: subtitle,
      ),
    );
  }

  @override
  State<SuccessAnimationDialog> createState() => _SuccessAnimationDialogState();
}

class _SuccessAnimationDialogState extends State<SuccessAnimationDialog>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _scaleAnimation;
  late final Animation<double> _opacityAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );

    _scaleAnimation = CurvedAnimation(
      parent: _controller,
      curve: Curves.elasticOut,
    );

    _opacityAnimation = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeIn,
    );

    _controller.forward();

    // Auto dismiss
    Future.delayed(const Duration(milliseconds: 1400), () {
      if (mounted && Navigator.of(context).canPop()) {
        Navigator.of(context).pop();
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      elevation: 0,
      insetPadding: const EdgeInsets.symmetric(horizontal: AppDimensions.space32),
      child: Center(
        child: Container(
          padding: const EdgeInsets.symmetric(
            horizontal: AppDimensions.space24,
            vertical: AppDimensions.space24,
          ),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(AppDimensions.radiusCard),
            border: Border.all(color: AppColors.border, width: 1.0),
            boxShadow: const [
              BoxShadow(
                color: AppColors.shadowColor,
                blurRadius: 24,
                offset: Offset(0, 8),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ScaleTransition(
                scale: _scaleAnimation,
                child: Container(
                  width: 56,
                  height: 56,
                  decoration: const BoxDecoration(
                    color: AppColors.receivedGreenLight,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.check_rounded,
                    color: AppColors.receivedGreen,
                    size: 32,
                  ),
                ),
              ),
              const SizedBox(height: AppDimensions.space16),
              FadeTransition(
                opacity: _opacityAnimation,
                child: Column(
                  children: [
                    Text(
                      widget.title,
                      style: AppTypography.titleMedium,
                      textAlign: TextAlign.center,
                    ),
                    if (widget.subtitle != null) ...[
                      const SizedBox(height: AppDimensions.space4),
                      Text(
                        widget.subtitle!,
                        style: AppTypography.bodySmall,
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
