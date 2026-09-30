import 'package:cetak_struk/brand.dart';
import 'package:shared_preferences/shared_preferences.dart';

class StoreProfile {
  static const namaTokoKey = 'namaToko';
  static const catatanKey = 'catatanStruk';
  static const defaultCatatan =
      'Simpan struk ini sebagai bukti transaksi yang sah.';

  const StoreProfile({required this.namaToko, required this.catatan});

  final String namaToko;
  final String catatan;

  static Future<StoreProfile> load() async {
    final prefs = await SharedPreferences.getInstance();
    final savedName = prefs.getString(namaTokoKey)?.trim();
    return StoreProfile(
      namaToko: (savedName == null || savedName.isEmpty)
          ? Brand.name
          : savedName,
      catatan: prefs.getString(catatanKey) ?? defaultCatatan,
    );
  }

  static Future<void> save({
    required String namaToko,
    required String catatan,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    final name = namaToko.trim().isEmpty ? Brand.name : namaToko.trim();
    await prefs.setString(namaTokoKey, name);
    await prefs.setString(catatanKey, catatan);
  }
}
