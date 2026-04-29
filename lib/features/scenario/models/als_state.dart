enum ResuscitationPhase {
  assessmentABCDE,
  analyzing,
  rhythmCheck,
  cprCycle,
  postResuscitation,
}

enum PatientRhythm { unknown, vf, pvt, asystole, pea }

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
  int lastShockEnergy = 0; // NOWE: Pamięta energię poprzedniego wyładowania

  List<String> preparedDrugs = [];
  bool isPreparingDrug = false;

  List<String> log = [];

  int cprCyclesCompleted = 0;
  int lastAdrenalineTime = -999;
  int lastAmiodaroneTime = -999;

  int cprInactiveSeconds = 0; // NOWE: Licznik "hands-off time"
}
