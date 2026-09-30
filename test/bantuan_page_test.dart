import "package:cetak_struk/pages/bantuan_page.dart";
import "package:flutter/material.dart";
import "package:flutter_test/flutter_test.dart";

void main() {
  testWidgets("bantuan menampilkan email dan WhatsApp yang bisa diketuk", (
    tester,
  ) async {
    await tester.pumpWidget(const MaterialApp(home: BantuanPage()));

    expect(
      find.text("Laporkan bug, atau e-wallet yang belum dikenali."),
      findsOneWidget,
    );
    expect(find.textContaining("Lampirkan foto struk"), findsOneWidget);
    expect(find.textContaining("GoPay, OVO, atau SeaBank"), findsOneWidget);
    expect(find.text("Email dan WhatsApp belum diisi."), findsNothing);
    expect(find.text("Kirim email"), findsOneWidget);
    expect(find.text("Kirim Whatsapp"), findsOneWidget);
  });
}
