import "package:flutter/material.dart";

/// Tile ikon lembut: primary-50, radius 8, ikon primary.
class AppIconTile extends StatelessWidget {
  const AppIconTile({super.key, required this.icon, this.iconSize = 24});

  final IconData icon;
  final double iconSize;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      width: 48,
      height: 48,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: theme.colorScheme.primaryContainer,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Icon(icon, size: iconSize, color: theme.colorScheme.primary),
    );
  }
}
