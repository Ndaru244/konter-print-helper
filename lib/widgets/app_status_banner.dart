import "package:flutter/material.dart";
import "package:cetak_struk/theme/app_colors.dart";

enum AppStatusTone { success, warning, danger, info }

/// Banner status. [inset] memakai radius 16 + border; full-bleed radius 0.
class AppStatusBanner extends StatelessWidget {
  const AppStatusBanner({
    super.key,
    required this.tone,
    required this.message,
    required this.icon,
    this.subtitle,
    this.trailing,
    this.inset = false,
    this.center = false,
  });

  final AppStatusTone tone;
  final String message;
  final String? subtitle;
  final IconData icon;
  final Widget? trailing;
  final bool inset;
  final bool center;

  @override
  Widget build(BuildContext context) {
    final palette = _paletteFor(tone);
    final theme = Theme.of(context);
    final messageStyle = theme.textTheme.bodyMedium?.copyWith(
      color: palette.text,
      fontWeight: FontWeight.w600,
    );
    final subtitleStyle = theme.textTheme.bodySmall?.copyWith(
      color: palette.text,
    );

    final text = Column(
      crossAxisAlignment: center
          ? CrossAxisAlignment.center
          : CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(message, style: messageStyle),
        if (subtitle != null) Text(subtitle!, style: subtitleStyle),
      ],
    );

    return Container(
      width: double.infinity,
      constraints: const BoxConstraints(minHeight: 48),
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
      decoration: BoxDecoration(
        color: palette.background,
        borderRadius: inset ? BorderRadius.circular(16) : BorderRadius.zero,
        border: inset ? Border.all(color: palette.border) : null,
      ),
      child: Row(
        mainAxisAlignment: center
            ? MainAxisAlignment.center
            : MainAxisAlignment.start,
        children: [
          Icon(icon, size: 20, color: palette.icon),
          const SizedBox(width: 8),
          if (center) Flexible(child: text) else Expanded(child: text),
          if (trailing != null) ...[const SizedBox(width: 8), trailing!],
        ],
      ),
    );
  }

  static _StatusPalette _paletteFor(AppStatusTone tone) {
    return switch (tone) {
      AppStatusTone.success => const _StatusPalette(
        background: AppColors.successBackground,
        icon: AppColors.successIcon,
        text: AppColors.successText,
        border: AppColors.successBorder,
      ),
      AppStatusTone.warning => const _StatusPalette(
        background: AppColors.warningBackground,
        icon: AppColors.warningIcon,
        text: AppColors.warningText,
        border: AppColors.warningBorder,
      ),
      AppStatusTone.danger => const _StatusPalette(
        background: AppColors.dangerBackground,
        icon: AppColors.dangerIcon,
        text: AppColors.dangerText,
        border: AppColors.dangerBorder,
      ),
      AppStatusTone.info => const _StatusPalette(
        background: AppColors.infoBackground,
        icon: AppColors.infoIcon,
        text: AppColors.infoText,
        border: AppColors.infoBorder,
      ),
    };
  }
}

class _StatusPalette {
  const _StatusPalette({
    required this.background,
    required this.icon,
    required this.text,
    required this.border,
  });

  final Color background;
  final Color icon;
  final Color text;
  final Color border;
}
