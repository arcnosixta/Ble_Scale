import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:ble_scale_app/Device/device_apple.dart';
import 'package:ble_scale_app/Device/device_banana.dart';
import 'package:ble_scale_app/Device/device_borre.dart';
import 'package:ble_scale_app/Device/device_coconut.dart';
import 'package:ble_scale_app/Device/device_egg.dart';
import 'package:ble_scale_app/Device/device_fish.dart';
import 'package:ble_scale_app/Device/device_grapes.dart';
import 'package:ble_scale_app/Device/device_hamburger.dart';
import 'package:ble_scale_app/Device/device_ice.dart';
import 'package:ble_scale_app/Device/device_jambul.dart';
import 'package:ble_scale_app/Device/device_torre.dart';
import 'package:pp_bluetooth_kit_flutter/ble/pp_bluetooth_kit_manager.dart';
import 'package:pp_bluetooth_kit_flutter/enums/pp_scale_enums.dart';
import 'package:pp_bluetooth_kit_flutter/model/pp_device_model.dart';
import 'package:permission_handler/permission_handler.dart';

import 'ui/theme.dart';
import 'ui/widgets/device_card.dart';
import 'ui/widgets/glow_button.dart';


class ScanPage extends StatefulWidget {
  const ScanPage({super.key, required this.title});

  final String title;

  @override
  State<ScanPage> createState() => _ScanPageState();
}

class _ScanPageState extends State<ScanPage> {
  bool _isScanning = false;
  final List<PPDeviceModel> _scanResults = [];

  @override
  void initState() {
    super.initState();

    //Monitor Bluetooth permission changes
    PPBluetoothKitManager.addBlePermissionListener(callBack: (permission) {
      print('Bluetooth permission state changed:$permission');
    });

    // Monitor scan status
    PPBluetoothKitManager.addScanStateListener(callBack: (scanning) {
      if (mounted) {
        setState(() {
          _isScanning = scanning;
        });
      }
    });
  }

  Future<void> _requestPermissions() async {
    Map<Permission, PermissionStatus> statuses = await [
      Permission.bluetoothScan,
      Permission.bluetoothConnect,
      Permission.location,
    ].request();

    if (statuses[Permission.bluetoothScan] != PermissionStatus.granted ||
        statuses[Permission.bluetoothConnect] != PermissionStatus.granted) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Bluetooth permissions are required for scanning")),
        );
      }
    }
  }

  Future<void> _onScanPressed() async {
    await _requestPermissions();

    setState(() {
      _scanResults.clear();
    });

    PPBluetoothKitManager.startScan((device) {
      print('Scan result:${device.toJson()}');

      if (mounted) {
        setState(() {
          // Check if device already exists in the list by MAC address
          final index = _scanResults.indexWhere((element) => element.deviceMac == device.deviceMac);
          if (index == -1) {
            _scanResults.add(device);
          } else {
            // Update existing device (optional, e.g., for RSSI updates)
            _scanResults[index] = device;
          }
        });
      }
    });
  }

  Future<void> _onStopPressed() async {
    PPBluetoothKitManager.stopScan();
  }

  Widget _buildScanButton(BuildContext context) {
    if (_isScanning) {
      return FloatingActionButton(
        onPressed: _onStopPressed,
        backgroundColor: Colors.red,
        child: const Icon(Icons.stop),
      );
    } else {
      return FloatingActionButton(
        onPressed: _onScanPressed,
        child: const Text("SCAN"),
      );
    }
  }

  void _handleDeviceTap(PPDeviceModel device, int index) {
    switch (device.getDevicePeripheralType()) {
      case PPDevicePeripheralType.apple:
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => DeviceApple(device: device),
          ),
        );
        break;
      case PPDevicePeripheralType.coconut:
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => DeviceCoconut(device: device),
          ),
        );
        break;
      case PPDevicePeripheralType.banana:
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => DeviceBanana(device: device),
          ),
        );
        break;
      case PPDevicePeripheralType.ice:
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => DeviceIce(device: device),
          ),
        );
        break;
      case PPDevicePeripheralType.jambul:
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => DeviceJambul(device: device),
          ),
        );
        break;
      case PPDevicePeripheralType.torre:
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => DeviceTorre(device: device),
          ),
        );
        break;
      case PPDevicePeripheralType.borre:
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => DeviceBorre(device: device),
          ),
        );
        break;
      case PPDevicePeripheralType.fish:
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => DeviceFish(device: device),
          ),
        );
        break;
      case PPDevicePeripheralType.hamburger:
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => DeviceHamburger(device: device),
          ),
        );
        break;
      case PPDevicePeripheralType.egg:
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => DeviceEgg(device: device),
          ),
        );
        break;
      case PPDevicePeripheralType.grapes:
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => DeviceGrapes(device: device),
          ),
        );
        break;
      default:
        print('undefined-${device.getDevicePeripheralType()}');
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        title: Text(widget.title),
        backgroundColor: Colors.black,
        elevation: 0,
      ),
      body: _scanResults.isEmpty
          ? Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.bluetooth_searching,
              size: 60,
              color: accent.withOpacity(0.7),
            ),
            const SizedBox(height: 20),
            Text(
              _isScanning
                  ? "Сканирование устройств..."
                  : "Устройства не найдены\nили Bluetooth выключен",
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 16,
                color: Colors.white70,
              ),
            ),
            const SizedBox(height: 20),
            if (_isScanning)
              CircularProgressIndicator(color: accent),
          ],
        ),
      )
          : ListView.builder(
        padding: const EdgeInsets.symmetric(vertical: 10),
        itemCount: _scanResults.length,
        itemBuilder: (context, index) {
          final device = _scanResults[index];

          return GestureDetector(
            onTap: () {
              _handleDeviceTap(device, index);
            },
            child: Container(
              margin:
              const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.05),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: accent.withOpacity(0.3),
                ),
              ),
              child: Row(
                children: [
                  // Иконка
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: LinearGradient(
                        colors: [primary, accent],
                      ),
                    ),
                    child: const Icon(
                      Icons.scale,
                      color: Colors.white,
                    ),
                  ),

                  const SizedBox(width: 15),

                  // Инфа
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          (device.deviceName != null && device.deviceName.toString().isNotEmpty)
                              ? device.deviceName.toString()
                              : "Unknown Device",
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          "RSSI: ${device.rssi}",
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.6),
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          device.deviceMac?.toString() ?? "No MAC",
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.4),
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),

                  const Icon(
                    Icons.arrow_forward_ios,
                    color: Colors.white38,
                    size: 16,
                  ),
                ],
              ),
            ),
          );
        },
      ),
      floatingActionButton: _buildScanButton(context),
    );
  }
}
