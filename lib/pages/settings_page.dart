import "package:flex_color_picker/flex_color_picker.dart";
import "package:flutter/material.dart";
import "package:provider/provider.dart";
import "package:cetak_struk/pages/bantuan_page.dart";
import "package:cetak_struk/pages/legal_document_page.dart";
import "package:cetak_struk/pages/settings_struk_page.dart";
import "package:cetak_struk/services/theme_settings.dart";
import "package:cetak_struk/theme/app_colors.dart";
import "package:cetak_struk/widgets/app_card.dart";
import "package:cetak_struk/widgets/app_icon_tile.dart";
import "package:cetak_struk/widgets/app_list_tile.dart";
import "package:cetak_struk/widgets/app_section_label.dart";
import "package:cetak_struk/widgets/app_version_text.dart";

class SettingsPage extends StatelessWidget {
  const SettingsPage({super.key});

  void _openDoc(BuildContext context, String title, String asset) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => LegalDocumentPage(title: title, assetPath: asset),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Pengaturan")),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
        children: [
          const Padding(
            padding: EdgeInsets.only(bottom: 12),
            child: AppSectionLabel(label: "Tampilan"),
          ),
          const _ThemeChoice(),
          const SizedBox(height: 24),
          const Padding(
            padding: EdgeInsets.only(bottom: 12),
            child: AppSectionLabel(label: "Struk"),
          ),
          AppListTile(
            leading: const AppIconTile(icon: Icons.receipt_long_outlined),
            title: "Struk toko",
            subtitle: "Ubah nama toko dan catatan, lihat pratinjau",
            trailing: const Icon(Icons.chevron_right),
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const SettingsStrukPage()),
            ),
          ),
          const SizedBox(height: 24),
          const Padding(
            padding: EdgeInsets.only(bottom: 12),
            child: AppSectionLabel(label: "Tentang & legal"),
          ),
          AppListTile(
            leading: const AppIconTile(icon: Icons.info_outline),
            title: "Tentang",
            subtitle: "Nama aplikasi, versi, dan cara pakai",
            trailing: const Icon(Icons.chevron_right),
            onTap: () =>
                _openDoc(context, "Tentang", "assets/legal/tentang.md"),
          ),
          AppListTile(
            leading: const AppIconTile(icon: Icons.help_outline),
            title: "Bantuan",
            subtitle: "Lapor bug atau e-wallet yang belum didukung",
            trailing: const Icon(Icons.chevron_right),
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const BantuanPage()),
            ),
          ),
          AppListTile(
            leading: const AppIconTile(icon: Icons.privacy_tip_outlined),
            title: "Kebijakan privasi",
            subtitle: "Privasi transaksi Anda tetap di perangkat",
            trailing: const Icon(Icons.chevron_right),
            onTap: () => _openDoc(
              context,
              "Kebijakan privasi",
              "assets/legal/privacy_policy.md",
            ),
          ),
          AppListTile(
            leading: const AppIconTile(icon: Icons.gavel_outlined),
            title: "Lisensi",
            subtitle: "Teks lisensi MIT di aplikasi",
            trailing: const Icon(Icons.chevron_right),
            onTap: () =>
                _openDoc(context, "Lisensi", "assets/legal/license.md"),
          ),
          const SizedBox(height: 24),
          AppVersionText(style: Theme.of(context).textTheme.bodyMedium),
        ],
      ),
    );
  }
}

class _ThemeChoice extends StatelessWidget {
  const _ThemeChoice();

  @override
  Widget build(BuildContext context) {
    final settings = context.watch<ThemeSettings>();
    final theme = Theme.of(context);
    final caption = switch (settings.choice) {
      AppThemeChoice.system => "Mengikuti pengaturan HP.",
      AppThemeChoice.light => "Selalu tampilan terang.",
      AppThemeChoice.dark => "Selalu tampilan gelap.",
    };
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text("Tema aplikasi", style: theme.textTheme.titleMedium),
          const SizedBox(height: 12),
          Row(
            children: [
              for (final option in _options) ...[
                if (option != _options.first) const SizedBox(width: 8),
                Expanded(
                  child: _ThemeOption(
                    choice: option.choice,
                    label: option.label,
                    selected: settings.choice == option.choice,
                    onTap: () => settings.setChoice(option.choice),
                  ),
                ),
              ],
            ],
          ),
          const SizedBox(height: 12),
          Text(caption, style: theme.textTheme.bodyMedium),
          const SizedBox(height: 16),
          Text("Warna utama", style: theme.textTheme.titleMedium),
          const SizedBox(height: 8),
          Text(
            "Tombol dan aksen mengikuti warna ini.",
            style: theme.textTheme.bodyMedium,
          ),
          const SizedBox(height: 12),
          const _PrimaryChoice(),
        ],
      ),
    );
  }
}

class _ThemeOptionData {
  const _ThemeOptionData(this.choice, this.label);
  final AppThemeChoice choice;
  final String label;
}

const _options = [
  _ThemeOptionData(AppThemeChoice.system, "Sistem"),
  _ThemeOptionData(AppThemeChoice.light, "Terang"),
  _ThemeOptionData(AppThemeChoice.dark, "Gelap"),
];

