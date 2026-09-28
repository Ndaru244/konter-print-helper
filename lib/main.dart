import "package:flutter/material.dart";
import "package:provider/provider.dart";
import "package:cetak_struk/services/printer_service.dart";
import "package:cetak_struk/pages/homepage.dart";
import "package:cetak_struk/theme/app_theme.dart";

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => PrinterService()..init()),
      ],
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: "Daru Cell",
      theme: AppTheme.light(),
      home: const HomePage(),
    );
  }
}
