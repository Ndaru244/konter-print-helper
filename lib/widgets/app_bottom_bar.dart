import "package:flutter/material.dart";
import "package:cetak_struk/theme/app_colors.dart";

/// Bar aksi bawah: surface putih, padding 16, SafeArea, bayangan halus.
class AppBottomBar extends StatelessWidget {
  const AppBottomBar({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        boxShadow: [
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
