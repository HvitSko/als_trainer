import 'patient_model.dart';

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
  // GŁÓWNY BOHATER
  late PatientModel patient;

  // STAN SCENARIUSZA
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

  // --- DRZWI DO PŁUC (Narzędzia i akcje - nie fizjologia!) ---
  AirwayType airwayStatus = AirwayType.none;
  IntubationStatus intubationStatus = IntubationStatus.none;
  int oxygenFlow = 0;
  bool isPreoxygenated = false;
  bool isCapnographyAttached = false;
  bool isAuscultated = false;
  bool intubationAttemptInProgress = false;
  bool isIntubationVerified = false;

  // --- DIAGNOSTYKA (Flagi akcji Zespołu) ---
  bool isGlucoseMeasured = false;
  bool isTempMeasured = false;
  bool isPhysicalExamDone = false;
  Set<String> considered4H4T = {};
}
