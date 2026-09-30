# Changelog

## 0.2.0

Beta. Nomor versi hanya di `pubspec.yaml` (`0.2.0+5`).

### Navigasi dan pengaturan

- Bottom navigation: Beranda, Printer, dan Pengaturan.
- Pengaturan tampilan: tema terang/gelap dan warna utama (preset atau kustom).
- Struk toko: nama toko, catatan bawah, dan pratinjau struk sebelum disimpan.

### Legal dan bantuan

- Dokumen legal di aplikasi: Tentang, Kebijakan privasi, dan Lisensi (`assets/legal/`).
- Halaman Bantuan: kirim laporan lewat email atau WhatsApp.

### OCR dan Edit Struk

- Perbaikan pembacaan rekening GoPay dan SeaBank.
- Edit Struk: form Transfer / PLN Token / Lain, koreksi manual, termasuk total bayar (nominal + admin konter).

### Ikon, splash, dan status bar (build 5)

- Ikon launcher adaptif baru (foreground putih + background PNG) dan aset terkait di `assets/icon/`.
- Splash native diperbarui: latar terang/gelap, aset Android 12+, dan resource Android yang digenerate ulang.
- Perbaikan ikon status bar di mode terang (`SystemUiOverlayStyle` di tema AppBar dan overlay tema).

### Teknis

- Flutter 3.47.5 dan pembaruan paket (ML Kit, `package_info_plus`, `url_launcher`, pemilih warna, markdown).
- Nama aplikasi Android dibaca dari `brand.txt`.
- `.cursor/` dan `Docs/` hanya lokal (gitignore), tidak ikut rilis.
