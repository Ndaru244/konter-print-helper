import "package:flutter/material.dart";
import "package:cetak_struk/theme/app_colors.dart";

/// Tile ikon lembut: primary-50, radius 8, ikon primary.
class AppIconTile extends StatelessWidget {
  const AppIconTile({super.key, required this.icon, this.iconSize = 24});

  final IconData icon;
  final double iconSize;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 48,
      height: 48,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: AppColors.primary50,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Icon(
        icon,
        size: iconSize,
        color: Theme.of(context).colorScheme.primary,
      ),
    );
  }
}
