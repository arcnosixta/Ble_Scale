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
      appBar: AppBar(
        title: Text(widget.title),
      ),
      body: _scanResults.isEmpty
          ? Center(
              child: Text(
                _isScanning ? "Идет поиск устройств..." : "Устройства не найдены или Bluetooth выключен",
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 16, color: Colors.grey),
              ),
            )
          : ListView.builder(
              itemCount: _scanResults.length,
              itemBuilder: (context, index) {
                final device = _scanResults[index];

                return InkWell(
                  onTap: () {
                    _handleDeviceTap(device, index);
                  },
                  borderRadius: BorderRadius.circular(12),
                  child: Card(
                    margin: const EdgeInsets.all(8.0),
                    elevation: 4.0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Name: ${device.deviceName}\t\tRSSI: ${device.rssi}\nMac: ${device.deviceMac}\nSetting ID: ${device.deviceSettingId}\nAdv Length: ${device.advLength}\t\tSign: ${device.sign}\nPeripheral Type: ${device.getDevicePeripheralType()}',
                            style: const TextStyle(fontSize: 14),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
      floatingActionButton: _buildScanButton(context),
    );
  }
}
