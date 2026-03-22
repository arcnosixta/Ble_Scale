import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:pp_bluetooth_kit_flutter/ble/pp_bluetooth_kit_manager.dart';
import 'package:pp_bluetooth_kit_flutter/utils/pp_bluetooth_kit_logger.dart';

import 'scan_page.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Monitor logs
  PPBluetoothKitLogger.addListener(callBack: (log) {
    print('SDK-Log:$log');
  });

  // init SDK
  final configPath = 'config/lefu.config';
  String content = await rootBundle.loadString(configPath);
  PPBluetoothKitManager.initSDK('lefu0eb0a285268f22c7', 'oA0pdd57IJxmFqgvh1iQt4XyDxyQy8XDkTRTbsYFo0I=', content);

  // set device setting
  final deviceSettingPath = 'config/Device.json';
  try {
    String jsonStr = await rootBundle.loadString(deviceSettingPath);
    PPBluetoothKitManager.setDeviceSetting(jsonStr);
    print("Device settings loaded successfully");
  } catch (e) {
    print("Error loading device settings: $e");
  }

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'BLE Scale App',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        useMaterial3: true,
      ),
      home: const ScanPage(title: 'Scan Device'),
    );
  }
}
