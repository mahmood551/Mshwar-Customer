import 'package:cabme/common/widget/custom_text.dart';
import 'package:cabme/core/themes/constant_colors.dart';
import 'package:cabme/core/utils/dark_theme_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:provider/provider.dart';

class CustomButton extends StatelessWidget {
  final String? btnName;
  final VoidCallback? ontap;
  final Color? textColor;
  final Color? buttonColor;
  final Color? outlineColor;
  final double? height;
  final double? borderRadius;
  final double? fontSize;
  final bool? isLoading;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;
  final List<BoxShadow>? boxShadow;
  final Gradient? gradient;
  final AlignmentGeometry? alignment;
  final bool isOutlined;
  final double? borderWidth;
  final Widget? icon;
  final FontWeight? fontWeight;

  const CustomButton({
    super.key,
    this.ontap,
    this.btnName,
    this.buttonColor,
    this.textColor,
    this.outlineColor,
    this.height,
    this.borderRadius,
    this.fontSize,
    this.isLoading = false,
    this.padding,
    this.margin,
    this.boxShadow,
    this.gradient,
    this.alignment,
    this.isOutlined = false,
    this.borderWidth,
    this.icon,
    this.fontWeight,
  });

  @override
  Widget build(BuildContext context) {
    final themeChange = Provider.of<DarkThemeProvider>(context);
    final isDarkMode = themeChange.getThem();

    return Container(
      margin: margin,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: (isLoading ?? false) ? null : ontap,
          borderRadius: BorderRadius.circular(borderRadius ?? 14),
          splashColor: AppThemeData.primary200.withOpacity(0.1),
          highlightColor: AppThemeData.primary200.withOpacity(0.05),
          child: Ink(
            height: height ?? 56,
            padding: padding ??
                const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(borderRadius ?? 14),
              boxShadow: boxShadow ??
                  (isOutlined
                      ? null
                      : [
                          BoxShadow(
                            color: AppThemeData.primary200.withOpacity(0.2),
                            blurRadius: 8,
                            offset: const Offset(0, 4),
                          ),
                        ]),
              color: _getBackgroundColor(isDarkMode),
              gradient: isOutlined ? null : gradient,
              border: isOutlined
                  ? Border.all(
                      color: outlineColor ?? AppThemeData.primary200,
                      width: borderWidth ?? 1.5,
                    )
                  : null,
            ),
            child: Center(
              child: (isLoading ?? false)
                  ? SpinKitThreeBounce(
                      size: 24,
                      color: _getTextColor(isDarkMode),
                    )
                  : icon != null
                      ? Row(
                          mainAxisSize: MainAxisSize.min,
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            icon!,
                            const SizedBox(width: 12),
                            CustomText(
                              text: btnName ?? 'Get Started',
                              color: _getTextColor(isDarkMode),
                              size: fontSize ?? 16,
                              weight: fontWeight ?? FontWeight.w600,
                            ),
                          ],
                        )
                      : CustomText(
                          text: btnName ?? 'Get Started',
                          color: _getTextColor(isDarkMode),
                          size: fontSize ?? 16,
                          weight: fontWeight ?? FontWeight.w600,
                        ),
            ),
          ),
        ),
      ),
    );
  }

  // 🔹 Background logic
  Color? _getBackgroundColor(bool isDarkMode) {
    if (isOutlined) return Colors.transparent;
    if (gradient != null) return null; // gradient takes over
    return buttonColor ?? AppThemeData.primary200;
  }

  // 🔹 Text color logic
  Color _getTextColor(bool isDarkMode) {
    if (isOutlined) {
      return textColor ?? outlineColor ?? AppThemeData.primary200;
    }
    return textColor ?? Colors.white;
  }
}
