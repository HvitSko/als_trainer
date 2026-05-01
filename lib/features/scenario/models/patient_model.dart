// lib/features/scenario/models/patient_model.dart

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
  // Parametry życiowe
  int heartRate; // Elektryczna czynność serca (widoczna na EKG)
  bool hasPulse; // KRYTYCZNE W EBM: Czy to PEA czy ROSC?
  int systolicBP;
  int diastolicBP;
  int? spO2; // Null, gdy brak fali tętna (np. w NZK)
  int etCo2;
  double temperature;
  int bloodGlucose;

  // Ukryty wróg - 4H4T
  ReversibleCause hiddenCause;

  // Fizykalne objawy (Widok Pacjenta)
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
    required this.hiddenCause,
    required this.skinCondition,
    required this.chestMovement,
    required this.pupils,
  });

  // Konstruktor dla standardowego pacjenta w NZK (Randomizacja)
  factory PatientModel.generateRandomArrest() {
    // Tutaj w przyszłości podepniemy potężny silnik losujący (RNG)
    return PatientModel(
      heartRate: 0, // Zależne od rytmu, w asystolii 0, w VF np. 250
      hasPulse: false, // W NZK zawsze false
      systolicBP: 0,
      diastolicBP: 0,
      spO2: null, // Pulsoksymetr nie czyta w NZK!
      etCo2: 0, // Rośnie dopiero, gdy zaczynamy uciski/wentylację
      temperature: 36.6, // Docelowo losowane np. 31.0 dla hipotermii
      bloodGlucose: 100, // Docelowo losowane
      hiddenCause: ReversibleCause.none, // Do rozbudowy 4H4T
      skinCondition: "Blada, spocona, chłodna",
      chestMovement: "Brak ruchów oddechowych",
      pupils: "Szerokie, niereaktywne na światło",
    );
  }
}
