---
name: flutter
description: >-
  Flutter/Dart workflow for Konter Print Helper (cetak_struk / Daru Cell):
  ThemeData, Material 3 UI, Provider, OCR (ML Kit), Bluetooth thermal print,
  Android permissions, and design-system tokens. Use when editing lib/**,
  pubspec.yaml, Android/iOS manifests, or app theme/splash/icons.
---

# Flutter — Konter Print Helper

## Source of truth

1. Design spec: [`Docs/design-system.md`](../../../Docs/design-system.md)
2. Cursor rules: [`.cursor/rules/design-system.mdc`](../../rules/design-system.mdc), [`.cursor/rules/Rules.mdc`](../../rules/Rules.mdc)
3. Entry / theme: [`lib/main.dart`](../../../lib/main.dart)
4. Screens: `lib/pages/` (`homepage.dart`, `cetakstruk.dart`, `settingprinter.dart`)
5. Services: `lib/services/` (`printer_service.dart`, `receipt_scanner.dart`)

Read the design doc and the file you will change before inventing UI or new packages.

## Hard rules (theme & tokens)

- Primary seed: `const Color(0xFF8F00BF)` (`#8F00BF`) — **not** `Colors.indigo`, not sistem-sekolah indigo.
- Prefer `Theme.of(context).colorScheme` / `textTheme` over raw hex in widgets.
- Status icons/borders: success `#22C55E`, warning `#F59E0B`, danger `#EF4444`, info `#3B82F6`. Banner backgrounds are the solid tints in `Docs/design-system.md`. Destructive filled buttons use `#B91C1C` + white.
- Neutrals: slate scale in design doc (not random `Colors.grey`). Override scaffold/surface; `fromSeed` does not emit slate.
- Radius: 8 / 12 / 16 / 24 (sm/md/lg/xl). Cards 16, buttons and inputs 12. No 4, 6, 10, 14, 20.
- Touch targets: controls ≥ **48** logical px. Primary kasir actions height **56**, full-width. Reading text 16 (`bodyLarge`). AppBar title 22 w600.
- Splash / launcher background in `pubspec.yaml` uses `#511d66` (brand-adjacent). Keep brand purple family; do not switch to indigo/blue without updating Docs + splash together.

```dart
ThemeData(
  useMaterial3: true,
  colorScheme: ColorScheme.fromSeed(
    seedColor: const Color(0xFF8F00BF),
    brightness: Brightness.light,
  ),
)
```

When adding shared colors, prefer `lib/theme/app_colors.dart` (create if missing) and update `Docs/design-system.md` first.

## Architecture

| Layer | Location | Notes |
|-------|----------|--------|
| UI screens | `lib/pages/` | Keep widgets focused; no Bluetooth/OCR logic buried in build methods when a service exists |
| Services | `lib/services/` | `PrinterService` (Provider + ChangeNotifier), `receipt_scanner` (ML Kit) |
| DI / state | `provider` | Register in `main.dart` via `MultiProvider`; do not add Riverpod/Bloc unless asked |

- Package name: `cetak_struk` (import paths use this).
- App title: **Daru Cell**.
- Printer package: `blue_thermal_printer` via **git override** in `pubspec.yaml` — do not replace with a random pub.dev fork without an explicit ask.

## Feature map

| Need | Where to look / extend |
|------|-------------------------|
| Home / navigation | `lib/pages/homepage.dart` |
| Scan + parse receipt (OCR) | `lib/services/receipt_scanner.dart`, `lib/pages/cetakstruk.dart` |
| Print / Bluetooth connect | `lib/services/printer_service.dart`, `lib/pages/settingprinter.dart` |
| Theme | `lib/main.dart` (+ optional `lib/theme/`) |

## UI conventions

- Primary CTA: `ElevatedButton` / `FilledButton`, height 56, full-width on kasir flows (bottom bar, not a lone FAB).
- Secondary: `OutlinedButton` / `TextButton`, min height 48.
- Destructive: filled `#B91C1C` with white text. Use `colorScheme.error` (`#EF4444`) for borders and icons.
- Cards: theme `CardThemeData` radius 16; flat + border OK for dense lists.
- Loading: `CircularProgressIndicator` with primary; disable double-submit while printing/scanning.
- Errors for kasir: short Indonesian messages (permission denied, printer disconnect, OCR gagal) — no stack traces in UI.

## Packages & platform

```bash
flutter pub get
flutter analyze
flutter test
flutter run
```

- Add deps with `flutter pub add …` when possible; keep git override for `blue_thermal_printer` intact.
- New capability (camera, Bluetooth, storage): update Dart permission flow **and** `android/app/src/main/AndroidManifest.xml` (and iOS `Info.plist` if iOS is enabled later). iOS is currently off for splash/icons (`ios: false`).
- Never commit keystore passwords, API keys, or secret `.env` values.

## Design-system change workflow

1. Update `Docs/design-system.md` (tokens / components).
2. Apply in `ThemeData` or `lib/theme/`.
3. Use theme in pages — no one-off hex unless temporary and flagged.

## Checklist before finishing

- [ ] Read `Docs/design-system.md` for any UI/color change
- [ ] Seed / primary still `#8F00BF` (no indigo regression)
- [ ] Logic in `services/`; UI in `pages/`
- [ ] Provider pattern preserved (no second state library)
- [ ] `blue_thermal_printer` git override untouched unless asked
- [ ] Manifest/permissions updated if new hardware/API access
- [ ] `flutter analyze` clean for files you touched (or report failures plainly)
- [ ] No secrets committed; no unsolicited `git push`
