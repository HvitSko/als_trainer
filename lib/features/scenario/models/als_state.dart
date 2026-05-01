enum ResuscitationPhase {
  assessmentABCDE,
  analyzing,
  rhythmCheck,
  cprCycle,
  postResuscitation,
}

enum PatientRhythm { unknown, vf, pvt, asystole, pea }

enum AirwayType { none, basic, bvm, igel, endotracheal }

enum IntubationStatus { none, esophageal, rightMainstem, correct }

class AlsScenarioState {
  ResuscitationPhase currentPhase = ResuscitationPhase.assessmentABCDE;
  PatientRhythm monitorRhythm = PatientRhythm.unknown;

  int totalElapsedGameTime = 0;
  int cprSecondsRemaining = 0;
  bool isCprActive = false;

  int shocksDelivered = 0;
  bool isDefibCharged = false;
  bool isDefibCharging = false;
  int selectedEnergy = 150;
  int chargedEnergy = 0;
  int lastShockEnergy = 0;

  List<String> preparedDrugs = [];
  bool isPreparingDrug = false;
  List<String> log = [];

  int cprCyclesCompleted = 0;
  int lastAdrenalineTime = -999;
  int lastAmiodaroneTime = -999;
  int cprInactiveSeconds = 0;

  // --- DRZWI DO PŁUC (AIRWAY & BREATHING) ---
  AirwayType airwayStatus = AirwayType.none;
  IntubationStatus intubationStatus = IntubationStatus.none;

  double patientWeight = 75.0;
  int oxygenFlow = 0;
  bool isPreoxygenated = false; // NOWE: Flaga natlenienia przed ETI
  int etco2 = 0; // NOWE: Wartość kapnografii

  bool isCapnographyAttached = false;
  bool isAuscultated = false;
  bool intubationAttemptInProgress = false;
}
