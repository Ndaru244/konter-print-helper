import "package:flutter/material.dart";

/// Field outline dari InputDecorationTheme: tinggi minimum 48, teks 16.
class AppTextField extends StatelessWidget {
  const AppTextField({
    super.key,
    required this.controller,
    required this.label,
    this.minLines = 1,
    this.maxLines = 1,
  });

  final TextEditingController controller;
  final String label;
  final int minLines;
  final int? maxLines;

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      minLines: minLines,
      maxLines: maxLines,
      style: Theme.of(context).textTheme.bodyLarge,
      decoration: InputDecoration(
        labelText: label,
        alignLabelWithHint: minLines > 1,
      ),
    );
  }
}
