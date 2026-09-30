import "package:flutter/material.dart";
import "package:flutter/services.dart";
import "package:provider/provider.dart";
import "package:cetak_struk/brand.dart";
import "package:cetak_struk/pages/main_shell.dart";
import "package:cetak_struk/services/printer_service.dart";
import "package:cetak_struk/services/theme_settings.dart";
import "package:cetak_struk/theme/app_theme.dart";

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
  await Brand.load();
  final themeSettings = ThemeSettings();
  await themeSettings.load();

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider.value(value: themeSettings),
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
    final themeSettings = context.watch<ThemeSettings>();
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: Brand.name,
      theme: AppTheme.light(seed: themeSettings.seedColor),
      darkTheme: AppTheme.dark(seed: themeSettings.seedColor),
      themeMode: themeSettings.themeMode,
      home: const MainShell(),
    );
  }
}
