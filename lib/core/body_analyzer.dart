import 'dart:math';

class BodyAnalyzer {
  static Map<String, dynamic> calculate({
    required double weight,
    required double height,
    required int age,
    required bool isMale,
    required Map<String, dynamic> data,
  }) {
    double get(String key) => (data[key] ?? 0).toDouble();

    // 1. Извлечение и нормализация сегментарного сопротивления
    double normalize(String key) {
      double raw = get(key);
      if (raw == 0) return 0;
      return (raw / 1000000).clamp(300.0, 900.0);
    }

    double rLA = normalize("z20KhzLeftArmEnCode");
    double rRA = normalize("z20KhzRightArmEnCode");
    double rLL = normalize("z20KhzLeftLegEnCode");
    double rRL = normalize("z20KhzRightLegEnCode");
    double rT = normalize("z20KhzTrunkEnCode");

    double rSum = rLA + rRA + rLL + rRL + rT;
    int count = [rLA, rRA, rLL, rRL, rT].where((v) => v > 0).length;
    double rAvg = count > 0 ? rSum / count : (get("impedance") / 1000).clamp(300.0, 900.0);

    if (rAvg == 0 || weight <= 0) return {};

    // 2. Базовые показатели
    double bmi = weight / pow(height / 100, 2);
    double bfBase = (1.20 * bmi) + (0.23 * age) - (isMale ? 10.8 : 0) - 5.4;
    double bodyFat = (bfBase - ((rAvg - 500) / 50)).clamp(5.0, 35.0);
    double fatMass = weight * bodyFat / 100;
    double ffm = weight - fatMass;
    double muscleKg = ffm * 0.88;
    double musclePercent = (muscleKg / weight) * 100;

    // 3. Сегментарный расчет мышц (Biomedical constants)
    double calcM(double r, double coeff) => r > 0 ? (pow(height, 2) / r) * coeff : 0;
    double mLA = calcM(rLA, 0.02);
    double mRA = calcM(rRA, 0.02);
    double mLL = calcM(rLL, 0.04);
    double mRL = calcM(rRL, 0.04);
    double mTR = calcM(rT, 0.06);

    // Нормализация сегментов к общему весу мышц
    double sSum = mLA + mRA + mLL + mRL + mTR;
    if (sSum > 0) {
      double factor = muscleKg / sSum;
      mLA *= factor; mRA *= factor; mLL *= factor; mRL *= factor; mTR *= factor;
    }

    // 4. Тип телосложения
    String bodyType = "Normal";
    if (bodyFat < 10 && musclePercent > 85) bodyType = "Lean Muscular";
    else if (bodyFat < 15) bodyType = "Fit";
    else if (bodyFat < 20) bodyType = "Normal";
    else bodyType = "Overweight";

    return {
      "bmi": bmi,
      "bodyFat": bodyFat,
      "fatMass": fatMass,
      "muscle": musclePercent,
      "muscleKg": muscleKg,
      "water": (ffm * 0.73 / weight) * 100,
      "waterKg": ffm * 0.73,
      "protein": (ffm * 0.21 / weight) * 100,
      "bmr": (10 * weight) + (6.25 * height) - (5 * age) + (isMale ? 5 : -161),
      "visceralFat": (bodyFat / 4).clamp(1.0, 15.0),
      "boneMass": weight * 0.045,
      "bodyAge": age + (bodyFat - 12) * 0.5,
      "bodyHealth": (100 - (bodyFat - 12).abs() * 2).clamp(0, 100),
      "bodyType": bodyType,
      "idealWeight": height - 100,
      // Сегменты (кг)
      "m_la": mLA, "m_ra": mRA, "m_ll": mLL, "m_rl": mRL, "m_tr": mTR,
      "f_la": fatMass * 0.05, "f_ra": fatMass * 0.05,
      "f_ll": fatMass * 0.20, "f_rl": fatMass * 0.20,
      "f_tr": fatMass * 0.50,
    };
  }
}