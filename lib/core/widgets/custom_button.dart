import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class CustomButton extends StatelessWidget {
  final String text;
  final VoidCallback? onPressed;
  final bool isLoading;
  final bool isOutlined;
  final double width;
  final Color? backgroundColor;
  final Color? textColor;
  final Color? borderColor;
  final IconData? icon; // Added icon parameter
  final double? iconSize; // Added icon size parameter

  const CustomButton({
    super.key,
    required this.text,
    required this.onPressed,
    this.isLoading = false,
    this.isOutlined = false,
    this.width = double.infinity,
    this.backgroundColor,
    this.textColor,
    this.borderColor,
    this.icon, // Optional icon
    this.iconSize = 18.0, // Default icon size
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: width,
      child: isOutlined
          ? OutlinedButton(
              onPressed: isLoading ? null : onPressed,
              style: OutlinedButton.styleFrom(
                side: BorderSide(color: borderColor ?? AppTheme.primaryColor),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                padding: const EdgeInsets.symmetric(vertical: 15),
              ),
              child: _buttonContent(),
            )
          : ElevatedButton(
              onPressed: isLoading ? null : onPressed,
              style: ElevatedButton.styleFrom(
                backgroundColor: backgroundColor ?? AppTheme.primaryColor,
                foregroundColor: textColor ?? Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                  side: borderColor != null
                      ? BorderSide(color: borderColor!)
                      : BorderSide.none,
                ),
                padding: const EdgeInsets.symmetric(vertical: 15),
              ),
              child: _buttonContent(),
            ),
    );
  }

  Widget _buttonContent() {
    if (isLoading) {
      return const SizedBox(
        height: 20,
        width: 20,
        child: CircularProgressIndicator(
          color: Colors.white,
          strokeWidth: 2,
        ),
      );
    }

    // Text style for button
    final textStyle = TextStyle(
      fontSize: 16,
      fontWeight: FontWeight.w600,
      color: isOutlined
          ? borderColor ?? AppTheme.primaryColor
          : textColor ?? Colors.white,
    );

    // If there's an icon, show icon and text
    if (icon != null) {
      return Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            icon,
            size: iconSize,
            color: isOutlined
                ? borderColor ?? AppTheme.primaryColor
                : textColor ?? Colors.white,
          ),
          const SizedBox(width: 8),
          Text(text, style: textStyle),
        ],
      );
    }

    // Otherwise just show text
    return Text(text, style: textStyle);
  }
}
