# Design System — Konter Print Helper (Daru Cell)

SSOT desain UI untuk Flutter app **konter-print-helper** (`cetak_struk`), target **phone kasir**.
Pola warna dan komponen diadaptasi dari design system **sistem-sekolah** (web), lalu dikunci ulang untuk Material 3: satu ukuran per peran, kelipatan 4, sentuh minimum 48.

> Sumber pola: `/home/ndaruls/Projects/WEB/sistem-sekolah/Docs/design-system.md`  
> Primary brand app ini: **`#8F00BF`**.  
> Brand web sistem-sekolah adalah indigo `#6366F1` (hover `#4F46E5`). Jangan dipakai di app ini.

Mode yang dipakai aplikasi: **light**. Token dark di §6 hanya supaya nilai gelap tidak salah saat ditambah nanti.

---

## 1. Prinsip

1. **Konsisten** — warna, tipografi, radius, dan spasi dari token di bawah. Satu peran UI = satu nilai, bukan rentang.
2. **Phone kasir** — tombol besar, teks baca 16, sedikit langkah. Skala judul desktop web (30 / 36 / 48) tidak dipakai.
3. **Material 3** — `ThemeData` / `ColorScheme` / `TextTheme`. `ColorScheme.fromSeed` tidak menghasilkan slate; netral di-override (§2).
4. **Sentuh** — kontrol interaktif minimum **48**. Aksi primer alur kasir tinggi **56**, lebar penuh.
5. **Tanpa hover** — state interaktif: pressed, focus, disabled, loading. Jangan andalkan hover web.

---

## 2. Warna

### Primary (brand ungu Daru Cell)

| Token | Hex | Flutter |
|-------|-----|---------|
| primary-50 | `#F6EBFA` | `Color(0xFFF6EBFA)` |
| primary-100 | `#EDD6F5` | `Color(0xFFEDD6F5)` |
| primary-200 | `#E0B8ED` | `Color(0xFFE0B8ED)` |
| primary-300 | `#CD8CE2` | `Color(0xFFCD8CE2)` |
| primary-400 | `#B352D3` | `Color(0xFFB352D3)` |
| **primary-500** | **`#8F00BF`** | **`Color(0xFF8F00BF)`** |
| primary-600 | `#7E00A8` | `Color(0xFF7E00A8)` |
| primary-700 | `#67008A` | `Color(0xFF67008A)` |
| primary-800 | `#4F0069` | `Color(0xFF4F0069)` |
| primary-900 | `#3C0050` | `Color(0xFF3C0050)` |

**Seed theme (wajib), lalu override netral dan status:**

```dart
colorScheme: ColorScheme.fromSeed(
  seedColor: const Color(0xFF8F00BF),
  brightness: Brightness.light,
).copyWith(
  surface: Colors.white,
  onSurface: const Color(0xFF0F172A),       // slate-900
  onSurfaceVariant: const Color(0xFF475569), // slate-600
  outline: const Color(0xFFE2E8F0),          // slate-200
  error: const Color(0xFFEF4444),
  onError: Colors.white,
),
scaffoldBackgroundColor: const Color(0xFFF8FAFC), // slate-50
```

Pemakaian primary:
- Tombol utama / progress aktif → `colorScheme.primary` + teks `onPrimary` (putih). Kontras putih di `#8F00BF` ≈ **7.2:1**.
- Pressed → primary-600 / primary-700
- Chip / tile ikon lembut → primary-50, ikon primary-500
- Jangan taruh teks slate-400 / abu tipis di atas primary

### Status

Warna solid dari sistem-sekolah (bukan `Colors.green` / `Colors.red` / `Colors.orange`, bukan tint `opacity 0.12`).

| Peran | Background | Ikon / garis | Teks di atas background | Tombol isi |
|-------|------------|--------------|-------------------------|------------|
| Success | `#F0FDF4` | `#22C55E` | `#15803D` | Jangan. Putih di `#22C55E` ≈ 2.3:1 |
| Warning | `#FFFBEB` | `#F59E0B` | `#92400E` | Jangan. Putih di `#F59E0B` ≈ 2.2:1 |
| Danger | `#FEF2F2` | `#EF4444` | `#B91C1C` | Isi tombol **`#B91C1C`** + teks putih (≈ 6.5:1). Putih di `#EF4444` ≈ 3.8:1, gagal untuk label kecil |
| Info | `#EFF6FF` | `#3B82F6` | `#1E40AF` | Jangan diisi putih |

Border banner (opsional, 1px): success `#BBF7D0`, warning `#FDE68A`, danger `#FECACA`, info `#BFDBFE`.

Alur printer:
- Terhubung → success (kedua layar sama)
- Putus / gagal cetak → danger (bukan warning)
- Warning hanya untuk perhatian yang belum gagal (izin belum lengkap, dsb.)

### Netral (slate)

