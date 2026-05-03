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

enum GameMode { practice, test } // NOWE: Tryb gry

class AlsScenarioState {
  late PatientModel patient;

  GameMode mode = GameMode.practice; // Domyślnie tryb z podpowiedziami

  ResuscitationPhase currentPhase = ResuscitationPhase.assessmentABCDE;
  PatientRhythm monitorRhythm = PatientRhythm.unknown;
  int totalCprSeconds = 0; // Ile łącznie sekund ratownik uciskał
  int criticalErrorsCount = 0; // Ile razy zabił pacjenta
  int warningErrorsCount = 0; // Ile razy zlekceważył wytyczne EBM

  int totalElapsedGameTime = 0;
  int cprSecondsRemaining = 0;
  bool isCprActive = false;
  bool isBagOpen = false;
  bool isAirwayMenuOpen = false;

  int shocksDelivered = 0;
  bool isDefibCharged = false;
  bool isDefibCharging = false;
  int selectedEnergy = 150;
  int chargedEnergy = 0;
  int lastShockEnergy = 0;

  List<String> preparedDrugs = [];
  bool isPreparingDrug = false;
  List<String> administeredDrugs =
      []; // NOWE: Śmietnik zużytych ampułek (historia podaży)

  List<String> log = []; // Dziennik widoczny dla gracza
  List<String> auditLog =
      []; // NOWE: Ukryty Dziennik Audytora (do podsumowania na koniec!)

  int cprCyclesCompleted = 0;
  int lastAdrenalineTime = -999;
  int lastAmiodaroneTime = -999;
  int cprInactiveSeconds = 0;

  AirwayType airwayStatus = AirwayType.none;
  IntubationStatus intubationStatus = IntubationStatus.none;
  int oxygenFlow = 0;
  bool isPreoxygenated = false;
  bool isCapnographyAttached = false;
  bool isAuscultated = false;
  bool intubationAttemptInProgress = false;
  bool isIntubationVerified = false;
  bool isGlucoseMeasured = false;
  bool isTempMeasured = false;
  bool isPhysicalExamDone = false;
  bool isWarmingProvided = false; // NOWE: Terapia hipotermii
  bool isSpO2Attached = false; // NOWE: Czy klips jest na palcu?
  bool isUsgDone = false; // NOWE: Czy zrobiono Hokus POCUS?

  // BRKAUJĄCE OGNIWO: Zbiór przyczyn, które zespół rozważa (krótkie kliknięcie)
  Set<String> considered4H4T = {};

  // Statusy 4H4T (0 - neutralny, 1 - wyleczone/wykluczone (zielony), -1 - błąd (czerwony))
  Map<String, int> h4tStatus = {
    "Hipoksja": 0,
    "Hipowolemia": 0,
    "Hipo/Hiperkaliemia": 0,
    "Hipotermia": 0,
    "Tamponada": 0,
    "Toxins (Zatrucia)": 0,
    "Tension pneumothorax (Odma)": 0,
    "Thrombosis (Zator)": 0,
  };

  int secondsWithoutVentilation = 0; // NOWE: Stoper niedotlenienia
  bool airwayNeglectFlagged = false; // NOWE: Żeby nie spamować błędem 100 razy

  List<String> instructorFeedback = []; // NOWE: Lista mądrości na koniec gry
}
