import "package:flutter/services.dart";

/// Nama brand. Satu-satunya tempat mengedit: berkas `brand.txt` di akar repo.
abstract final class Brand {
  static late final String name;

  static Future<void> load() async {
    name = (await rootBundle.loadString("brand.txt")).trim();
  }
}
