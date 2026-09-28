import "package:flutter/material.dart";
import "package:cetak_struk/theme/app_colors.dart";

/// Keadaan kosong: ikon 48, judul titleMedium, deskripsi bodyMedium slate-500.
class AppEmptyState extends StatelessWidget {
  const AppEmptyState({
    super.key,
    required this.icon,
    required this.title,
    required this.description,
  });

  final IconData icon;
  final String title;
  final String description;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 48, color: AppColors.slate300),
        const SizedBox(height: 16),
        Text(
          title,
          style: theme.textTheme.titleMedium,
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 8),
        Text(
          description,
          style: theme.textTheme.bodyMedium?.copyWith(
            color: AppColors.slate500,
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }
}
