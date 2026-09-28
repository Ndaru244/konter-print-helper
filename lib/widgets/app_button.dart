import "package:flutter/material.dart";
import "package:cetak_struk/theme/app_colors.dart";

enum AppButtonVariant { primary, secondary, text, destructive }

/// Tombol dengan tinggi tetap: primer 56, sekunder/teks/destruktif 48, radius 12.
class AppButton extends StatelessWidget {
  const AppButton.primary({
    super.key,
    required this.label,
    required this.onPressed,
    this.icon,
    this.loading = false,
    this.expand = true,
  }) : variant = AppButtonVariant.primary;

  const AppButton.secondary({
    super.key,
    required this.label,
    required this.onPressed,
    this.icon,
    this.loading = false,
    this.expand = true,
  }) : variant = AppButtonVariant.secondary;

  const AppButton.text({
    super.key,
    required this.label,
    required this.onPressed,
    this.icon,
    this.loading = false,
    this.expand = false,
  }) : variant = AppButtonVariant.text;

  const AppButton.destructive({
    super.key,
    required this.label,
    required this.onPressed,
    this.icon,
    this.loading = false,
    this.expand = false,
  }) : variant = AppButtonVariant.destructive;

  final String label;
  final VoidCallback? onPressed;
  final IconData? icon;
  final bool loading;
  final bool expand;
  final AppButtonVariant variant;

  @override
  Widget build(BuildContext context) {
    final enabled = onPressed != null && !loading;
    final style = _style(context);
    final visual = _leading(context);
    final labelWidget = Text(label);

    return switch (variant) {
      AppButtonVariant.primary || AppButtonVariant.destructive =>
        visual == null
            ? FilledButton(
                onPressed: enabled ? onPressed : null,
                style: style,
                child: labelWidget,
              )
            : FilledButton.icon(
                onPressed: enabled ? onPressed : null,
                style: style,
                icon: visual,
                label: labelWidget,
              ),
      AppButtonVariant.secondary =>
        visual == null
            ? OutlinedButton(
                onPressed: enabled ? onPressed : null,
                style: style,
                child: labelWidget,
              )
            : OutlinedButton.icon(
                onPressed: enabled ? onPressed : null,
                style: style,
                icon: visual,
                label: labelWidget,
              ),
      AppButtonVariant.text =>
        visual == null
            ? TextButton(
                onPressed: enabled ? onPressed : null,
                style: style,
                child: labelWidget,
              )
            : TextButton.icon(
                onPressed: enabled ? onPressed : null,
                style: style,
                icon: visual,
                label: labelWidget,
              ),
    };
  }

  Widget? _leading(BuildContext context) {
    if (loading) {
      return SizedBox(
        width: 20,
        height: 20,
        child: CircularProgressIndicator(
          strokeWidth: 2,
          color: _foreground(context),
        ),
      );
    }
    if (icon == null) return null;
    return Icon(icon, size: 20);
  }

  Color _foreground(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return switch (variant) {
      AppButtonVariant.primary => scheme.onPrimary,
      AppButtonVariant.destructive => Colors.white,
      AppButtonVariant.secondary || AppButtonVariant.text => scheme.primary,
    };
  }

  ButtonStyle _style(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final shape = RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(12),
    );
    final secondaryLabel = theme.textTheme.labelLarge?.copyWith(
      fontSize: 14,
      height: 20 / 14,
    );

    return switch (variant) {
      AppButtonVariant.primary =>
        FilledButton.styleFrom(
          minimumSize: Size(expand ? double.infinity : 0, 56),
          backgroundColor: scheme.primary,
          foregroundColor: scheme.onPrimary,
          disabledBackgroundColor: scheme.primary.withValues(alpha: 0.38),
          disabledForegroundColor: scheme.onPrimary,
          textStyle: theme.textTheme.labelLarge,
          elevation: 0,
          shape: shape,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
        ).copyWith(
          backgroundColor: WidgetStateProperty.resolveWith((states) {
            if (states.contains(WidgetState.disabled)) {
              return scheme.primary.withValues(alpha: 0.38);
            }
            if (states.contains(WidgetState.pressed)) {
              return AppColors.primary700;
            }
            return scheme.primary;
          }),
        ),
      AppButtonVariant.secondary =>
        OutlinedButton.styleFrom(
          minimumSize: Size(expand ? double.infinity : 0, 48),
          foregroundColor: scheme.primary,
          disabledForegroundColor: AppColors.slate400,
          textStyle: secondaryLabel,
          shape: shape,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
        ).copyWith(
          side: WidgetStateProperty.resolveWith((states) {
            final color = states.contains(WidgetState.disabled)
                ? AppColors.slate200
                : AppColors.slate300;
            return BorderSide(color: color);
          }),
        ),
      AppButtonVariant.text => TextButton.styleFrom(
        minimumSize: Size(expand ? double.infinity : 48, 48),
        foregroundColor: scheme.primary,
        textStyle: secondaryLabel,
        shape: shape,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
      ),
      AppButtonVariant.destructive =>
        FilledButton.styleFrom(
          minimumSize: Size(expand ? double.infinity : 0, 48),
          backgroundColor: AppColors.dangerFill,
          foregroundColor: Colors.white,
          disabledBackgroundColor: AppColors.dangerFill.withValues(alpha: 0.38),
          disabledForegroundColor: Colors.white,
          textStyle: secondaryLabel,
          elevation: 0,
          shape: shape,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
        ).copyWith(
          backgroundColor: WidgetStateProperty.resolveWith((states) {
            if (states.contains(WidgetState.disabled)) {
              return AppColors.dangerFill.withValues(alpha: 0.38);
            }
            if (states.contains(WidgetState.pressed)) {
              return Color.alphaBlend(
                Colors.black.withValues(alpha: 0.12),
                AppColors.dangerFill,
              );
            }
            return AppColors.dangerFill;
          }),
        ),
    };
  }
}
