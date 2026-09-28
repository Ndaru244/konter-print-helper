# Informasi aplikasi — Daru Cell (Beta)

Draf untuk Google Play (jalur uji / beta). Belum diunggah. Isi bertanda **[isi saat publish]** wajib dilengkapi sebelum listing dikirim.

| Kolom | Nilai |
|-------|--------|
| Nama tampilan | Daru Cell |
| Nama di Play (maks. 30) | Daru Cell |
| Status rilis | Beta |
| Versi sekarang | `1.0.0` (versionCode `1`, dari `pubspec.yaml`) |
| Paket | `com.example.cetak_struk` — **harus diganti** sebelum publish |
| Kategori | Bisnis |
| Iklan | Tidak ada |
| Akun pengguna | Tidak ada |
| Bahasa listing | Indonesia |
| Di aplikasi | Beranda → ikon info → halaman Tentang |

---

## Deskripsi singkat

Maks. 80 karakter. Yang ini 64.

```
Cetak struk e-wallet ke printer Bluetooth. Versi beta Daru Cell.
```

## Deskripsi lengkap

```
Daru Cell membantu kasir konter mencetak ulang resi e-wallet ke printer thermal Bluetooth.

Ini versi beta. Alur utamanya sudah bisa dipakai, tetapi hasil baca struk masih perlu dicek sebelum dicetak.

Cara pakai
1. Pairing printer thermal di pengaturan Bluetooth HP.
2. Di Daru Cell, pilih printer lalu sambungkan.
3. Buka riwayat di DANA, GoPay, Seabank, atau e-wallet lain.
4. Bagikan gambar resi ke Daru Cell.
5. Cek teks yang terbaca, ubah bila perlu, lalu cetak.

Yang ada di versi beta
• Menerima gambar resi yang dibagikan ke aplikasi
• Membaca teks struk di perangkat, lalu menampilkannya agar bisa diedit
• Menyimpan nama toko di HP ini (bawaan: Daru Cell)
• Mencetak ke printer thermal yang sudah ter-pairing
• Tes cetak dari halaman pengaturan printer

Yang belum dijanjikan di beta
• Tidak semua format struk terbaca sempurna
• Tidak ada akun, cloud, atau riwayat transaksi di server
• Tidak ada penjualan, pembayaran, atau dompet digital di dalam aplikasi

Syarat
• Android dengan Bluetooth
• Printer thermal Bluetooth yang sudah di-pairing dari pengaturan HP
```

## Catatan rilis beta

```
Beta 1.0.0
• Terima resi dari bagikan gambar
• Baca teks struk dan izinkan perbaikan sebelum cetak
• Sambungkan printer Bluetooth dan tes cetak
• Nama toko bawaan Daru Cell
```

---

## Data yang disentuh aplikasi

Untuk formulir Keamanan data Play dan draf kebijakan privasi. Tidak ada server Daru Cell.

| Data | Dari mana | Disimpan | Dikirim ke server Daru Cell |
|------|-----------|----------|-----------------------------|
| Gambar resi yang dibagikan | Aplikasi e-wallet lewat bagikan | Sementara, untuk ditampilkan dan dibaca | Tidak |
| Teks hasil baca struk | Dibaca di perangkat dari gambar | Hanya di layar, sampai kasir menutup atau menghapus | Tidak |
| Nama toko | Diketik kasir | Di HP (`SharedPreferences`) | Tidak |
| Nama dan alamat printer Bluetooth yang dipilih | Perangkat yang sudah di-pairing | Di HP | Tidak |

Pengenalan teks memakai ML Kit di perangkat. Model pengenalan teks dapat disediakan Google Play Services. Daru Cell tidak punya akun dan tidak mengirim isi struk ke server sendiri.

Izin rilis: Bluetooth untuk printer yang sudah di-pairing, dan terima bagikan gambar. Izin internet di manifest debug/profile hanya untuk pengembangan, tidak untuk fitur kasir.

## Kontak listing

| Kolom | Nilai |
|-------|--------|
| Email developer | **[isi saat publish]** |
| Telepon | **[isi saat publish]** opsional |
| Situs / kebijakan privasi | **[URL publik wajib]** — Play memintanya karena aplikasi memproses gambar resi yang bisa berisi nama, nomor, dan nominal |

---

## Sebelum tombol publish

- [ ] Ganti `applicationId` `com.example.cetak_struk` (Play menolak ID contoh)
- [ ] Tanda tangan rilis dengan keystore sendiri (sekarang build rilis memakai kunci debug)
- [ ] Host kebijakan privasi di URL publik, lalu tempel ringkasan data di atas
- [ ] Ikon 512×512, graphic 1024×500, screenshot HP (beranda kosong, struk diterima, edit struk, pengaturan printer)
- [ ] Isi kuesioner rating konten: tanpa kekerasan, tanpa lokasi, tanpa akun, tanpa iklan
- [ ] Unggah ke jalur **Uji internal** atau **Uji tertutup** dulu, bukan produksi
