import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import '../models/als_state.dart';

class GameEngine extends ChangeNotifier {
  AlsScenarioState state = AlsScenarioState();
  Timer? _globalTimer;

  GameEngine() {
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
        // Co 10 sekund bierności system bezlitośnie krzyczy:
        if (state.cprInactiveSeconds % 10 == 0) {
          _logEvent(
            "KRYTYCZNY BŁĄD EBM: Ręce oderwane od klatki już od ${state.cprInactiveSeconds} sekund! Mózg pacjenta umiera (hands-off time)!",
          );
        }
      } else {
        state.cprInactiveSeconds = 0; // Resetujemy, gdy tylko RKO wraca
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

      // KONIEC GRY
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

    // NOWE: Sprawdzanie, czy małpa nie zatrzymała RKO za wcześnie
    if (state.cprSecondsRemaining > 10) {
      _logEvent(
        "KRYTYCZNY BŁĄD EBM: Przerywasz RKO za wcześnie! Do końca cyklu zostało ${state.cprSecondsRemaining}s. Zabijasz ciśnienie perfuzji wieńcowej!",
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

    // NOWA WALIDACJA (EBM ERC 2021/2025):
    // Strzał jest prawidłowy w czasie, jeśli:
    // 1. To pierwsza defibrylacja (strzelamy jak najszybciej).
    // 2. RKO nie jest aktywne (np. strzał w trakcie pauzy na ocenę - choć lepiej ładować w trakcie RKO).
    // 3. RKO dopiero co wystartowało (zostało > 110s), co symuluje ładowanie w trakcie uciśnięć (pre-charging).
    bool isValidShockTiming =
        isFirstShock ||
        !state.isCprActive ||
        (state.isCprActive && state.cprSecondsRemaining > 110);

    if (!isValidShockTiming) {
      _logEvent(
        "KRYTYCZNY BŁĄD EBM: Wyładowanie w połowie cyklu! Zostało ${state.cprSecondsRemaining}s RKO. Przerywasz masaż bez powodu. Strzał powinien nastąpić na początku pętli po ocenie rytmu!",
      );
    } else if (isFirstShock) {
      _logEvent(
        "INFO EBM: Wczesna defibrylacja (Early Defibrillation). Szybki pierwszy strzał ratuje życie!",
      );
    }

    if (_isShockable(state.monitorRhythm)) {
      if (state.shocksDelivered > 0 &&
          state.chargedEnergy <= state.lastShockEnergy &&
          state.chargedEnergy < 360) {
        _logEvent(
          "OSTRZEŻENIE EBM: Brak eskalacji energii! Poprzednio było ${state.lastShockEnergy}J. ERC zaleca eskalację (np. 150->200->300->360J).",
        );
      }

      state.shocksDelivered++;
      state.lastShockEnergy = state.chargedEnergy;
      _logEvent(
        "SUKCES: Defibrylacja nr ${state.shocksDelivered} energią ${state.chargedEnergy}J dostarczona.",
      );

      // EBM: Bezpośrednio po wyładowaniu ZAWSZE wznawiamy uciśnięcia na kolejne 2 minuty!
      state.isCprActive = true;
      state.cprSecondsRemaining = 120;
      state.currentPhase = ResuscitationPhase.cprCycle;
      _logEvent(
        "AKCJA AUTO: Automatyczny powrót do 2-minutowej pętli RKO po wyładowaniu.",
      );
    } else {
      _logEvent(
        "KRYTYCZNY BŁĄD: Wyładowanie ${state.chargedEnergy}J w rytmie ${state.monitorRhythm.name.toUpperCase()}! To wbrew algorytmowi.",
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

    if (!state.isCprActive) {
      _logEvent(
        "OSTRZEŻENIE: Leki podajemy w trakcie RKO, aby minimalizować przerwy w uciśnięciach.",
      );
    }

    int currentTime = state.totalElapsedGameTime;

    if (drugName == "Adrenalina") {
      if (dose != "1 mg") {
        _logEvent(
          "BŁĄD KRYTYCZNY: Podałeś $drugName w dawce $dose w NZK! Obowiązuje dawka 1 mg.",
        );
      } else {
        if (_isShockable(state.monitorRhythm)) {
          if (state.shocksDelivered < 3) {
            _logEvent(
              "BŁĄD EBM: W rytmach VF/pVT Adrenalinę 1 mg podajemy dopiero PO 3. wyładowaniu!",
            );
          } else {
            _logEvent(
              "SUKCES: Podano Adrenalinę 1 mg we właściwej fazie (po ${state.shocksDelivered}. wyładowaniu).",
            );
            _validateDrugTiming(
              "Adrenalina",
              currentTime,
              state.lastAdrenalineTime,
            );
            state.lastAdrenalineTime = currentTime;
          }
        } else {
          _logEvent("SUKCES: Podano Adrenalinę 1 mg w asystolii/PEA.");
          _validateDrugTiming(
            "Adrenalina",
            currentTime,
            state.lastAdrenalineTime,
          );
          state.lastAdrenalineTime = currentTime;
        }
      }
    } else if (drugName == "Amiodaron") {
      if (dose == "300 mg") {
        if (_isShockable(state.monitorRhythm) && state.shocksDelivered == 3) {
          _logEvent("SUKCES: Podano Amiodaron 300 mg po 3. wyładowaniu.");
          state.lastAmiodaroneTime = currentTime;
        } else {
          _logEvent(
            "BŁĄD EBM: Amiodaron 300 mg podajemy po 3. wyładowaniu w VF/pVT. Ty masz za sobą ${state.shocksDelivered}.",
          );
        }
      } else if (dose == "150 mg") {
        if (_isShockable(state.monitorRhythm) && state.shocksDelivered == 5) {
          _logEvent("SUKCES: Podano Amiodaron 150 mg po 5. wyładowaniu.");
        } else {
          _logEvent(
            "BŁĄD EBM: Amiodaron 150 mg należy się pacjentowi po 5. defibrylacji.",
          );
        }
      } else {
        _logEvent(
          "BŁĄD KRYTYCZNY: Nieprawidłowa dawka Amiodaronu w NZK ($dose)!",
        );
      }
    } else if (drugName == "Morfina" ||
        drugName == "Fentanyl" ||
        drugName == "Relanium") {
      _logEvent(
        "BŁĄD KRYTYCZNY: Podajesz pacjentowi w NZK $drugName?! Zero EBM!",
      );
    } else {
      _logEvent("INFO: Podałeś $drugName $dose. Oceniono w kontekście (4H4T).");
    }

    state.preparedDrugs.removeAt(index);
    notifyListeners();
  }

  void _validateDrugTiming(String drug, int currentTime, int lastTime) {
    if (lastTime > 0 && (currentTime - lastTime) < 170) {
      _logEvent(
        "BŁĄD ZBYT WCZESNEJ PODAŻY: $drug podany za wcześnie! (wymagany odstęp ok. 3-5 minut).",
      );
    } else if (lastTime > 0) {
      _logEvent(
        "SUKCES: Kolejna dawka leku $drug z zachowaniem odpowiedniego odstępu.",
      );
    }
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
