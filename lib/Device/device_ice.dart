import 'dart:async';
import 'package:ble_scale_app/ui/theme.dart';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:ble_scale_app/Common/Define.dart';
import 'package:ble_scale_app/Common/custom_widgets.dart';
import 'package:pp_bluetooth_kit_flutter/ble/pp_bluetooth_kit_manager.dart';
import 'package:pp_bluetooth_kit_flutter/ble/pp_peripheral_ice.dart';
import 'package:pp_bluetooth_kit_flutter/enums/pp_scale_enums.dart';
import 'package:pp_bluetooth_kit_flutter/model/pp_body_base_model.dart';
import 'package:pp_bluetooth_kit_flutter/model/pp_device_model.dart';
import 'package:pp_bluetooth_kit_flutter/model/pp_wifi_result.dart';

class DeviceIce extends StatefulWidget {
  final PPDeviceModel device;

  const DeviceIce({Key? key, required this.device}) : super(key: key);

  @override
  State<DeviceIce> createState() => _DeviceIceState();
}

class _DeviceIceState extends State<DeviceIce> {
  final ScrollController _gridController = ScrollController();
  dynamic _bodyData;
  PPUnitType _unit = PPUnitType.Unit_KG;
  PPDeviceConnectionState _connectionStatus =
      PPDeviceConnectionState.disconnected;
  double _weightValue = 0;
  String _measurementStateStr = '';
  Timer? _timer;

  final List<GridItem> _gridItems = [
    GridItem(DeviceMenuType.syncTime.value),
    GridItem(DeviceMenuType.changeUnit.value),
    GridItem(DeviceMenuType.fetchHistory.value),
    GridItem(DeviceMenuType.getPower.value),
    GridItem(DeviceMenuType.configNetwork.value),
    GridItem(DeviceMenuType.queryWifiConfig.value),
    GridItem(DeviceMenuType.getDeviceInfo.value),
    GridItem(DeviceMenuType.restoreFactory.value),
    GridItem(DeviceMenuType.turnOnHeartRate.value),
    GridItem(DeviceMenuType.turnOffHeartRate.value),
    GridItem(DeviceMenuType.getHeartRateSW.value),
    GridItem(DeviceMenuType.turnOnImpedance.value),
    GridItem(DeviceMenuType.turnOffImpedance.value),
    GridItem(DeviceMenuType.getImpedanceSW.value),
    GridItem(DeviceMenuType.syncDeviceLog.value),
    GridItem(DeviceMenuType.userOTA.value),
  ];

  @override
  void initState() {
    final ppDevice = widget.device;
    PPBluetoothKitManager.connectDevice(ppDevice, callBack: (state) {
      _timer?.cancel();
      _timer = Timer.periodic(const Duration(seconds: 10), (timer) {
        PPPeripheralIce.keepAlive();
      });

      _connectionStatus = state;
      if (mounted) {
        setState(() {});
      }
    });

    PPBluetoothKitManager.addMeasurementListener(
        callBack: (measurementState, dataModel, device) {
          _weightValue = dataModel.weight / 100.0;

          print(
              'weight:$_weightValue measurementState:$measurementState dataModel:${dataModel.toJson()}');

          switch (measurementState) {
            case PPMeasurementDataState.completed:
              _measurementStateStr = 'state:completed';
              // ALWAYS assign dataModel to _bodyData
              _bodyData = dataModel;
              break;
            case PPMeasurementDataState.measuringHeartRate:
              _measurementStateStr = 'state:measuringHeartRate';
              break;
            case PPMeasurementDataState.measuringBodyFat:
              _measurementStateStr = 'state:measuringBodyFat';
              break;
            default:
              _measurementStateStr = 'state:processData';
              break;
          }

          if (mounted) {
            setState(() {});
          }
        });

    super.initState();
  }

  /// Safely extracts value from body data using JSON keys
  dynamic _getValue(String key) {
    if (_bodyData == null) return null;
    try {
      final json = _bodyData.toJson();
      return json[key];
    } catch (e) {
      return null;
    }
  }

