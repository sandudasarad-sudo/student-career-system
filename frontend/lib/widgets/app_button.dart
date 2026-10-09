import 'package:flutter/material.dart';

import '../config/app_theme.dart';

enum AppButtonVariant { primary, outline, danger }

class AppButton extends StatelessWidget {
  final String text;
  final VoidCallback? onPressed;
  final bool isLoading;
  final IconData? icon;
  final AppButtonVariant variant;
  final double? width;
  final double height;

  const AppButton({
    super.key,
    required this.text,
    this.onPressed,
    this.isLoading = false,
    this.icon,
    this.variant = AppButtonVariant.primary,
    this.width,
    this.height = 48,
  });

  @override
  Widget build(BuildContext context) {
    Widget child;
    if (isLoading) {
      child = const SizedBox(
        width: 22,
        height: 22,
        child: CircularProgressIndicator(
          strokeWidth: 2.2,
          valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
        ),
      );
    } else if (icon != null) {
      child = Row(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [Icon(icon, size: 18), const SizedBox(width: 8), Text(text)],
      );
    } else {
      child = Text(text);
    }

    if (variant == AppButtonVariant.outline) {
      return SizedBox(
        width: width,
        height: height,
        child: OutlinedButton(
          onPressed: isLoading ? null : onPressed,
          child: child,
        ),
      );
    }

    final bgColor = variant == AppButtonVariant.danger
        ? AppTheme.statusRejected
        : AppTheme.primaryColor;

    return SizedBox(
      width: width,
      height: height,
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: bgColor,
          foregroundColor: Colors.white,
        ),
        onPressed: isLoading ? null : onPressed,
        child: child,
      ),
    );
  }
}
