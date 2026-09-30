import "package:flutter/material.dart";
import "package:url_launcher/url_launcher.dart";
import "package:cetak_struk/widgets/app_button.dart";
import "package:cetak_struk/widgets/app_card.dart";
import "package:cetak_struk/widgets/app_section_label.dart";
import "package:cetak_struk/widgets/app_snackbar.dart";

/// Alamat email laporan. Ganti dengan alamat yang asli.
const String bantuanEmail = "laporan@contoh.com";

/// Nomor WhatsApp internasional, tanpa tanda +. Ganti dengan nomor yang asli.
const String bantuanWhatsApp = "6280000000000";

const _laporanSubject = "Laporan struk";
const _laporanBody =
    "Aplikasi e-wallet: \n\n"
    "Lampirkan foto struk. Contoh aplikasi: GoPay, OVO, atau SeaBank.";

class BantuanPage extends StatelessWidget {
  const BantuanPage({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final email = bantuanEmail.trim();
    final whatsApp = bantuanWhatsApp.trim();
    final adaKontak = email.isNotEmpty || whatsApp.isNotEmpty;
    return Scaffold(
      appBar: AppBar(title: const Text("Bantuan")),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
        children: [
          AppCard(
            child: Text(
              "Laporkan bug, atau e-wallet yang belum dikenali.",
              style: theme.textTheme.bodyLarge,
            ),
          ),
          const SizedBox(height: 24),
          const AppSectionLabel(label: "Yang perlu dikirim"),
          const SizedBox(height: 12),
          AppCard(
            child: Text(
              "Lampirkan foto struk. Sebutkan aplikasinya, misalnya GoPay, OVO, atau SeaBank.",
              style: theme.textTheme.bodyLarge,
            ),
          ),
          const SizedBox(height: 24),
          const AppSectionLabel(label: "Kontak"),
          const SizedBox(height: 12),
          if (!adaKontak)
            AppCard(
              child: Text(
                "Email dan WhatsApp belum diisi.",
                style: theme.textTheme.bodyLarge,
              ),
            )
          else ...[
            if (email.isNotEmpty)
              AppButton.secondary(
                icon: Icons.email_outlined,
                label: "Kirim email",
                onPressed: () => _kirimEmail(context, email),
              ),
            if (email.isNotEmpty && whatsApp.isNotEmpty)
              const SizedBox(height: 12),
            if (whatsApp.isNotEmpty)
              AppButton.secondary(
                icon: Icons.chat_outlined,
                label: "Kirim Whatsapp",
                onPressed: () => _bukaWhatsApp(context, whatsApp),
              ),
          ],
        ],
      ),
    );
  }

  Future<void> _kirimEmail(BuildContext context, String email) async {
    final uri = Uri(
      scheme: "mailto",
      path: email,
      queryParameters: {"subject": _laporanSubject, "body": _laporanBody},
    );
    await _buka(context, uri, "Aplikasi email tidak ditemukan.");
  }

  Future<void> _bukaWhatsApp(BuildContext context, String nomor) async {
    final digits = nomor.replaceAll(RegExp(r"\D"), "");
    final uri = Uri.https("wa.me", "/$digits", {"text": _laporanBody});
    await _buka(context, uri, "WhatsApp tidak ditemukan.");
  }

  Future<void> _buka(BuildContext context, Uri uri, String gagal) async {
    final opened = await launchUrl(uri, mode: LaunchMode.externalApplication);
    if (opened || !context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(appSnackBar(context, gagal));
  }
}
