# Konter Print Helper

Aplikasi Android (Flutter) untuk konter: baca bukti transaksi e-wallet lewat **share/OCR**, isi form struk, lalu cetak ke **printer thermal Bluetooth**.

## Isi aplikasi

- **Home** — menunggu resi yang dibagikan dari e-wallet (DANA, GoPay, SeaBank, dll.)
- **Edit Struk** — OCR → form Transfer / PLN Token / Lain (bisa dikoreksi), termasuk **total bayar** (nominal + admin)
- **Pengaturan Printer** — sambung Bluetooth, test print
- **Cetak** — template padat untuk kertas thermal; token PLN satu baris ukuran besar

**Stack:** Flutter, Google ML Kit Text Recognition, `blue_thermal_printer`, Provider.

## Tampilan

| Home | Edit Struk | Printer | Hasil cetak |
|:---:|:---:|:---:|:---:|
| ![Home](screenshots/home-v110.jpg) | ![Edit Struk](screenshots/edit-struk-v110.jpg) | ![Printer](screenshots/setting-v110.jpg) | ![Hasil](screenshots/hasil-v110.jpg) |

## Cara menjalankan

Butuh Flutter SDK dan device/emulator Android (Bluetooth nyata lebih baik di device fisik).

```bash
git clone https://github.com/Ndaru244/konter-print-helper.git
cd konter-print-helper
flutter pub get
flutter run
```

Build APK release:

```bash
flutter build apk --release
```

Output: `build/app/outputs/flutter-apk/app-release.apk`

Atau unduh APK dari [Releases](https://github.com/Ndaru244/konter-print-helper/releases).

## Lisensi

MIT
