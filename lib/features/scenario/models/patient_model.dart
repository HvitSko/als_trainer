import 'dart:math';

enum ReversibleCause {
  none,
  hypoxia,
  hypovolemia,
  hypoHyperkalemia,
  hypothermia,
  thrombosis,
  tamponade,
  toxins,
  tensionPneumothorax,
}

class PatientModel {
  int heartRate;
  bool hasPulse;
  int systolicBP;
  int diastolicBP;
  int? spO2;
  int etCo2;
  double temperature;
  int bloodGlucose;
  double weight; // NOWE: Waga przeniesiona do pacjenta

  ReversibleCause hiddenCause;

  String skinCondition;
  String chestMovement;
  String pupils;

  PatientModel({
    required this.heartRate,
    required this.hasPulse,
    required this.systolicBP,
    required this.diastolicBP,
    this.spO2,
    required this.etCo2,
    required this.temperature,
    required this.bloodGlucose,
    required this.weight,
    required this.hiddenCause,
    required this.skinCondition,
    required this.chestMovement,
    required this.pupils,
  });

  // Generator pacjenta w NZK (RNG)
  factory PatientModel.generateRandomArrest() {
    final rand = Random();

    return PatientModel(
      heartRate: 0,
      hasPulse: false,
      systolicBP: 0,
      diastolicBP: 0,
      spO2: null,
      etCo2: 0,
      temperature: 30.0 + (rand.nextInt(75) / 10), // 30.0 - 37.5 °C
      bloodGlucose: 40 + rand.nextInt(160), // 40 - 200 mg/dL
      weight: 60.0 + rand.nextInt(50), // 60 - 110 kg
      hiddenCause: ReversibleCause.none, // Do rozbudowy 4H4T w kolejnych fazach
      skinCondition: "Blada, spocona, chłodna, zasinienie obwodowe",
      chestMovement: "Brak ruchów oddechowych",
      pupils: "Szerokie, niereaktywne na światło",
    );
  }
}
