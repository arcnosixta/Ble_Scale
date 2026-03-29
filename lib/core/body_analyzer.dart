import 'dart:math';
import 'package:flutter/foundation.dart';

class BodyAnalyzer {
  static Map<String, dynamic> calculate({
    required double weight,
    required double height,
    required int age,
    required bool isMale,
    required Map<String, dynamic> data,
  }) {
    if (weight <= 0) return {};

    // ========================
    // DECODE & NORMALIZE
    // ========================
    double decode(String key) {
      int raw = (data[key] ?? 0).toInt();
      return raw / 1000000.0;
    }

    double norm(double z) {
      if (z < 50) return 50;
      if (z > 1500) return 1500;
      return z;
    }

    double la20 = norm(decode("z20KhzLeftArmEnCode"));
    double ra20 = norm(decode("z20KhzRightArmEnCode"));
    double ll20 = norm(decode("z20KhzLeftLegEnCode"));
    double rl20 = norm(decode("z20KhzRightLegEnCode"));
    double tr20 = norm(decode("z20KhzTrunkEnCode"));

    double la100 = norm(decode("z100KhzLeftArmEnCode"));
    double ra100 = norm(decode("z100KhzRightArmEnCode"));
    double ll100 = norm(decode("z100KhzLeftLegEnCode"));
    double rl100 = norm(decode("z100KhzRightLegEnCode"));
    double tr100 = norm(decode("z100KhzTrunkEnCode"));

    // ========================
    // BODY COMPOSITION BASE
    // ========================
    double z100Avg = (la100 + ra100 + ll100 + rl100 + tr100) / 5;
    double tbw = 0.372 * weight + (3.05 * (height * height) / z100Avg) - 0.142 * age + (isMale ? 5.0 : -3.0);
    tbw = tbw.clamp(weight * 0.45, weight * 0.75);

    double ffm = (tbw / 0.73).clamp(weight * 0.6, weight * 0.95);
    double fatMass = (weight - ffm).clamp(weight * 0.05, weight * 0.4);
    double fatPercent = (fatMass / weight) * 100;

    double muscleKg = (ffm * 0.85).clamp(weight * 0.5, weight * 0.9);
    double musclePercent = (muscleKg / weight) * 100;

    // ========================
    // WEIGHTED SEGMENT ANALYSIS
    // ========================
    // Anatomical weights (approximate muscle distribution)
    const wArm = 0.18;
    const wLeg = 0.32;
    const wTrunk = 0.50;

    // Weighted Admittance (1/Z) calculation
    double getInv(double z20, double z100, double weight) {
      double zEff = (0.7 * z20 + 0.3 * z100);
      return (1 / zEff).clamp(0.0001, 1.0) * weight;
    }

    double invLA = getInv(la20, la100, wArm);
    double invRA = getInv(ra20, ra100, wArm);
    double invLL = getInv(ll20, ll100, wLeg);
    double invRL = getInv(rl20, rl100, wLeg);
    double invTR = getInv(tr20, tr100, wTrunk);

    double totalInv = invLA + invRA + invLL + invRL + invTR;

    // Distribute Muscle (Weighted)
    double mLA = muscleKg * (invLA / totalInv);
    double mRA = muscleKg * (invRA / totalInv);
    double mLL = muscleKg * (invLL / totalInv);
    double mRL = muscleKg * (invRL / totalInv);
    double mTR = muscleKg * (invTR / totalInv);

    // Sanity Checks for Segment Proportions
    // 1. Balance check (max 20% difference between limbs)
    double balance(double left, double right) {
      if (left == 0 || right == 0) return 1.0;
      double diff = (left - right).abs() / ((left + right) / 2);
      if (diff > 0.20) {
        double avg = (left + right) / 2;
        return avg; // Return avg if diff is too high
      }
      return -1.0; // No adjustment needed
    }

    double bArm = balance(mLA, mRA);
    if (bArm != -1.0) { mLA = bArm; mRA = bArm; }

    double bLeg = balance(mLL, mRL);
    if (bLeg != -1.0) { mLL = bLeg; mRL = bLeg; }

    // 2. Trunk Proportion Check (40-60%)
    double trProp = mTR / muscleKg;
    if (trProp < 0.40) mTR = muscleKg * 0.40;
    if (trProp > 0.60) mTR = muscleKg * 0.60;

    // Final Normalize to ensure sum == muscleKg
    double currentSum = mLA + mRA + mLL + mRL + mTR;
    double normFactor = muscleKg / currentSum;
    mLA *= normFactor; mRA *= normFactor; mLL *= normFactor; mRL *= normFactor; mTR *= normFactor;

    // Distribute Fat (proportional to muscle segments as a simplified model)
    double fFactor = fatMass / muscleKg;
    double fLA = mLA * fFactor; double fRA = mRA * fFactor;
    double fLL = mLL * fFactor; double fRL = mRL * fFactor;
    double fTR = mTR * fFactor;

    // ========================
    // FINAL RESULTS
    // ========================
    double bmr = (10 * weight) + (6.25 * height) - (5 * age) + (isMale ? 5 : -161);
    
    return {
      "bmi": weight / pow(height / 100, 2),
      "bodyFat": fatPercent.clamp(5.0, 35.0),
      "fatMass": fatMass,
      "muscle": musclePercent.clamp(60.0, 90.0),
      "muscleKg": muscleKg,
      "water": (tbw / weight * 100).clamp(50.0, 75.0),
      "visceralFat": (fatPercent * 0.35).clamp(1.0, 15.0),
      "protein": (ffm * 0.21 / weight * 100).clamp(10.0, 20.0),
      "bmr": bmr,
      "boneMass": weight * 0.045,
      "m_la": mLA, "m_ra": mRA, "m_ll": mLL, "m_rl": mRL, "m_tr": mTR,
      "f_la": fLA, "f_ra": fRA, "f_ll": fLL, "f_rl": fRL, "f_tr": fTR,
      "bodyAge": age + (fatPercent - 15) * 0.5,
      "bodyHealth": (100 - (fatPercent - 12).abs() * 3).clamp(0, 100),
      "idealWeight": height - 100,
    };
  }
}