| Token | Hex | Flutter | Peran |
|-------|-----|---------|--------|
| slate-50 | `#F8FAFC` | `Color(0xFFF8FAFC)` | Scaffold |
| slate-100 | `#F1F5F9` | `Color(0xFFF1F5F9)` | Fill nonaktif, avatar kosong |
| slate-200 | `#E2E8F0` | `Color(0xFFE2E8F0)` | Border kartu, divider |
| slate-300 | `#CBD5E1` | `Color(0xFFCBD5E1)` | Border sekunder, ikon empty |
| slate-400 | `#94A3B8` | `Color(0xFF94A3B8)` | Placeholder saja (bukan teks isi) |
| slate-500 | `#64748B` | `Color(0xFF64748B)` | Caption, helper |
| slate-600 | `#475569` | `Color(0xFF475569)` | Body sekunder |
| slate-700 | `#334155` | `Color(0xFF334155)` | Label field |
| slate-800 | `#1E293B` | `Color(0xFF1E293B)` | Teks kuat |
| slate-900 | `#0F172A` | `Color(0xFF0F172A)` | Judul, nilai isi |

- Kartu / sheet → putih + border slate-200
- `Colors.grey` Material bukan token ini

---

## 3. Tipografi

Font: **bawaan platform** (Roboto di Android). Jangan menambah Inter kecuali diminta.

Override `TextTheme`. Default Material 3 tidak sama dengan tabel ini (`titleLarge` bawaan w400, `labelSmall` bawaan 11).

| Peran UI | `TextTheme` | Ukuran | Line height | Berat |
|----------|-------------|--------|-------------|-------|
| Judul layar (AppBar) | `titleLarge` | 22 | 28 | w600 |
| Judul section, kartu, empty, baris list | `titleMedium` | 16 | 24 | w600 |
| Isi utama (nilai field, instruksi) | `bodyLarge` | 16 | 24 | w400 |
| Sekunder (subtitle, helper) | `bodyMedium` | 14 | 20 | w400 |
| Caption | `bodySmall` | 12 | 16 | w400 |
| Label section huruf kapital | `labelMedium` | 12 | 16 | w600, `letterSpacing: 0.6` |
| Label tombol primer | `labelLarge` | 16 | 24 | w600 |
| Label tombol sekunder | `labelLarge` | 14 | 20 | w600 |
| Label field | `bodyMedium` | 14 | 20 | w500, warna slate-700 |

Warna:
- Judul → slate-900
- Isi utama → slate-900
- Body sekunder / helper → slate-600 atau slate-500
- Label section → slate-500

Dilarang di phone: **11, 13, 18, 20, 30, 36, 48**.  
18 tidak punya peran Material 3. 20 adalah subjudul web, bukan judul AppBar. Angka desktop web diturunkan lewat aturan mobile sistem-sekolah (judul turun satu langkah) lalu dikunci ke baris di atas.

---

## 4. Spacing, radius, ikon

Semua nilai kelipatan 4. Jangan 6, 10, 14, 54.

### Spacing

| Token | px | Pakai untuk |
|-------|----|-------------|
| space-1 | 4 | Rapat, offset label section |
| space-2 | 8 | Jarak ikon–teks, antar baris rapat |
| space-3 | 12 | Di dalam grup field |
| space-4 | 16 | Padding layar phone, padding kartu, padding banner, padding bar bawah |
| space-5 | 20 | Hindari sebagai default phone |
| space-6 | 24 | Jarak antar section, padding layar tablet |
| space-8 | 32 | Padding vertikal empty state |
| space-12 | 48 | Tinggi minimum kontrol |

### Radius

Angka web (4 / 8 / 12 / 16 / 24) **digeser satu langkah** di phone. Radius web 4px terlalu tajam; kartu adalah permukaan utama.

| Token | px | Web yang diganti | Pakai untuk |
|-------|----|------------------|-------------|
| radius-sm | 8 | web sm 4 / md 8 | Tile ikon kecil |
| radius-md | 12 | web lg 12 | Tombol, input, chip |
| radius-lg | 16 | web xl 16 | Kartu, banner inset, dialog |
| radius-xl | 24 | web 2xl 24 | Bottom sheet, hanya sudut atas |
| radius-full | pill | sama | Avatar, chip status |

Dilarang: **4, 6, 10, 14, 20**.

### Ikon

| Peran | px |
|-------|----|
| Sejajar teks | 20 |
| Leading list | 24 |
| Empty state | 48 |

### Elevasi

Kartu list: **flat + border** slate-200, elevation 0.  
Bayangan hanya bar aksi bawah (halus), bukan shadow besar pada kartu konten.

---

## 5. Komponen

### AppBar

- Tinggi **64**, judul `titleLarge` (22 / w600 / slate-900), rata tengah
- Background transparan atau surface, elevation 0
- `IconButton` area sentuh 48

### Tombol

