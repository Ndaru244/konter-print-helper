import "package:flutter/material.dart";
import "package:cetak_struk/pages/homepage.dart";
import "package:cetak_struk/pages/settingprinter.dart";
import "package:cetak_struk/pages/settings_page.dart";

class MainShell extends StatefulWidget {
  const MainShell({super.key});

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  int _index = 0;

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: _index == 0,
      onPopInvokedWithResult: (didPop, _) {
        if (didPop) return;
        setState(() => _index = 0);
      },
      child: Scaffold(
        body: IndexedStack(
          index: _index,
          children: [
            HomePage(
              tabActive: _index == 0,
              onOpenPrinter: () => setState(() => _index = 1),
            ),
            const PrinterSettingPage(),
            const SettingsPage(),
          ],
        ),
        bottomNavigationBar: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Divider(
              height: 1,
              thickness: 1,
              color: Theme.of(context).colorScheme.outline,
            ),
            NavigationBar(
              selectedIndex: _index,
              onDestinationSelected: (index) => setState(() => _index = index),
              destinations: const [
                NavigationDestination(
                  icon: Icon(Icons.home_outlined),
                  selectedIcon: Icon(Icons.home),
                  label: "Beranda",
                ),
                NavigationDestination(
                  icon: Icon(Icons.print_outlined),
                  selectedIcon: Icon(Icons.print),
                  label: "Printer",
                ),
                NavigationDestination(
                  icon: Icon(Icons.settings_outlined),
                  selectedIcon: Icon(Icons.settings),
                  label: "Pengaturan",
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
