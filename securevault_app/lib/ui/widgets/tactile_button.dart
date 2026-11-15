import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';

class TactileButton extends StatefulWidget {
  final Widget child;
  final VoidCallback? onPressed;
  final double borderRadius;
  final EdgeInsetsGeometry padding;
  final Color? backgroundColor;
  final bool isPrimary;
  final double? width;

  const TactileButton({
    Key? key,
    required this.child,
    required this.onPressed,
    this.borderRadius = 14.0,
    this.padding = const EdgeInsets.symmetric(horizontal: 20.0, vertical: 14.0),
    this.backgroundColor,
    this.isPrimary = false,
    this.width,
  }) : super(key: key);

  @override
  State<TactileButton> createState() => _TactileButtonState();
}

class _TactileButtonState extends State<TactileButton> {
  bool _isPressed = false;

  @override
  Widget build(BuildContext context) {
    final enabled = widget.onPressed != null;
    final bg = widget.isPrimary
        ? AppColors.primary
        : (widget.backgroundColor ?? AppColors.background);

    return GestureDetector(
      onTapDown: enabled ? (_) => setState(() => _isPressed = true) : null,
      onTapUp: enabled
          ? (_) {
              setState(() => _isPressed = false);
              widget.onPressed?.call();
            }
          : null,
      onTapCancel: enabled ? () => setState(() => _isPressed = false) : null,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 120),
        width: widget.width,
        padding: widget.padding,
        decoration: BoxDecoration(
          color: enabled ? bg : bg.withOpacity(0.6),
          borderRadius: BorderRadius.circular(widget.borderRadius),
          boxShadow: _isPressed || !enabled
              ? [
                  BoxShadow(
                    color: AppColors.sunkenShadow.withOpacity(0.3),
                    offset: const Offset(2, 2),
                    blurRadius: 4,
                  ),
                ]
              : [
                  BoxShadow(
                    color: widget.isPrimary
                        ? AppColors.primary.withOpacity(0.35)
                        : AppColors.shadowDark,
                    offset: const Offset(4, 5),
                    blurRadius: 12,
                  ),
                  const BoxShadow(
                    color: AppColors.shadowLight,
                    offset: Offset(-4, -4),
                    blurRadius: 10,
                  ),
                ],
        ),
        child: Center(child: widget.child),
      ),
    );
  }
}
