import "package:flutter/material.dart";
import "package:flutter/services.dart";
import "package:flutter_markdown_plus/flutter_markdown_plus.dart";
import "package:package_info_plus/package_info_plus.dart";
import "package:url_launcher/url_launcher.dart";
import "package:cetak_struk/brand.dart";
import "package:cetak_struk/widgets/app_snackbar.dart";
import "package:cetak_struk/widgets/app_version_text.dart";

class LegalDocumentPage extends StatelessWidget {
  const LegalDocumentPage({
    super.key,
    required this.title,
    required this.assetPath,
  });

  final String title;
  final String assetPath;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(title: Text(title)),
      body: FutureBuilder<String>(
        future: loadLegalDocument(assetPath),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Text(
                  "Dokumen tidak dapat dibuka.",
                  style: theme.textTheme.bodyLarge,
                  textAlign: TextAlign.center,
                ),
              ),
            );
          }
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }
          return Markdown(
            data: snapshot.data!,
            selectable: true,
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
            styleSheet: legalMarkdownStyle(theme),
            onTapLink: (text, href, title) => _openLink(context, href),
          );
        },
      ),
    );
  }

  Future<void> _openLink(BuildContext context, String? href) async {
    final uri = Uri.tryParse(href ?? "");
    if (uri == null || (uri.scheme != "https" && uri.scheme != "http")) {
      return;
    }
    final opened = await launchUrl(uri, mode: LaunchMode.externalApplication);
    if (opened || !context.mounted) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(appSnackBar(context, "Tautan tidak dapat dibuka."));
  }
}

/// Gaya yang ikut tema, termasuk kutipan, judul kecil, garis, dan kode.
MarkdownStyleSheet legalMarkdownStyle(ThemeData theme) {
  final scheme = theme.colorScheme;
  final body = theme.textTheme.bodyLarge?.copyWith(color: scheme.onSurface);
  final code = theme.textTheme.bodyMedium?.copyWith(
    fontFamily: "monospace",
    color: scheme.onSurface,
    backgroundColor: Colors.transparent,
  );
  return MarkdownStyleSheet.fromTheme(theme).copyWith(
    p: body,
    h1: theme.textTheme.titleLarge?.copyWith(color: scheme.onSurface),
    h1Padding: const EdgeInsets.only(bottom: 8),
    h2: theme.textTheme.titleMedium?.copyWith(color: scheme.onSurface),
    h2Padding: const EdgeInsets.only(top: 8, bottom: 8),
    h3: body?.copyWith(fontWeight: FontWeight.w600),
    h3Padding: const EdgeInsets.only(top: 8, bottom: 4),
    strong: const TextStyle(fontWeight: FontWeight.w600),
    a: TextStyle(
      color: scheme.primary,
      decoration: TextDecoration.underline,
      decorationColor: scheme.primary,
    ),
    listBullet: body,
    blockquote: body,
    blockquotePadding: const EdgeInsets.all(12),
    blockquoteDecoration: BoxDecoration(
      color: scheme.surface,
      borderRadius: BorderRadius.circular(8),
      border: Border(left: BorderSide(color: scheme.primary, width: 4)),
    ),
    code: code,
    codeblockPadding: const EdgeInsets.all(12),
    codeblockDecoration: BoxDecoration(
      color: theme.scaffoldBackgroundColor,
      borderRadius: BorderRadius.circular(8),
      border: Border.all(color: scheme.outline),
    ),
    horizontalRuleDecoration: BoxDecoration(
      border: Border(top: BorderSide(color: scheme.outline)),
    ),
  );
}

/// Mengganti `{{brand}}` dan, bila ada, `{{version}}`.
Future<String> loadLegalDocument(String assetPath) async {
  var text = (await rootBundle.loadString(
    assetPath,
  )).replaceAll("{{brand}}", Brand.name);
  if (!text.contains("{{version}}")) return text;
  try {
    final info = await PackageInfo.fromPlatform();
    return text.replaceAll("{{version}}", formatAppVersion(info));
  } catch (_) {
    return text.replaceAll("{{version}}", "versi …");
  }
}
