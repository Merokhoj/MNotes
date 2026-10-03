import 'dart:ui';
import 'package:flutter/material.dart';
import 'app_colors.dart';
import 'app_theme.dart';

/// Reusable Neo-Glass Surface with Frosted Blur and Optional Prism Refraction
class NeoGlassContainer extends StatelessWidget {
  final Widget child;
  final double? width;
  final double? height;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;
  final double borderRadius;
  final double blur;
  final bool isPrism;
  final bool isHeavy;
  final Color? customColor;
  final Border? customBorder;
  final VoidCallback? onTap;

  const NeoGlassContainer({
    super.key,
    required this.child,
    this.width,
    this.height,
    this.padding,
    this.margin,
    this.borderRadius = AppSpacing.radiusMd,
    this.blur = 18.0,
    this.isPrism = false,
    this.isHeavy = false,
    this.customColor,
    this.customBorder,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final isDark = context.isDark;

    final baseColor = customColor ?? (isHeavy ? colors.glassHeavy : colors.glass);

    Widget content = Container(
      width: width,
      height: height,
      padding: padding,
      margin: margin,
      decoration: BoxDecoration(
        color: isPrism ? null : baseColor,
        gradient: isPrism ? colors.prismGradient : null,
        borderRadius: BorderRadius.circular(borderRadius),
        border: customBorder ??
            Border.all(
              color: isPrism
                  ? colors.primary.withOpacity(0.35)
                  : colors.glassBorder,
              width: 1.0,
            ),
        boxShadow: [
          BoxShadow(
            color: isDark
                ? Colors.black.withOpacity(0.3)
                : const Color(0xFF6857F5).withOpacity(0.04),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
          if (isPrism)
            BoxShadow(
              color: colors.primary.withOpacity(0.12),
              blurRadius: 20,
              offset: const Offset(0, 2),
            ),
        ],
      ),
      child: child,
    );

    if (blur > 0) {
      content = ClipRRect(
        borderRadius: BorderRadius.circular(borderRadius),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: blur, sigmaY: blur),
          child: content,
        ),
      );
    }

    if (onTap != null) {
      return Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(borderRadius),
          child: content,
        ),
      );
    }

    return content;
  }
}

/// Interactive Neo-Glass Button with micro-animations and prism hover glow
class NeoGlassButton extends StatefulWidget {
  final Widget child;
  final VoidCallback onPressed;
  final bool isPrimary;
  final EdgeInsetsGeometry? padding;
  final String? tooltip;
  final double borderRadius;

  const NeoGlassButton({
    super.key,
    required this.child,
    required this.onPressed,
    this.isPrimary = false,
    this.padding,
    this.tooltip,
    this.borderRadius = AppSpacing.radiusSm,
  });

  @override
  State<NeoGlassButton> createState() => _NeoGlassButtonState();
}

class _NeoGlassButtonState extends State<NeoGlassButton> {
  bool _isHovered = false;
  bool _isPressed = false;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;

    final baseColor = widget.isPrimary
        ? colors.primary
        : (_isHovered
            ? colors.surface2
            : colors.glass);

    Widget button = MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: GestureDetector(
        onTapDown: (_) => setState(() => _isPressed = true),
        onTapUp: (_) => setState(() => _isPressed = false),
        onTapCancel: () => setState(() => _isPressed = false),
        onTap: widget.onPressed,
        child: AnimatedScale(
          scale: _isPressed ? 0.97 : (_isHovered ? 1.02 : 1.0),
          duration: const Duration(milliseconds: 140),
          curve: Curves.easeOutCubic,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 160),
            padding: widget.padding ??
                const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            decoration: BoxDecoration(
              color: baseColor,
              borderRadius: BorderRadius.circular(widget.borderRadius),
              border: Border.all(
                color: widget.isPrimary
                    ? Colors.transparent
                    : (_isHovered
                        ? colors.primary.withOpacity(0.4)
                        : colors.glassBorder),
                width: 1.0,
              ),
              boxShadow: [
                if (widget.isPrimary || _isHovered)
                  BoxShadow(
                    color: colors.primary.withOpacity(_isHovered ? 0.25 : 0.15),
                    blurRadius: 10,
                    offset: const Offset(0, 3),
                  ),
              ],
            ),
            child: DefaultTextStyle(
              style: TextStyle(
                fontSize: 12.5,
                fontWeight: FontWeight.w600,
                color: widget.isPrimary
                    ? Colors.white
                    : (_isHovered ? colors.primary : colors.textPrimary),
              ),
              child: widget.child,
            ),
          ),
        ),
      ),
    );

    if (widget.tooltip != null) {
      return Tooltip(message: widget.tooltip!, child: button);
    }
    return button;
  }
}

/// Frosted Prism Badge for tags, categories and status
class NeoGlassBadge extends StatelessWidget {
  final String label;
  final IconData? icon;
  final Color? color;
  final VoidCallback? onDelete;
  final VoidCallback? onTap;

  const NeoGlassBadge({
    super.key,
    required this.label,
    this.icon,
    this.color,
    this.onDelete,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final badgeColor = color ?? colors.primary;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppSpacing.radiusFull),
        child: Container(
          padding: EdgeInsets.only(
            left: 8,
            right: onDelete != null ? 4 : 8,
            top: 2.5,
            bottom: 2.5,
          ),
          decoration: BoxDecoration(
            color: badgeColor.withOpacity(0.12),
            borderRadius: BorderRadius.circular(AppSpacing.radiusFull),
            border: Border.all(
              color: badgeColor.withOpacity(0.3),
              width: 0.8,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (icon != null) ...[
                Icon(icon, size: 11, color: badgeColor),
                const SizedBox(width: 4),
              ],
              Text(
                label,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: badgeColor,
                ),
              ),
              if (onDelete != null) ...[
                const SizedBox(width: 2),
                InkWell(
                  onTap: onDelete,
                  borderRadius: BorderRadius.circular(8),
                  child: Padding(
                    padding: const EdgeInsets.all(2),
                    child: Icon(
                      Icons.close_rounded,
                      size: 11,
                      color: badgeColor.withOpacity(0.7),
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
