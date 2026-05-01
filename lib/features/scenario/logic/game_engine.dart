import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import '../models/als_state.dart';
import '../models/patient_model.dart';

class GameEngine extends ChangeNotifier {
  AlsScenarioState state = AlsScenarioState();
  Timer? _globalTimer;

  GameEngine() {
    // Inicjalizacja Głównego Bohatera w momencie startu silnika!
    state.patient = PatientModel.generateRandomArrest();
    _startGlobalTimer();
  }

  void _startGlobalTimer() {
    _globalTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      state.totalElapsedGameTime++;

      // LOGIKA ODSTĘPÓW (HANDS-OFF TIME)
      if (!state.isCprActive &&
          state.currentPhase != ResuscitationPhase.assessmentABCDE &&
          state.currentPhase != ResuscitationPhase.postResuscitation) {
        state.cprInactiveSeconds++;
        if (state.cprInactiveSeconds % 10 == 0) {
          _logEvent(
            "KRYTYCZNY BŁĄD EBM: Ręce oderwane od klatki już od ${state.cprInactiveSeconds} sekund! Mózg pacjenta umiera!",
          );
        }
      } else {
        state.cprInactiveSeconds = 0;
      }

      // LOGIKA PĘTLI RKO
      if (state.isCprActive) {
        if (state.cprSecondsRemaining > 0) {
          state.cprSecondsRemaining--;
        } else if (state.cprSecondsRemaining == 0) {
          if (state.totalElapsedGameTime % 5 == 0) {
            _logEvent(
              "INFO: Minęły 2 minuty RKO! ZATRZYMAJ uciśnięcia, aby ocenić rytm!",
            );
          }
        }
      }

      // FIZJOLOGIA: KAPNOGRAFIA (ETCO2) idzie prosto do modelu pacjenta!
      if (state.isCapnographyAttached) {
        if (state.intubationStatus == IntubationStatus.esophageal) {
          state.patient.etCo2 = 0;
        } else if (state.airwayStatus != AirwayType.none &&
            state.airwayStatus != AirwayType.basic) {
          if (state.isCprActive) {
            state.patient.etCo2 =
                10 + Random().nextInt(11); // 10-20 mmHg przy RKO
          } else {
            state.patient.etCo2 = state.patient.etCo2 > 2
                ? state.patient.etCo2 - 2
                : 0;
          }
        }
      }

      if (state.totalElapsedGameTime >= 600) {
        timer.cancel();
        state.currentPhase = ResuscitationPhase.postResuscitation;
        state.isCprActive = false;
        _logEvent("KONIEC SCENARIUSZA: Osiągnięto limit 10 minut.");
      }

      notifyListeners();
    });
  }

  // ... (reszta standardowej logiki defibrylatora i leków)
  Future<void> connectMonitor() async {
    if (state.currentPhase != ResuscitationPhase.assessmentABCDE) return;
    state.currentPhase = ResuscitationPhase.analyzing;
    _logEvent("INFO: Podłączono monitor. Trwa analiza rytmu...");
    notifyListeners();
    await Future.delayed(const Duration(seconds: 3));
    state.monitorRhythm = Random().nextBool()
        ? PatientRhythm.vf
        : PatientRhythm.asystole;
    state.currentPhase = ResuscitationPhase.rhythmCheck;
    _logEvent("DIAGNOZA: Wykryto ${state.monitorRhythm.name.toUpperCase()}");
    notifyListeners();
  }

  void stopCprAndAssess() async {
    if (!state.isCprActive) return;
    if (state.cprSecondsRemaining > 10) {
      _logEvent(
        "KRYTYCZNY BŁĄD EBM: Przerywasz RKO za wcześnie! Zostało ${state.cprSecondsRemaining}s.",
      );
    } else {
      _logEvent("SUKCES: Cykl 2-minutowy zaliczony pomyślnie.");
    }
    state.isCprActive = false;
    state.cprCyclesCompleted++;
    state.currentPhase = ResuscitationPhase.analyzing;
    _logEvent("AKCJA: RKO zatrzymane. Analiza EKG...");
    notifyListeners();
    await Future.delayed(const Duration(seconds: 3));

    // Prosta zmiana rytmu (Markow)
    int rand = Random().nextInt(100);
    if (rand < 20)
      state.monitorRhythm = state.monitorRhythm == PatientRhythm.vf
          ? PatientRhythm.asystole
          : PatientRhythm.vf;

    state.currentPhase = ResuscitationPhase.rhythmCheck;
    _logEvent(
      "DIAGNOZA: Aktualny rytm to ${state.monitorRhythm.name.toUpperCase()}",
    );
    notifyListeners();
  }

  void startCpr() {
    state.isCprActive = true;
    state.cprSecondsRemaining = 120;
    state.currentPhase = ResuscitationPhase.cprCycle;
    _logEvent("AKCJA: Rozpoczęto uciśnięcia klatki piersiowej (2 minuty).");
    notifyListeners();
  }

  void setEnergy(int energy) {
    state.selectedEnergy = energy;
    notifyListeners();
  }

  Future<void> chargeDefibrillator() async {
    if (state.isDefibCharged || state.isDefibCharging) return;
    state.isDefibCharging = true;
    _logEvent("INFO: Ładowanie do ${state.selectedEnergy}J...");
    notifyListeners();
    await Future.delayed(const Duration(seconds: 4));
    state.isDefibCharging = false;
    state.isDefibCharged = true;
    state.chargedEnergy = state.selectedEnergy;
    _logEvent("INFO: Defibrylator naładowany (${state.chargedEnergy}J).");
    notifyListeners();
  }

  void disarmDefibrillator() {
    if (!state.isDefibCharged) return;
    state.isDefibCharged = false;
    state.chargedEnergy = 0;
    _logEvent(
      "AKCJA: Defibrylator bezpiecznie rozładowany (Internal Discharge).",
    );
    notifyListeners();
  }

  void deliverShock() {
    if (!state.isDefibCharged) return;
    bool isFirstShock = state.shocksDelivered == 0;
    bool isValidShockTiming =
        isFirstShock ||
        !state.isCprActive ||
        (state.isCprActive && state.cprSecondsRemaining > 110);

    if (!isValidShockTiming)
      _logEvent("KRYTYCZNY BŁĄD EBM: Wyładowanie w połowie cyklu!");

    if (state.monitorRhythm == PatientRhythm.vf ||
        state.monitorRhythm == PatientRhythm.pvt) {
      state.shocksDelivered++;
      state.lastShockEnergy = state.chargedEnergy;
      _logEvent(
        "SUKCES: Defibrylacja nr ${state.shocksDelivered} energią ${state.chargedEnergy}J dostarczona.",
      );
      state.isCprActive = true;
      state.cprSecondsRemaining = 120;
      state.currentPhase = ResuscitationPhase.cprCycle;
    } else {
      _logEvent(
        "KRYTYCZNY BŁĄD: Wyładowanie ${state.chargedEnergy}J w rytmie ${state.monitorRhythm.name.toUpperCase()}!",
      );
    }
    state.isDefibCharged = false;
    notifyListeners();
  }

  Future<void> prepareDrug(String drugName, String dose) async {
    if (state.preparedDrugs.length >= 2 || state.isPreparingDrug) return;
    state.isPreparingDrug = true;
    state.preparedDrugs.add("Przygotowywanie: $drugName...");
    notifyListeners();
    await Future.delayed(const Duration(seconds: 4));
    state.preparedDrugs.removeLast();
    state.preparedDrugs.add("$drugName|$dose");
    state.isPreparingDrug = false;
    notifyListeners();
  }

  void administerDrug(int index) {
    if (index >= state.preparedDrugs.length) return;
    String drugName = state.preparedDrugs[index].split('|')[0];
    _logEvent("INFO: Podano lek: $drugName.");
    state.preparedDrugs.removeAt(index);
    notifyListeners();
  }

  // --- DRZWI DO PŁUC ---
  void openAirway() {
    if (state.airwayStatus != AirwayType.none) return;
    state.airwayStatus = AirwayType.basic;
    _logEvent("AKCJA: Udrożniono drogi oddechowe (rękoczyn czoło-żuchwa).");
    notifyListeners();
  }

  void setOxygenFlow(int flow) {
    state.oxygenFlow = flow;
    _logEvent("INFO: Ustawiono przepływ tlenu na $flow l/min.");
    notifyListeners();
  }

  void setupBVM() {
    state.airwayStatus = AirwayType.bvm;
    _logEvent("AKCJA: Założono maskę z workiem (BVM).");
    notifyListeners();
  }

  Future<void> preoxygenate() async {
    if (state.airwayStatus != AirwayType.bvm || state.oxygenFlow < 15) return;
    _logEvent("INFO: Zespół preoksygenuje pacjenta...");
    await Future.delayed(const Duration(seconds: 4));
    state.isPreoxygenated = true;
    _logEvent("SUKCES: Pacjent natleniony.");
    notifyListeners();
  }

  void insertIGel(int size) {
    if (state.airwayStatus == AirwayType.endotracheal) return;
    int expectedSize = 4;
    if (state.patient.weight > 90) expectedSize = 5;
    if (state.patient.weight < 50) expectedSize = 3;

    if (size != expectedSize) {
      _logEvent(
        "KRYTYCZNY BŁĄD: Założyłeś I-gel #$size u pacjenta ${state.patient.weight.toStringAsFixed(0)} kg! Narzędzie nieszczelne.",
      );
      return;
    }
    state.airwayStatus = AirwayType.igel;
    _logEvent("SUKCES: Założono I-gel #$size.");
    notifyListeners();
  }

  Future<void> attemptIntubation() async {
    if (state.intubationAttemptInProgress) return;
    state.intubationAttemptInProgress = true;
    _logEvent("AKCJA: Laryngoskopia i próba intubacji...");
    notifyListeners();

    await Future.delayed(const Duration(seconds: 4));
    int rand = Random().nextInt(100);
    if (rand < 70)
      state.intubationStatus = IntubationStatus.correct;
    else if (rand < 85)
      state.intubationStatus = IntubationStatus.esophageal;
    else
      state.intubationStatus = IntubationStatus.rightMainstem;

    state.airwayStatus = AirwayType.endotracheal;
    state.intubationAttemptInProgress = false;
    state.isIntubationVerified = false;
    _logEvent(
      "INFO: Rurka wprowadzona. ŚLEPA INTUBACJA. Natychmiast zweryfikuj jej położenie!",
    );
    notifyListeners();
  }

  void auscultate() {
    if (state.airwayStatus == AirwayType.none ||
        state.airwayStatus == AirwayType.basic)
      return;
    state.isAuscultated = true;

    if (state.airwayStatus == AirwayType.igel ||
        state.airwayStatus == AirwayType.bvm) {
      _logEvent(
        "DIAGNOZA (Osłuchiwanie): Szmer pęcherzykowy słyszalny obustronnie.",
      );
      notifyListeners();
      return;
    }
    if (state.airwayStatus == AirwayType.endotracheal) {
      state.isIntubationVerified = true;
      if (state.intubationStatus == IntubationStatus.correct)
        _logEvent("DIAGNOZA: Szmery słyszalne symetrycznie.");
      else
        _logEvent("DIAGNOZA: Problem! Rurka w przełyku lub za głęboko!");
    }
    notifyListeners();
  }

  void attachCapnography() {
    state.isCapnographyAttached = true;
    if (state.airwayStatus == AirwayType.endotracheal)
      state.isIntubationVerified = true;
    _logEvent("DIAGNOZA: Podłączono Kapnografię.");
    notifyListeners();
  }

  // --- DIAGNOSTYKA I 4H4T ---
  Future<void> measureGlucose() async {
    if (state.isGlucoseMeasured) return;
    _logEvent("AKCJA: Zespół nakłuwa palec...");
    notifyListeners();
    await Future.delayed(const Duration(seconds: 3));
    state.isGlucoseMeasured = true;
    _logEvent("DIAGNOZA: Glikemia ${state.patient.bloodGlucose} mg/dL.");
    notifyListeners();
  }

  Future<void> measureTemperature() async {
    if (state.isTempMeasured) return;
    _logEvent("AKCJA: Zespół mierzy temperaturę...");
    notifyListeners();
    await Future.delayed(const Duration(seconds: 3));
    state.isTempMeasured = true;
    _logEvent(
      "DIAGNOZA: Temperatura ${state.patient.temperature.toStringAsFixed(1)} °C.",
    );
    notifyListeners();
  }

  Future<void> performPhysicalExam() async {
    if (state.isPhysicalExamDone) return;
    _logEvent("AKCJA: Szybkie badanie urazowe (Exposure)...");
    notifyListeners();
    await Future.delayed(const Duration(seconds: 4));
    state.isPhysicalExamDone = true;
    _logEvent("DIAGNOZA (Badanie): Żyły szyjne zapadnięte. Źrenice szerokie.");
    notifyListeners();
  }

  void considerCause(String cause) {
    if (state.considered4H4T.contains(cause)) return;
    state.considered4H4T.add(cause);
    _logEvent("ZESPÓŁ ROZWAŻA: $cause.");
    notifyListeners();
  }

  void _logEvent(String message) {
    state.log.insert(
      0,
      "[${_formatTime(state.totalElapsedGameTime)}] $message",
    );
  }

  String _formatTime(int seconds) {
    final m = (seconds ~/ 60).toString().padLeft(2, '0');
    final s = (seconds % 60).toString().padLeft(2, '0');
    return "$m:$s";
  }

  @override
  void dispose() {
    _globalTimer?.cancel();
    super.dispose();
  }
}
