import "package:cetak_struk/brand.dart";
import "package:cetak_struk/pages/legal_document_page.dart";
import "package:flutter/material.dart";
import "package:flutter_test/flutter_test.dart";
import "package:package_info_plus/package_info_plus.dart";

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() async {
    await Brand.load();
    PackageInfo.setMockInitialValues(
      appName: "Daru Cell",
      packageName: "cetak_struk",
      version: "0.1.0",
      buildNumber: "3",
      buildSignature: "",
    );
  });

  testWidgets("tentang dibaca dari markdown beserta versi", (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: LegalDocumentPage(
          title: "Tentang",
          assetPath: "assets/legal/tentang.md",
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text("Tentang"), findsWidgets);
    expect(find.textContaining("versi 0.1.0 (3)"), findsOneWidget);
    expect(find.textContaining("Cara Kerja"), findsOneWidget);
    await tester.drag(find.byType(ListView), const Offset(0, -2400));
    await tester.pumpAndSettle();
    expect(find.textContaining("Kode Sumber"), findsOneWidget);
    expect(find.textContaining(Brand.name), findsWidgets);
  });

  testWidgets("lisensi menampilkan teks lisensi utuh", (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: LegalDocumentPage(
          title: "Lisensi",
          assetPath: "assets/legal/license.md",
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.drag(find.byType(ListView), const Offset(0, -800));
    await tester.pumpAndSettle();
    expect(
      find.textContaining("Permission is hereby granted", findRichText: true),
      findsOneWidget,
    );
  });
}
