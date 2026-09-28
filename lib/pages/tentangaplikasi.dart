import "package:flutter/material.dart";
import "package:cetak_struk/widgets/app_card.dart";
import "package:cetak_struk/widgets/app_section_label.dart";
import "package:cetak_struk/widgets/app_status_banner.dart";

class TentangAplikasiPage extends StatelessWidget {
  const TentangAplikasiPage({super.key});

  static const versionLabel = "1.0.0";

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(title: const Text("Tentang")),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
        children: [
          const AppStatusBanner(
            inset: true,
            tone: AppStatusTone.info,
            icon: Icons.info_outline,
            message: "Versi beta $versionLabel",
            subtitle: "Cek teks struk sebelum dicetak.",
          ),
          const SizedBox(height: 16),
          AppCard(
            child: Text(
              "Daru Cell membantu kasir mencetak ulang resi e-wallet ke printer thermal Bluetooth.",
              style: theme.textTheme.bodyLarge,
            ),
          ),
          const SizedBox(height: 24),
          const AppSectionLabel(label: "Cara pakai"),
          const SizedBox(height: 12),
          const AppCard(
            child: _StepList(
              steps: [
                "Pairing printer thermal di pengaturan Bluetooth HP.",
                "Di Daru Cell, pilih printer lalu sambungkan.",
                "Buka riwayat di DANA, GoPay, Seabank, atau e-wallet lain.",
                "Bagikan gambar resi ke Daru Cell.",
                "Cek teks yang terbaca, ubah bila perlu, lalu cetak.",
              ],
            ),
          ),
          const SizedBox(height: 24),
          const AppSectionLabel(label: "Yang ada di beta"),
          const SizedBox(height: 12),
          const AppCard(
            child: _BulletList(
              items: [
                "Menerima gambar resi yang dibagikan ke aplikasi.",
                "Membaca teks struk di perangkat, lalu bisa diedit.",
                "Menyimpan nama toko di HP ini. Bawaan: Daru Cell.",
                "Mencetak ke printer thermal yang sudah ter-pairing.",
                "Tes cetak dari halaman pengaturan printer.",
              ],
            ),
          ),
          const SizedBox(height: 24),
          const AppSectionLabel(label: "Data di HP ini"),
          const SizedBox(height: 12),
          AppCard(
            child: Text(
              "Gambar resi dan teks struk diproses di perangkat. Nama toko dan printer yang dipilih disimpan di HP ini. Aplikasi tidak mengirim isi struk ke server Daru Cell.",
              style: theme.textTheme.bodyLarge,
            ),
          ),
        ],
      ),
    );
  }
}

class _StepList extends StatelessWidget {
  const _StepList({required this.steps});

  final List<String> steps;

  @override
  Widget build(BuildContext context) {
    final style = Theme.of(context).textTheme.bodyLarge;
    return Column(
      children: [
        for (var i = 0; i < steps.length; i++) ...[
          if (i > 0) const SizedBox(height: 12),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(
                width: 24,
                child: Text("${i + 1}.", style: style),
              ),
              Expanded(child: Text(steps[i], style: style)),
            ],
          ),
        ],
      ],
    );
  }
}

class _BulletList extends StatelessWidget {
  const _BulletList({required this.items});

  final List<String> items;

  @override
  Widget build(BuildContext context) {
    final style = Theme.of(context).textTheme.bodyLarge;
    return Column(
      children: [
        for (var i = 0; i < items.length; i++) ...[
          if (i > 0) const SizedBox(height: 12),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text("•", style: style),
              const SizedBox(width: 8),
              Expanded(child: Text(items[i], style: style)),
            ],
          ),
        ],
      ],
    );
  }
}