  Future<void> _handle(String title) async {
    if (_connectionStatus != PPDeviceConnectionState.connected) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Device Disconnect')),
      );
      return;
    }

    try {
      if (title == DeviceMenuType.syncTime.value) {
        await PPPeripheralIce.syncTime();
      }
      if (title == DeviceMenuType.changeUnit.value) {
        _unit = _unit == PPUnitType.Unit_KG
            ? PPUnitType.Unit_LB
            : PPUnitType.Unit_KG;
        await PPPeripheralIce.syncUnit(_unit);
      }
      if (title == DeviceMenuType.fetchHistory.value) {
        PPPeripheralIce.fetchHistoryData(callBack: (dataList, isSuccess) {
          if (isSuccess && dataList.isNotEmpty) {
            PPPeripheralIce.deleteHistoryData();
          }
        });
      }
      if (title == DeviceMenuType.getPower.value) {
        PPPeripheralIce.fetchBatteryInfo(
            continuity: true,
            callBack: (power) {
              print('power:$power');
            });
      }
      if (title == DeviceMenuType.configNetwork.value) {
        _showWifiInputDialog(context, (ssid, password) async {
          PPWifiResult result = await PPPeripheralIce.configWifi(
              domain: "http://120.79.144.170:6032",
              ssId: ssid,
              password: password);
          print('Distribution network results:${result.success}');
        });
      }
      if (title == DeviceMenuType.queryWifiConfig.value) {
        final ssId = await PPPeripheralIce.fetchWifiInfo()
            .timeout(const Duration(seconds: 5));
        print('ssId:$ssId');
      }
      if (title == DeviceMenuType.getDeviceInfo.value) {
        final device180AModel = await PPPeripheralIce.fetchDeviceInfo()
            .timeout(const Duration(seconds: 5));
        print(
            'firmwareRevision:${device180AModel?.firmwareRevision} modelNumber:${device180AModel?.modelNumber}');
      }
      if (title == DeviceMenuType.restoreFactory.value) {
        PPPeripheralIce.resetDevice();
      }
      if (title == DeviceMenuType.turnOnHeartRate.value) {
        await PPPeripheralIce.heartRateSwitchControl(true);
      }
      if (title == DeviceMenuType.turnOffHeartRate.value) {
        await PPPeripheralIce.heartRateSwitchControl(false);
      }
      if (title == DeviceMenuType.getHeartRateSW.value) {
        final ret = await PPPeripheralIce.fetchHeartRateSwitch();
        print('fetchHeartRateSwitch return:$ret');
      }
      if (title == DeviceMenuType.turnOnImpedance.value) {
        await PPPeripheralIce.impedanceSwitchControl(true);
      }
      if (title == DeviceMenuType.turnOffImpedance.value) {
        await PPPeripheralIce.impedanceSwitchControl(false);
      }
      if (title == DeviceMenuType.getImpedanceSW.value) {
        final ret = await PPPeripheralIce.fetchImpedanceSwitch();
        print('fetchImpedanceSwitch return:$ret');
      }
      if (title == DeviceMenuType.syncDeviceLog.value) {
        final directory = await getApplicationDocumentsDirectory();
        final logDirectory = '${directory.path}/DeviceLog';
        PPPeripheralIce.syncDeviceLog(logDirectory,
            callBack: (progress, isFailed, filePath) {
              print('sync log-isFailed:$isFailed filePath:$filePath');
            });
      }
      if (title == DeviceMenuType.userOTA.value) {
        await PPPeripheralIce.wifiOTA();
      }
    } on TimeoutException catch (e) {
      print('TimeoutException:$e');
    } catch (e) {
      print('Exception:$e');
    }
  }

  void _showWifiInputDialog(
      BuildContext context, Function(String ssid, String password) callBack) {
    final TextEditingController _ssidController = TextEditingController();
    final TextEditingController _passwordController = TextEditingController();

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Enter Wi-Fi information'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: [
                  const Text('SSID: ', style: TextStyle(fontSize: 14)),
                  Expanded(
                    child: TextField(
                      controller: _ssidController,
                      decoration: const InputDecoration(
                        hintText: 'Enter the Wi-Fi name',
                        border: OutlineInputBorder(),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  const Text('Password: ', style: TextStyle(fontSize: 14)),
                  Expanded(
                    child: TextField(
                      controller: _passwordController,
                      obscureText: false,
                      decoration: const InputDecoration(
                        hintText: 'Enter the Wi-Fi password',
                        border: OutlineInputBorder(),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('取消'),
            ),
            TextButton(
              onPressed: () {
                final ssid = _ssidController.text;
                final password = _passwordController.text;
                Navigator.pop(context);
                callBack(ssid, password);
              },
              child: const Text('确定'),
            ),
          ],
        );
      },
    );
  }

  @override
  void dispose() {
    _gridController.dispose();
    PPBluetoothKitManager.stopScan();
    PPBluetoothKitManager.disconnect();
    _timer?.cancel();
    super.dispose();
  }

  Widget buildMetricCard(String title, String value) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.05),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            title,
            style: const TextStyle(color: Colors.white60, fontSize: 12),
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        title: const Text("SMART SCALE"),
        backgroundColor: Colors.black,
        elevation: 0,
      ),
      body: Column(
        children: [
          const SizedBox(height: 20),
          // ⚖️ WEIGHT BLOCK
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 16),
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(25),
              gradient: LinearGradient(
                colors: [primary, accent],
              ),
              boxShadow: [
                BoxShadow(
                  color: accent.withOpacity(0.4),
                  blurRadius: 30,
                )
              ],
            ),
            child: Column(
              children: [
                const Text(
                  "Current Weight",
                  style: TextStyle(color: Colors.white70),
                ),
                const SizedBox(height: 10),
                TweenAnimationBuilder(
                  tween: Tween(begin: 0.0, end: _weightValue),
                  duration: const Duration(milliseconds: 500),
                  builder: (_, double value, __) {
                    return Text(
                      "${value.toStringAsFixed(1)} kg",
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 48,
                        fontWeight: FontWeight.bold,
                      ),
                    );
                  },
                ),
                const SizedBox(height: 10),
                Text(
                  _connectionStatus == PPDeviceConnectionState.connected
                      ? "Connected"
                      : "Disconnected",
                  style: const TextStyle(color: Colors.white70),
                ),
                const SizedBox(height: 4),
                Text(
                  _measurementStateStr,
                  style: const TextStyle(color: Colors.white70),
                ),
              ],
            ),
          ),

          const SizedBox(height: 20),

          // 📊 METRICS GRID
          Expanded(
            flex: 2,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: (_bodyData == null && _weightValue == 0)
                  ? Center(
                child: Text(
                  _isScanningOrConnecting()
                      ? "Measuring..."
                      : "Waiting for measurement",
                  style: const TextStyle(color: Colors.white54),
                ),
              )
                  : GridView.count(
                crossAxisCount: 2,
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
                childAspectRatio: 1.5,
                children: [
                  buildMetricCard("Body Fat", "${_getValue("bodyFat") ?? '--'} %"),
                  buildMetricCard("Water", "${_getValue("water") ?? '--'} %"),
                  buildMetricCard("Muscle", "${_getValue("muscle") ?? '--'} %"),
                  buildMetricCard("Visceral Fat", "${_getValue("visceralFat") ?? '--'}"),
                  buildMetricCard("BMI", "${_getValue("bmi") ?? '--'}"),
                  buildMetricCard("Heart Rate", "${_getValue("heartRate") ?? '--'} bpm"),
                ],
              ),
            ),
          ),

          // ⚙️ SETTINGS BUTTONS
          Expanded(
            flex: 1,
            child: Container(
              margin: const EdgeInsets.all(16),
              child: GridView.builder(
                controller: _gridController,
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 4,
                  crossAxisSpacing: 8,
                  mainAxisSpacing: 8,
                ),
                itemCount: _gridItems.length,
                itemBuilder: (context, index) {
                  final model = _gridItems[index];
                  return GestureDetector(
                    onTap: () => _handle(model.title),
                    child: Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(12),
                        color: Colors.white.withOpacity(0.05),
                      ),
                      child: const Center(
                        child: Icon(Icons.settings, color: Colors.white30, size: 20),
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }

  bool _isScanningOrConnecting() {
    return _connectionStatus != PPDeviceConnectionState.connected ||
        _measurementStateStr.contains("measuring");
  }
}
