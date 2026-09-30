import "package:flutter/material.dart";
import "package:cetak_struk/theme/app_colors.dart";

/// Bar aksi bawah: surface tema, padding 16, SafeArea.
/// Light memakai bayangan halus; dark memakai garis atas slate-700.
class AppBottomBar extends StatelessWidget {
  const AppBottomBar({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final dark = theme.brightness == Brightness.dark;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        border: dark
            ? const Border(top: BorderSide(color: AppColors.slate700))
            : null,
        boxShadow: dark
            ? null
            : [
                BoxShadow(
                  color: AppColors.slate900.withValues(alpha: 0.08),
                  blurRadius: 16,
                  offset: const Offset(0, -4),
                ),
              ],
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: SizedBox(width: double.infinity, child: child),
        ),
      ),
    );
  }
}
