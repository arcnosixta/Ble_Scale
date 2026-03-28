import 'dart:async';
import 'package:ble_scale_app/core/body_analyzer.dart';
import 'package:ble_scale_app/ui/theme.dart';
import 'package:ble_scale_app/ui/widgets/analysis_grid.dart';
import 'package:flutter/material.dart';
import 'package:pp_bluetooth_kit_flutter/ble/pp_bluetooth_kit_manager.dart';
import 'package:pp_bluetooth_kit_flutter/ble/pp_peripheral_ice.dart';
import 'package:pp_bluetooth_kit_flutter/enums/pp_scale_enums.dart';
import 'package:pp_bluetooth_kit_flutter/model/pp_device_model.dart';
import 'package:pp_bluetooth_kit_flutter/model/pp_device_user.dart';

class DeviceIce extends StatefulWidget {
  final PPDeviceModel device;
  const DeviceIce({Key? key, required this.device}) : super(key: key);

  @override
  State<DeviceIce> createState() => _DeviceIceState();
}

class _DeviceIceState extends State<DeviceIce> {
  dynamic _bodyData;
  PPDeviceConnectionState _connectionStatus = PPDeviceConnectionState.disconnected;
  double _weightValue = 0;
  String _measurementStateStr = 'Ожидание...';
  Timer? _timer;

  // Данные пользователя для точного расчета жира
  final PPDeviceUser _userProfile = PPDeviceUser(
    userHeight: 180,
    age: 18,
    sex: PPUserGender.male,
    unitType: PPUnitType.Unit_KG,
  );

  @override
  void initState() {
    super.initState();
    _startConnection();
  }

  void _startConnection() {
    PPBluetoothKitManager.connectDevice(widget.device, callBack: (state) {
      if (state == PPDeviceConnectionState.connected) {
        PPPeripheralIce.syncUnit(_userProfile.unitType);

        Future.delayed(const Duration(seconds: 2), () async {
          final result = await PPPeripheralIce.impedanceSwitchControl(true);
          print("IMPEDANCE ENABLE RESULT: $result");
        });
      }
      _timer?.cancel();
      _timer = Timer.periodic(const Duration(seconds: 10), (timer) {
        PPPeripheralIce.keepAlive();
      });
      if (mounted) setState(() => _connectionStatus = state);
    });

    PPBluetoothKitManager.addMeasurementListener(
      callBack: (measurementState, dataModel, device) {

        print("RAW DATA: ${dataModel.toJson()}");


        if (mounted) {
          setState(() {
            _weightValue = dataModel.weight / 100.0;
            _bodyData = dataModel; // Сохраняем модель (включая импеданс для сетки)

            if (measurementState == PPMeasurementDataState.completed) {
              _measurementStateStr = 'Готово';
            } else if (measurementState == PPMeasurementDataState.measuringBodyFat) {
              _measurementStateStr = 'Анализ состава тела...';
            } else if (measurementState == PPMeasurementDataState.measuringHeartRate) {
              _measurementStateStr = 'Измерение пульса...';
            } else {
              _measurementStateStr = 'Взвешивание...';
            }
          });
        }
      },
    );
  }

  @override
  void dispose() {
    _timer?.cancel();
    PPBluetoothKitManager.stopScan();
    super.dispose();
  }

  // --- UI КОМПОНЕНТЫ ---

  Widget _buildWeightBlock() {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.symmetric(vertical: 40),
      decoration: BoxDecoration(
        gradient: LinearGradient(colors: [primary, accent]),
        borderRadius: BorderRadius.circular(30),
        boxShadow: [
          BoxShadow(color: accent.withOpacity(0.3), blurRadius: 20, offset: const Offset(0, 10))
        ],
      ),
      child: Column(
        children: [
          Text(_measurementStateStr, style: const TextStyle(color: Colors.white70, fontSize: 16)),
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                _weightValue.toStringAsFixed(2),
                style: const TextStyle(color: Colors.white, fontSize: 80, fontWeight: FontWeight.bold),
              ),
              const Padding(
                padding: EdgeInsets.only(bottom: 15, left: 8),
                child: Text("kg", style: TextStyle(color: Colors.white, fontSize: 24)),
              ),
            ],
          ),
          Text(
            _connectionStatus == PPDeviceConnectionState.connected ? "Подключено" : "Поиск весов...",
            style: const TextStyle(color: Colors.white54),
          ),
        ],
      ),
    );
  }

  Widget _buildSettingsPanel() {
    return Container(
      height: 100,
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        children: [
          // Закомментированы проблемные методы для проверки работы сетки анализов
          _buildActionChip(Icons.refresh, "Сброс", () => PPPeripheralIce.exitNetworkConfig()),
          _buildActionChip(Icons.settings_bluetooth, "Unit", () => PPPeripheralIce.syncUnit(PPUnitType.Unit_LB)),
          _buildActionChip(Icons.history, "История", () => PPPeripheralIce.fetchHistoryData(callBack: (list, success) {})),
        ],
      ),
    );
  }

  Widget _buildActionChip(IconData icon, String label, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(right: 12),
        padding: const EdgeInsets.symmetric(horizontal: 20),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.05),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.white12),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: accent, size: 18),
            const SizedBox(height: 4),
            Text(label, style: const TextStyle(color: Colors.white70, fontSize: 12)),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final json = _bodyData?.toJson() ?? {};

    final result = BodyAnalyzer.calculate(
      weight: _weightValue,
      height: 180,
      age: 18,
      isMale: true,
      data: json,
    );

    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        title: Text(widget.device.deviceName ?? "Умные весы"),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: Column(
        children: [
          _buildWeightBlock(),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 20, vertical: 10),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Text("АНАЛИЗ СОСТАВА ТЕЛА", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, letterSpacing: 1.2)),
            ),
          ),
          Expanded(
            child: (_weightValue == 0)
                ? const Center(child: Text("Встаньте на весы голыми ногами", style: TextStyle(color: Colors.white38)))
                : AnalysisGrid(bodyData: result),
          ),
          _buildSettingsPanel(),
        ],
      ),
    );
  }
}
