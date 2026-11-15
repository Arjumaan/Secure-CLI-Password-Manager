import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';

class NeumorphicBox extends StatelessWidget {
  final Widget child;
  final bool isSunken;
  final double borderRadius;
  final EdgeInsetsGeometry padding;
  final double? width;
  final double? height;
  final Color? surfaceColor;

  const NeumorphicBox({
    Key? key,
    required this.child,
    this.isSunken = false,
    this.borderRadius = 16.0,
    this.padding = const EdgeInsets.all(16.0),
    this.width,
    this.height,
    this.surfaceColor,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final bg = surfaceColor ?? AppColors.background;

    return Container(
      width: width,
      height: height,
      padding: padding,
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(borderRadius),
        boxShadow: isSunken
            ? [
                BoxShadow(
                  color: AppColors.sunkenShadow,
                  offset: const Offset(3, 3),
                  blurRadius: 5,
                  spreadRadius: -1,
                ),
                const BoxShadow(
                  color: AppColors.shadowLight,
                  offset: Offset(-3, -3),
                  blurRadius: 5,
                  spreadRadius: -1,
                ),
              ]
            : [
                BoxShadow(
                  color: AppColors.shadowDark,
                  offset: const Offset(6, 6),
                  blurRadius: 14,
                  spreadRadius: 0,
                ),
                const BoxShadow(
                  color: AppColors.shadowLight,
                  offset: Offset(-6, -6),
                  blurRadius: 14,
                  spreadRadius: 0,
                ),
              ],
      ),
      child: child,
    );
  }
}
