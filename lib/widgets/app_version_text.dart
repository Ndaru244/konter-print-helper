import "package:flutter/material.dart";
import "package:package_info_plus/package_info_plus.dart";

/// Tinggi `NavigationBar` Material 3. Dipakai agar SnackBar tidak menutup tab.
const double shellNavigationBarHeight = 80;

String formatAppVersion(PackageInfo info) {
  return "versi ${info.version} (${info.buildNumber})";
}

class AppVersionText extends StatelessWidget {
  const AppVersionText({super.key, this.style});

  final TextStyle? style;

  @override
  Widget build(BuildContext context) {
    final textStyle = style ?? Theme.of(context).textTheme.bodyMedium;
    return FutureBuilder<PackageInfo>(
      future: PackageInfo.fromPlatform(),
      builder: (context, snapshot) {
        final label = snapshot.hasData
            ? formatAppVersion(snapshot.data!)
            : "versi …";
        return Text(label, style: textStyle, textAlign: TextAlign.center);
      },
    );
  }
}
