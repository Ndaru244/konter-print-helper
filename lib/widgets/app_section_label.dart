import "package:flutter/material.dart";

/// Label section: labelMedium 12 w600, tracking 0.6, slate-500.
class AppSectionLabel extends StatelessWidget {
  const AppSectionLabel({
    super.key,
    required this.label,
    this.uppercase = true,
  });

  final String label;
  final bool uppercase;

  @override
  Widget build(BuildContext context) {
    return Text(
      uppercase ? label.toUpperCase() : label,
      style: Theme.of(context).textTheme.labelMedium,
    );
  }
}