| Peran | Widget | Tinggi | Radius | Label |
|-------|--------|--------|--------|-------|
| Primer (alur kasir) | `FilledButton` / `ElevatedButton` | **56** | 12 | 16 w600, primary + putih |
| Sekunder | `OutlinedButton` | **48** | 12 | 14 w600, border slate-300 |
| Teks | `TextButton` | min 48 | 12 | 14 w600 |
| Destruktif | `FilledButton` | 48 atau 56 | 12 | putih di atas `#B91C1C` |

- Aksi primer (lanjut cetak, cetak sekarang) = **bar bawah lebar penuh**, bukan FAB.
- Padding bar bawah 16 + `SafeArea`.
- Loading: `CircularProgressIndicator` primary, tombol disabled, tinggi tetap.
- Jangan tinggi 28 / 32 / 40 / 54.

### Kartu

- Putih, border 1px slate-200, radius **16**, padding **16**, elevation 0
- Judul `titleMedium`
- Isi `bodyLarge` atau `bodyMedium`

### Input

- Outline, radius **12**, tinggi minimum **48**, teks `bodyLarge` **16**
- Padding horizontal 16
- Border default slate-200, focus primary, error `#EF4444`
- Fill slate-50
- Label 14 w500 slate-700
- Helper `bodySmall` slate-500; pesan error `bodySmall` `#B91C1C`

### Banner status

- Padding vertikal 12, horizontal 16 (bukan 6)
- Inset: radius 16 + border semantic. Full-bleed: radius 0
- Ikon 20
- Background solid kolom “Background” §2, teks kolom “Teks”, ikon kolom “Ikon”
- Jika bisa diketuk: tinggi minimum 48
- Terhubung = success, putus = danger, di home dan pengaturan printer

### Baris list (perangkat)

- Tinggi minimum 48, disarankan 56
- Radius 16, border slate-200; terpilih: border primary
- Judul `titleMedium`, subtitle `bodyMedium` slate-500
- Leading ikon 24

### Empty state

- Ikon 48, warna slate-300, atau tile primary-50 + ikon primary + radius 8
- Judul `titleMedium`, deskripsi `bodyMedium` slate-500, rata tengah
- Bukan ikon 64, bukan indigo

### Dialog

- Radius 16, padding 24
- Aksi menumpuk lebar penuh di phone: primer di bawah, sekunder di atasnya
- Tutup lewat tombol, bukan pola hover

### SnackBar

- Material di **bawah**, pesan Indonesia pendek
- Bukan toast web pojok kanan atas

### Progress

- `CircularProgressIndicator` warna primary saat OCR atau cetak
- Teks di samping/bawah: `bodyMedium`

---

## 6. Light dan dark

**Light (dipakai sekarang)**

- Scaffold slate-50, kartu putih, judul slate-900, body slate-600
- Primary `#8F00BF`, teks tombol putih

**Dark (belum diimplementasi — token wajib jika ditambah)**

- Scaffold slate-900, surface slate-800
- Tombol primer tetap `#8F00BF` + teks putih
- Ikon atau teks primary di atas background gelap pakai **primary-300 `#CD8CE2`** (kontras ≈ 7.2:1). `#8F00BF` di atas slate-900 hanya ≈ **2.5:1**, tidak boleh jadi warna teks/ikon
- Border slate-700 `#334155`

---

## 7. Tidak dibawa dari web

Jangan menyalin ini ke Flutter:

- Grid 12 kolom, container max-width, breakpoint `lg` / `xl` / `2xl`
- Sidebar 256px, navbar web, drawer 280px
- Hover, `box-shadow` web, skala z-index CSS
- Tabel data, date picker web, searchable select
- Font Inter, ukuran 30 / 36 / 48, tombol 28 / 32, radius 4
- Toast fixed pojok kanan, max-width 400px

---

## 8. Anti-pola

- `Colors.indigo` atau seed selain `#8F00BF`
- `Colors.grey` / `Colors.green` / `Colors.red` / `Colors.orange` sebagai pengganti token
- Status dengan opacity ~0.12 di atas foto atau surface
- Hex di widget di luar `lib/theme/` atau `Theme.of(context)`
- Radius 4, 6, 10, 14, 20
- `fontSize` 11, 13, 18, 20, atau ukuran acak di luar §3
- Tinggi tombol 54 (bukan kelipatan 4; primer adalah 56)
- FAB sebagai satu-satunya CTA primer alur kasir
- Banner printer home (danger) dan pengaturan (warning) yang beda makna untuk state putus
- Teks atau ikon `#8F00BF` langsung di atas scaffold gelap

---

## 9. File terkait

| File | Peran |
|------|--------|
| `Docs/design-system.md` | SSOT ini |
| `lib/main.dart` | `ThemeData` — diselaraskan ke token saat implementasi UI |
| `lib/theme/` | `app_colors.dart`, `app_theme.dart` saat token dipusatkan |
| `.cursor/rules/design-system.mdc` | Ringkas aturan Cursor |

Saat menambah warna atau komponen: **update dokumen ini dulu**, lalu kode.
