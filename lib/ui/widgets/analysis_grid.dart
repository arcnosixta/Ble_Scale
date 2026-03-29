import 'package:flutter/material.dart';

class AnalysisGrid extends StatelessWidget {
  final Map<String, dynamic>? bodyData;
  const AnalysisGrid({Key? key, this.bodyData}) : super(key: key);

  /// Безопасное извлечение и форматирование строковых значений
  String _val(String k, {int d = 1, String u = ""}) {
    try {
      if (bodyData == null || !bodyData!.containsKey(k)) {
        return "--";
      }
      final v = bodyData![k];
      
      // Логирование для отладки источников null
      debugPrint("AnalysisGrid: Extraction - KEY: $k VALUE: $v");

      if (v == null || v == 0) return "--";
      
      String result;
      if (v is double) {
        result = v.toStringAsFixed(d);
      } else {
        result = v.toString();
      }
      
      return "$result$u";
    } catch (e) {
      debugPrint("AnalysisGrid: Error extracting $k - $e");
      return "--";
    }
  }

  @override
  Widget build(BuildContext context) {
    // Безопасная проверка на отсутствие данных
    final bool isDataMissing = bodyData == null || bodyData!.isEmpty;
    
    if (isDataMissing) {
      return const Center(
        child: Text(
          "Ожидание данных...", 
          style: TextStyle(color: Colors.white24)
        )
      );
    }

    return ListView(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      children: [
        _buildSection("ОСНОВНОЕ", [
          _card("ИМТ (BMI)", _val('bmi'), Icons.accessibility, _getColor('bmi')),
          _card("Жир", "${_val('bodyFat')}% (${_val('fatMass')}кг)", Icons.opacity, _getColor('fat')),
          _card("Мышцы", "${_val('muscle')}% (${_val('muscleKg')}кг)", Icons.fitness_center, Colors.green),
          _card("Вода", "${_val('water')}%", Icons.water_drop, Colors.blue),
        ]),

        _buildSection("ДЕТАЛИ", [
          _card("Висцеральный жир", _val('visceralFat'), Icons.monitor_weight, _getColor('visceral')),
          _card("Белок", _val('protein', u: "%"), Icons.egg, Colors.orange),
          _card("BMR", _val('bmr', d: 0, u: " ккал"), Icons.bolt, Colors.yellow),
          _card("Кости", _val('boneMass', u: " кг"), Icons.brightness_high, Colors.blueGrey),
        ]),

        _buildSection("СЕГМЕНТАРНЫЙ АНАЛИЗ (Мышцы / Жир)", [
          _segmentCard("ЛЕВАЯ РУКА", _val('m_la'), _val('f_la')),
          _segmentCard("ПРАВАЯ РУКА", _val('m_ra'), _val('f_ra')),
          _segmentCard("ЛЕВАЯ НОГА", _val('m_ll'), _val('f_ll')),
          _segmentCard("ПРАВАЯ НОГА", _val('m_rl'), _val('f_rl')),
          _segmentCard("ТУЛОВИЩЕ", _val('m_tr'), _val('f_tr')),
        ]),

        _buildSection("СОСТОЯНИЕ", [
          // Исправлено: использование _val для безопасного получения 'bodyType'
          _card("Тип тела", _val('bodyType'), Icons.person, Colors.cyan),
          _card("Возраст тела", _val('bodyAge', d: 0), Icons.history, Colors.purpleAccent),
          _card("Оценка здоровья", "${_val('bodyHealth', d: 0)}/100", Icons.favorite, Colors.pink),
        ]),
      ],
    );
  }

  Widget _buildSection(String title, List<Widget> items) {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Padding(
        padding: const EdgeInsets.only(top: 24, bottom: 12, left: 4),
        child: Text(
          title ?? "--", 
          style: const TextStyle(color: Colors.white38, fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 1.2)
        ),
      ),
      GridView.count(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        crossAxisCount: 2,
        crossAxisSpacing: 10,
        mainAxisSpacing: 10,
        childAspectRatio: 1.8,
        children: items,
      ),
    ]);
  }

  Widget _card(String label, String value, IconData icon, Color color) {
    // Двойная защита от null значений в UI
    final String safeLabel = label ?? "--";
    final String safeValue = (value != null && value.isNotEmpty) ? value : "--";
    final Color safeColor = color ?? Colors.grey;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: safeColor.withOpacity(0.12),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: safeColor.withOpacity(0.3), width: 1),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisAlignment: MainAxisAlignment.center, children: [
        Row(children: [
          Icon(icon, color: safeColor, size: 14),
          const SizedBox(width: 6),
          Expanded(
            child: Text(
              safeLabel, 
              style: const TextStyle(color: Colors.white54, fontSize: 10), 
              overflow: TextOverflow.ellipsis
            )
          ),
        ]),
        const SizedBox(height: 8),
        FittedBox(
          child: Text(
            safeValue, 
            style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)
          )
        ),
      ]),
    );
  }

  Widget _segmentCard(String label, String muscle, String fat) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(color: Colors.white.withOpacity(0.05), borderRadius: BorderRadius.circular(18)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(
          label ?? "--", 
          style: const TextStyle(color: Colors.white38, fontSize: 9, fontWeight: FontWeight.bold)
        ),
        const Spacer(),
        _row("Мышцы", muscle, Colors.greenAccent),
        _row("Жир", fat, Colors.orangeAccent),
      ]),
    );
  }

  Widget _row(String l, String v, Color c) {
    final String safeLabel = l ?? "--";
    final String safeValue = (v != null && v.isNotEmpty) ? v : "--";
    final Color safeColor = c ?? Colors.grey;

    return Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
      Text(safeLabel, style: const TextStyle(color: Colors.white70, fontSize: 10)),
      Text("$safeValue кг", style: TextStyle(color: safeColor, fontSize: 11, fontWeight: FontWeight.bold)),
    ]);
  }

  Color _getColor(String type) {
    try {
      if (bodyData == null) return Colors.cyan;
      
      final dynamic rawValue = bodyData![type == 'fat' ? 'bodyFat' : type];
      final double v = (rawValue is num) ? rawValue.toDouble() : 0.0;
      
      if (type == 'bmi') return (v < 18.5 || v > 25) ? Colors.orange : Colors.green;
      if (type == 'fat') return (v > 20) ? Colors.redAccent : Colors.green;
      if (type == 'visceral') return (v > 9) ? Colors.red : Colors.orange;
      return Colors.cyan;
    } catch (e) {
      return Colors.cyan;
    }
  }
}
