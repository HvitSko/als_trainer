enum PatientRhythm { unknown, vf, pvt, asystole, pea }

enum ResuscitationPhase {
  assessmentABCDE,
  analyzing,
  rhythmCheck,
  cprCycle,
  postResuscitation,
}

class AlsScenarioState {
  ResuscitationPhase currentPhase;
  PatientRhythm monitorRhythm;
  int cprSecondsRemaining;
  int shocksDelivered;
  bool isDefibCharged;
  int totalElapsedGameTime;
  List<String> preparedDrugs;
  bool isPreparingDrug;

  bool isCprActive;
  // O to krzyczał terminal! Tutaj musi być dokładnie słowo 'log'
  List<String> log;

  AlsScenarioState({
    this.currentPhase = ResuscitationPhase.assessmentABCDE,
    this.monitorRhythm = PatientRhythm.unknown,
    this.cprSecondsRemaining = 120,
    this.shocksDelivered = 0,
    this.isDefibCharged = false,
    this.totalElapsedGameTime = 0,
    this.preparedDrugs = const [],
    this.isPreparingDrug = false,
    this.isCprActive = false,
    // I tutaj domyślnie pusta lista pod nazwą 'log'
    this.log = const [],
  });
}
