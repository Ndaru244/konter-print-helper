import "package:flutter/material.dart";
import "package:cetak_struk/widgets/app_version_text.dart";

SnackBar appSnackBar(BuildContext context, String message) {
  final inShell = ModalRoute.of(context)?.isFirst ?? true;
  final systemInset = MediaQuery.viewPaddingOf(context).bottom;
  final bottom = inShell
      ? systemInset + shellNavigationBarHeight + 16
      : systemInset + 16;
  return SnackBar(
    behavior: SnackBarBehavior.floating,
    margin: EdgeInsets.fromLTRB(16, 0, 16, bottom),
    content: Text(message),
  );
}
