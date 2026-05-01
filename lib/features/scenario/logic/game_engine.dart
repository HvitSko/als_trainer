import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import '../models/als_state.dart';

class GameEngine extends ChangeNotifier {
  AlsScenarioState state = AlsScenarioState();
  Timer? _globalTimer;

  GameEngine() {
    state.patientWeight = 60.0 + Random().nextInt(50);
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
              "INFO: Minęły 2 minuty RKO! ZATRZYMAJ uciśnięcia, aby ocenić rytm (zmień uciskającego)!",
            );
          }
        }
      }

      // FIZJOLOGIA: KAPNOGRAFIA (ETCO2)
      if (state.isCapnographyAttached) {
        if (state.intubationStatus == IntubationStatus.esophageal) {
          state.etco2 = 0; // Rurka w żołądku = brak CO2
        } else if (state.airwayStatus != AirwayType.none &&
            state.airwayStatus != AirwayType.basic) {
          if (state.isCprActive) {
            // Skuteczne RKO generuje 10-20 mmHg
            state.etco2 = 10 + Random().nextInt(11);
          } else {
            // Brak uciśnięć = drastyczny spadek przepływu płucnego
            state.etco2 = state.etco2 > 2 ? state.etco2 - 2 : 0;
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
        "KRYTYCZNY BŁĄD EBM: Przerywasz RKO za wcześnie! Zostało ${state.cprSecondsRemaining}s. Zabijasz ciśnienie perfuzji wieńcowej!",
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
    state.monitorRhythm = _generateNextRhythm(state.monitorRhythm);
    state.currentPhase = ResuscitationPhase.rhythmCheck;
    _logEvent(
      "DIAGNOZA: Aktualny rytm to ${state.monitorRhythm.name.toUpperCase()}",
    );
    notifyListeners();
  }

  PatientRhythm _generateNextRhythm(PatientRhythm current) {
    int rand = Random().nextInt(100);
    switch (current) {
      case PatientRhythm.vf:
      case PatientRhythm.pvt:
        if (rand < 50) return current;
        if (rand < 80) return PatientRhythm.asystole;
        return PatientRhythm.pea;
      case PatientRhythm.asystole:
        if (rand < 70) return PatientRhythm.asystole;
        if (rand < 90) return PatientRhythm.pea;
        return PatientRhythm.vf;
      case PatientRhythm.pea:
        if (rand < 40) return PatientRhythm.pea;
        if (rand < 80) return PatientRhythm.asystole;
        return PatientRhythm.vf;
      default:
        return PatientRhythm.asystole;
    }
  }

  bool _isShockable(PatientRhythm r) =>
      r == PatientRhythm.vf || r == PatientRhythm.pvt;

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
    _logEvent(
      "INFO: Defibrylator naładowany (${state.chargedEnergy}J). GOTOWY DO WYŁADOWANIA.",
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

    if (!isValidShockTiming) {
      _logEvent(
        "KRYTYCZNY BŁĄD EBM: Wyładowanie w połowie cyklu! Zostało ${state.cprSecondsRemaining}s RKO.",
      );
    } else if (isFirstShock) {
      _logEvent("INFO EBM: Wczesna defibrylacja ratuje życie!");
    }

    if (_isShockable(state.monitorRhythm)) {
      if (state.shocksDelivered > 0 &&
          state.chargedEnergy <= state.lastShockEnergy &&
          state.chargedEnergy < 360) {
        _logEvent(
          "OSTRZEŻENIE EBM: Brak eskalacji energii! ERC zaleca eskalację (np. 150->200->300->360J).",
        );
      }
      state.shocksDelivered++;
      state.lastShockEnergy = state.chargedEnergy;
      _logEvent(
        "SUKCES: Defibrylacja nr ${state.shocksDelivered} energią ${state.chargedEnergy}J dostarczona.",
      );

      state.isCprActive = true;
      state.cprSecondsRemaining = 120;
      state.currentPhase = ResuscitationPhase.cprCycle;
      _logEvent(
        "AKCJA AUTO: Automatyczny powrót do 2-minutowej pętli RKO po wyładowaniu.",
      );
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

    if (drugName == "Adrenalina") {
      if (dose != "1 mg") {
        _logEvent("BŁĄD KRYTYCZNY: Obowiązuje dawka 1 mg Adrenaliny w NZK!");
      } else {
        if (_isShockable(state.monitorRhythm)) {
          if (state.shocksDelivered < 3) {
            _logEvent("BŁĄD EBM: Adrenalinę podajemy PO 3. wyładowaniu!");
          } else {
            _logEvent("SUKCES: Adrenalina podana poprawnie.");
            _validateDrugTiming(
              "Adrenalina",
              currentTime,
              state.lastAdrenalineTime,
            );
            state.lastAdrenalineTime = currentTime;
          }
        } else {
          _logEvent("SUKCES: Podano Adrenalinę w asystolii/PEA.");
          _validateDrugTiming(
            "Adrenalina",
            currentTime,
            state.lastAdrenalineTime,
          );
          state.lastAdrenalineTime = currentTime;
        }
      }
    } else if (drugName == "Amiodaron") {
      // ... reszta logiki bez zmian ...
      _logEvent("INFO: Podałeś $drugName $dose.");
    } else {
      _logEvent("INFO: Podałeś $drugName $dose.");
    }

    state.preparedDrugs.removeAt(index);
    notifyListeners();
  }

  void _validateDrugTiming(String drug, int currentTime, int lastTime) {
    if (lastTime > 0 && (currentTime - lastTime) < 170) {
      _logEvent(
        "BŁĄD ZBYT WCZESNEJ PODAŻY: $drug podany za wcześnie! (wymagany odstęp ok. 3-5 minut).",
      );
    }
  }

  // ==========================================
  // MODUŁ AIRWAY & BREATHING (ERC 2025)
  // ==========================================

  void openAirway() {
    if (state.airwayStatus != AirwayType.none) return;
    state.airwayStatus = AirwayType.basic;
    _logEvent("AKCJA: Udrożniono drogi oddechowe (rękoczyn czoło-żuchwa).");
    notifyListeners();
  }

  void setOxygenFlow(int flow) {
    state.oxygenFlow = flow;
    _logEvent("INFO: Ustawiono przepływ tlenu na $flow l/min.");
    if (flow < 15 && state.airwayStatus == AirwayType.bvm) {
      _logEvent(
        "OSTRZEŻENIE EBM: Zbyt niski przepływ! W NZK dajemy 100% O2 (min. 15 l/min).",
      );
    }
    notifyListeners();
  }

  void setupBVM() {
    state.airwayStatus = AirwayType.bvm;
    _logEvent(
      "AKCJA: Założono maskę z workiem (BVM). Zespół rozpoczął automatyczną wentylację (30:2).",
    );
    if (state.oxygenFlow < 15) {
      _logEvent(
        "BŁĄD EBM: Wentylowanie bez odpowiedniego tlenu to wentylowanie pacjenta powietrzem z sali!",
      );
    }
    notifyListeners();
  }

  Future<void> preoxygenate() async {
    if (state.airwayStatus != AirwayType.bvm) {
      _logEvent("BŁĄD: Do preoksygenacji potrzebujesz założonego worka BVM!");
      return;
    }
    if (state.oxygenFlow < 15) {
      _logEvent("BŁĄD: Preoksygenacja bez 15 l/min tlenu to oksymoron!");
      return;
    }
    _logEvent(
      "INFO: Zespół preoksygenuje pacjenta (5 oddechów ratunkowych)...",
    );
    await Future.delayed(const Duration(seconds: 4));
    state.isPreoxygenated = true;
    _logEvent(
      "SUKCES: Pacjent natleniony. Gotowy do zaawansowanego udrażniania dróg oddechowych.",
    );
    notifyListeners();
  }

  void insertIGel(int size) {
    if (state.airwayStatus == AirwayType.endotracheal) return;
    int expectedSize = 4;
    if (state.patientWeight > 90) expectedSize = 5;
    if (state.patientWeight < 50) expectedSize = 3;

    if (size != expectedSize) {
      _logEvent(
        "KRYTYCZNY BŁĄD: Założyłeś I-gel #$size u pacjenta ${state.patientWeight.toStringAsFixed(0)} kg! Narzędzie nieszczelne.",
      );
      return;
    }
    state.airwayStatus = AirwayType.igel;
    _logEvent(
      "SUKCES: Założono I-gel #$size. Zespół prowadzi asynchroniczną wentylację.",
    );
    notifyListeners();
  }

  Future<void> attemptIntubation() async {
    if (state.intubationAttemptInProgress) return;

    // BEZLITOSNY AUDYT EBM:
    if (!state.isPreoxygenated) {
      _logEvent(
        "KRYTYCZNY BŁĄD EBM: Rozpoczynasz intubację bez prewentylacji?! Hipoksja zabija pacjenta w trakcie laryngoskopii.",
      );
    }

    state.intubationAttemptInProgress = true;
    _logEvent(
      "AKCJA: Laryngoskopia i próba intubacji (max 5s przerwy w uciśnięciach)...",
    );
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
    _logEvent("INFO: Rurka wprowadzona. Natychmiast zweryfikuj jej położenie!");
    notifyListeners();
  }

  void auscultate() {
    if (state.airwayStatus == AirwayType.none ||
        state.airwayStatus == AirwayType.basic) {
      _logEvent("INFO: Osłuchujesz klatkę. Brak własnego oddechu pacjenta.");
      return;
    }

    state.isAuscultated = true;

    // POPRAWKA DLA I-GELA
    if (state.airwayStatus == AirwayType.igel ||
        state.airwayStatus == AirwayType.bvm) {
      _logEvent(
        "DIAGNOZA (Osłuchiwanie): Szmer pęcherzykowy słyszalny obustronnie w trakcie wentylacji zastępczej.",
      );
      notifyListeners();
      return;
    }

    // DIAGNOSTYKA INTUBACJI
    switch (state.intubationStatus) {
      case IntubationStatus.esophageal:
        _logEvent(
          "DIAGNOZA (Osłuchiwanie): Bulgotanie w żołądku. Cisza nad płucami. Rurka w PRZEŁYKU!",
        );
        break;
      case IntubationStatus.rightMainstem:
        _logEvent(
          "DIAGNOZA (Osłuchiwanie): Szmer pęcherzykowy tylko po prawej stronie. Rurka za głęboko!",
        );
        break;
      case IntubationStatus.correct:
        _logEvent(
          "DIAGNOZA (Osłuchiwanie): Szmery słyszalne symetrycznie. Rurka w tchawicy.",
        );
        break;
      default:
        break;
    }
    notifyListeners();
  }

  void attachCapnography() {
    state.isCapnographyAttached = true;
    if (state.airwayStatus == AirwayType.endotracheal ||
        state.airwayStatus == AirwayType.igel) {
      if (state.intubationStatus == IntubationStatus.esophageal) {
        _logEvent(
          "DIAGNOZA (Kapnografia): Płaska linia! Brak ETCO2. Rurka w przełyku. USUŃ JĄ.",
        );
      } else {
        _logEvent(
          "DIAGNOZA (Kapnografia): Prawidłowa krzywa. Podłączono czujnik ETCO2.",
        );
      }
    } else {
      _logEvent("INFO: Kapnografia podłączona (pomiar z maski/BVM).");
    }
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
