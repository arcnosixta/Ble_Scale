import 'package:flutter/material.dart';
import 'scan_page.dart';
import 'settings_screen.dart';

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _index = 0;

  // Список страниц лучше держать внутри build или использовать геттер,
  // чтобы страницы корректно обновлялись.
  List<Widget> get _pages => [
    const ScanPage(title: 'Scan Device'),
    const SettingsPage(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // IndexedStack сохраняет состояние страниц (они не перезагружаются при переключении)
      body: IndexedStack(
        index: _index,
        children: _pages,
      ),
      // Если вы используете CircularNotchedRectangle,
      // убедитесь, что у вас есть FloatingActionButton, иначе используйте обычный BottomAppBar
      bottomNavigationBar: BottomAppBar(
        shape: const CircularNotchedRectangle(),
        notchMargin: 8,
        child: Row( // Убрали лишний SizedBox с высотой, BottomAppBar сам подстроится
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            IconButton(
              icon: Icon(
                Icons.home,
                color: _index == 0 ? Colors.blue : Colors.grey,
              ),
              onPressed: () {
                setState(() {
                  _index = 0;
                });
              },
            ),
            // Этот SizedBox нужен, если между кнопками есть FloatingActionButton
            const SizedBox(width: 40),
            IconButton(
              icon: Icon(
                Icons.settings,
                color: _index == 1 ? Colors.blue : Colors.grey,
              ),
              onPressed: () {
                setState(() {
                  _index = 1;
                });
              },
            ),
          ],
        ),
      ),
      // Если вы хотели вырез (Notch), добавьте кнопку:
      // floatingActionButton: FloatingActionButton(onPressed: () {}),
      // floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
    );
  }
}