class _ThemeOption extends StatelessWidget {
  const _ThemeOption({
    required this.choice,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final AppThemeChoice choice;
  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final fill = selected
        ? theme.colorScheme.primaryContainer
        : theme.colorScheme.surface;
    return Semantics(
      button: true,
      selected: selected,
      label: label,
      child: Material(
        color: fill,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(
            color: selected
                ? theme.colorScheme.primary
                : theme.colorScheme.outline,
            width: 2,
          ),
        ),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: ConstrainedBox(
            constraints: const BoxConstraints(minHeight: 48),
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                children: [
                  _ThemeSwatch(choice: choice),
                  const SizedBox(height: 8),
                  Text(
                    label,
                    textAlign: TextAlign.center,
                    style: selected
                        ? theme.textTheme.titleMedium?.copyWith(
                            color: theme.colorScheme.primary,
                          )
                        : theme.textTheme.bodyLarge,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _ThemeSwatch extends StatelessWidget {
  const _ThemeSwatch({required this.choice});

  final AppThemeChoice choice;

  @override
  Widget build(BuildContext context) {
    final child = switch (choice) {
      AppThemeChoice.light => const _MiniScreen(dark: false),
      AppThemeChoice.dark => const _MiniScreen(dark: true),
      AppThemeChoice.system => const Row(
        children: [
          Expanded(child: _MiniScreen(dark: false)),
          Expanded(child: _MiniScreen(dark: true)),
        ],
      ),
    };
    return ClipRRect(
      borderRadius: BorderRadius.circular(8),
      child: SizedBox(height: 48, width: double.infinity, child: child),
    );
  }
}

class _MiniScreen extends StatelessWidget {
  const _MiniScreen({required this.dark});

  final bool dark;

  @override
  Widget build(BuildContext context) {
    final background = dark ? AppColors.slate900 : AppColors.slate50;
    final card = dark ? AppColors.slate800 : Colors.white;
    final accent = Theme.of(context).colorScheme.primary;
    return ColoredBox(
      color: background,
      child: Padding(
        padding: const EdgeInsets.all(8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              height: 4,
              width: 24,
              decoration: BoxDecoration(
                color: accent,
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            const SizedBox(height: 8),
            Expanded(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  color: card,
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PrimaryChoice extends StatelessWidget {
  const _PrimaryChoice();

  @override
  Widget build(BuildContext context) {
    final settings = context.watch<ThemeSettings>();
    const presets = AppPrimaryPreset.values;
    return LayoutBuilder(
      builder: (context, constraints) {
        const gap = 8.0;
        final width = (constraints.maxWidth - gap) / 2;
        return Wrap(
          spacing: gap,
          runSpacing: gap,
          children: [
            for (final preset in presets)
              SizedBox(
                width: width,
                child: _PrimaryOption(
                  label: switch (preset) {
                    AppPrimaryPreset.biru => "Biru",
                    AppPrimaryPreset.ungu => "Ungu",
                    AppPrimaryPreset.hijau => "Hijau",
                    AppPrimaryPreset.custom => "Kustom",
                  },
                  color: switch (preset) {
                    AppPrimaryPreset.biru => ThemeSettings.biru,
                    AppPrimaryPreset.ungu => ThemeSettings.ungu,
                    AppPrimaryPreset.hijau => ThemeSettings.hijau,
                    AppPrimaryPreset.custom => settings.customPrimary,
                  },
                  selected: settings.primaryPreset == preset,
                  onTap: () {
                    if (preset == AppPrimaryPreset.custom) {
                      _openCustomColor(context, settings);
                    } else {
                      settings.setPrimaryPreset(preset);
                    }
                  },
                ),
              ),
          ],
        );
      },
    );
  }
}

Future<void> _openCustomColor(
  BuildContext context,
  ThemeSettings settings,
) async {
  var picked = settings.customPrimary;
  final accepted = await showDialog<bool>(
    context: context,
    builder: (context) {
      return StatefulBuilder(
        builder: (context, setLocal) {
          return AlertDialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            title: const Text("Warna kustom"),
            content: SizedBox(
              width: 280,
              child: ColorPicker(
                color: picked,
                onColorChanged: (color) {
                  picked = color;
                  setLocal(() {});
                },
                pickersEnabled: const {
                  ColorPickerType.both: false,
                  ColorPickerType.primary: false,
                  ColorPickerType.accent: false,
                  ColorPickerType.bw: false,
                  ColorPickerType.custom: false,
                  ColorPickerType.wheel: true,
                },
                enableOpacity: false,
                showColorCode: true,
                showColorName: false,
                showMaterialName: false,
                colorCodeHasColor: false,
                wheelDiameter: 200,
              ),
            ),
            actionsPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            actionsOverflowDirection: VerticalDirection.down,
            actionsOverflowButtonSpacing: 8,
            actions: [
              SizedBox(
                width: double.infinity,
                child: OutlinedButton(
                  onPressed: () => Navigator.pop(context, false),
                  child: const Text("Batal"),
                ),
              ),
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: () => Navigator.pop(context, true),
                  child: const Text("Pakai"),
                ),
              ),
            ],
          );
        },
      );
    },
  );
  if (accepted == true && context.mounted) {
    await settings.setCustomPrimary(picked);
  }
}

class _PrimaryOption extends StatelessWidget {
  const _PrimaryOption({
    required this.label,
    required this.color,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final Color color;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Semantics(
      button: true,
      selected: selected,
      label: label,
      child: Material(
        color: selected
            ? theme.colorScheme.primaryContainer
            : theme.colorScheme.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(
            color: selected
                ? theme.colorScheme.primary
                : theme.colorScheme.outline,
            width: 2,
          ),
        ),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: ConstrainedBox(
            constraints: const BoxConstraints(minHeight: 48),
            child: Padding(
              padding: const EdgeInsets.all(8),
              child: Column(
                children: [
                  Container(
                    width: 24,
                    height: 24,
                    decoration: BoxDecoration(
                      color: color,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: theme.colorScheme.outline),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: selected
                        ? theme.textTheme.titleMedium?.copyWith(
                            color: theme.colorScheme.primary,
                            fontSize: 14,
                            height: 20 / 14,
                          )
                        : theme.textTheme.bodyMedium,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
