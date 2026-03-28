import 'package:flutter/material.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  bool isDarkMode = false;
  bool notificationsEnabled = true;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Настройки")),
      body: ListView(
        children: [
          SwitchListTile(
            title: const Text("Тёмная тема"),
            subtitle: const Text("Включить тёмный режим"),
            value: isDarkMode,
            onChanged: (value) {
              setState(() {
                isDarkMode = value;
              });
            },
            secondary: const Icon(Icons.dark_mode),
          ),
          SwitchListTile(
            title: const Text("Уведомления"),
            subtitle: const Text("Разрешить уведомления"),
            value: notificationsEnabled,
            onChanged: (value) {
              setState(() {
                notificationsEnabled = value;
              });
            },
            secondary: const Icon(Icons.notifications),
          ),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.info),
            title: const Text("О приложении"),
            subtitle: const Text("Версия 1.0"),
            onTap: () {
              showAboutDialog(
                context: context,
                applicationName: "BLE Scale App",
                applicationVersion: "1.0",
                children: const [
                  Text("Приложение для работы с умными весами."),
                ],
              );
            },
          ),
        ],
      ),
    );
  }
}