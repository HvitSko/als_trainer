import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import '../models/als_state.dart';
import '../models/scenario_model.dart';

class GameEngine extends ChangeNotifier {
  AlsScenarioState state = AlsScenarioState();
  Timer? _globalTimer;

  GameEngine(Scenario scenario) {
    // Ładujemy pacjenta z dostarczonego scenariusza
    state.patient = scenario.generatePatient();
    // Ładujemy początkowy rytm na defibrylator (zanim podłączymy łyżki, defibrylator trzyma to w pamięci, ale UI pokaże "Nieznany")
    state.monitorRhythm = scenario.initialRhythm;
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
    _logEvent(
      "INFO: Zespół nakleja elektrody na klatkę. Trwa analiza rytmu...",
    );
    notifyListeners();

    await Future.delayed(const Duration(seconds: 3));

    // USUNIĘTO STARE LOSOWANIE RYTMU! (state.monitorRhythm = Random...)
    // Teraz rytm pochodzi prosto z wgranego Scenariusza!

    state.currentPhase = ResuscitationPhase.rhythmCheck;
    _logEvent(
      "DIAGNOZA: Wykryto ${state.monitorRhythm.name.toUpperCase()} na monitorze.",
    );
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
    String fullDrugInfo = state.preparedDrugs[index];
    List<String> parts = fullDrugInfo.split('|');
    String drugName = parts[0];
    String dose = parts.length > 1 ? parts[1] : "";
    int currentTime = state.totalElapsedGameTime;

    state.preparedDrugs.removeAt(index);

    bool isShockable =
        state.monitorRhythm == PatientRhythm.vf ||
        state.monitorRhythm == PatientRhythm.pvt;

    if (drugName == "Adrenalina") {
      if (dose != "1 mg") {
        _logEvent(
          "KRYTYCZNY BŁĄD EBM: Adrenalina w NZK to zawsze 1 mg! Podałeś $dose.",
        );
      } else {
        if (isShockable && state.shocksDelivered < 3) {
          _logEvent(
            "BŁĄD EBM: W rytmach do defibrylacji (VF/pVT) Adrenalinę podajemy dopiero PO 3. wyładowaniu!",
          );
        } else {
          _validateAdrenalineTiming(currentTime);
        }
      }
    } else if (drugName == "Amiodaron") {
      if (!isShockable) {
        _logEvent(
          "KRYTYCZNY BŁĄD EBM: Amiodaron w Asystolii/PEA?! To lek antyarytmiczny, nie podajemy go tutaj!",
        );
      } else {
        if (state.shocksDelivered < 3) {
          _logEvent(
            "BŁĄD EBM: Amiodaron podajemy dopiero po 3. wyładowaniu (300 mg) i 5. wyładowaniu (150 mg)!",
          );
        } else if (state.shocksDelivered >= 3 && state.shocksDelivered < 5) {
          if (dose == "300 mg") {
            _logEvent(
              "SUKCES: Amiodaron 300 mg podany prawidłowo po 3. defibrylacji.",
            );
          } else {
            _logEvent(
              "BŁĄD EBM: Zła dawka! Po 3. wyładowaniu podajemy 300 mg (podałeś $dose).",
            );
          }
        } else if (state.shocksDelivered >= 5) {
          if (dose == "150 mg") {
            _logEvent(
              "SUKCES: Amiodaron 150 mg podany prawidłowo po 5. defibrylacji.",
            );
          } else {
            _logEvent(
              "BŁĄD EBM: Zła dawka! Po 5. wyładowaniu podajemy 150 mg (podałeś $dose).",
            );
          }
        }
      }
    } else {
      _logEvent("INFO: Podałeś lek: $drugName $dose.");
    }

    notifyListeners();
  }

  void _validateAdrenalineTiming(int currentTime) {
    if (state.lastAdrenalineTime > 0) {
      int diffSeconds = currentTime - state.lastAdrenalineTime;
      if (diffSeconds < 180) {
        // Mniej niż 3 minuty
        _logEvent(
          "BŁĄD EBM: Adrenalinę podajemy co 3-5 minut! Podałeś za wcześnie (odstęp: $diffSeconds s). Zwiększasz zapotrzebowanie serca na tlen!",
        );
      } else if (diffSeconds > 300) {
        // Więcej niż 5 minut
        _logEvent(
          "OSTRZEŻENIE EBM: Przekroczono okno podaży Adrenaliny! Odstęp wyniósł $diffSeconds s.",
        );
        state.lastAdrenalineTime = currentTime;
      } else {
        _logEvent(
          "SUKCES: Adrenalina 1 mg podana w idealnym oknie czasowym (odstęp: $diffSeconds s).",
        );
        state.lastAdrenalineTime = currentTime;
      }
    } else {
      _logEvent("SUKCES: Pierwsza dawka Adrenaliny (1 mg) podana prawidłowo.");
      state.lastAdrenalineTime = currentTime;
    }
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
    if (flow > 0 && flow < 15) {
      _logEvent(
        "BŁĄD EBM: Przepływ $flow l/min! W NZK do wentylacji BVM wymagane jest min. 15 l/min (100% O2)!",
      );
    } else if (flow >= 15) {
      _logEvent("SUKCES: Ustawiono właściwy przepływ O2: $flow l/min.");
    } else {
      _logEvent("INFO: Zakręcono przepływ tlenu.");
    }
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
    if (state.airwayStatus == AirwayType.endotracheal) {
      _logEvent("INFO: Pacjent jest już zaintubowany (ETI). Ignoruję I-gel.");
      return;
    }

    int expectedSize = 4;
    if (state.patient.weight > 90) expectedSize = 5;
    if (state.patient.weight < 50) expectedSize = 3;

    if (size != expectedSize) {
      // KARA: Narzędzie nie zostało poprawnie założone!
      _logEvent(
        "KRYTYCZNY BŁĄD EBM: Próba założenia I-gel #$size u pacjenta o wadze ${state.patient.weight.toStringAsFixed(0)} kg! Narzędzie jest niedopasowane. Próba nieudana.",
      );
      return;
    }

    state.airwayStatus = AirwayType.igel;
    _logEvent(
      "SUKCES: Założono I-gel w rozmiarze $size. Prawidłowo dobrany do wagi.",
    );
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
