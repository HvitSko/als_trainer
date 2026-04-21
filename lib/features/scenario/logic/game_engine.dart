import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import '../models/als_state.dart';

class GameEngine extends ChangeNotifier {
  AlsScenarioState state = AlsScenarioState();
  Timer? _globalTimer;

  void startScenario() async {
    state.currentPhase = ResuscitationPhase.analyzing;
    state.monitorRhythm = PatientRhythm.unknown;
    _startTimers();
    notifyListeners();

    // Czekamy 3 sekundy na analizę przez LifePak
    await Future.delayed(const Duration(seconds: 3));

    final rhythms = [
      PatientRhythm.vf,
      PatientRhythm.pvt,
      PatientRhythm.asystole,
      PatientRhythm.pea,
    ];
    state.monitorRhythm = rhythms[Random().nextInt(rhythms.length)];

    state.currentPhase = ResuscitationPhase.rhythmCheck;
    notifyListeners();
  }

  void _startTimers() {
    _globalTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      state.totalElapsedGameTime++;

      // Zegarek RKO tyka TYLKO wtedy, gdy pacjent jest aktywnie uciskany
      if (state.isCprActive) {
        if (state.cprSecondsRemaining > 0) {
          state.cprSecondsRemaining--;
        } else {
          // Po 2 minutach uciśnięć - koniec pętli, czas na reocenę
          state.isCprActive = false;
          state.currentPhase = ResuscitationPhase.rhythmCheck;
        }
      }

      // Koniec scenariusza po 10 minutach (600 s)
      if (state.totalElapsedGameTime >= 600) {
        timer.cancel();
        state.currentPhase = ResuscitationPhase.postResuscitation;
        state.isCprActive = false;
      }

      notifyListeners();
    });
  }

  void deliverShock() {
    if (!state.isDefibCharged) return;

    state.shocksDelivered++;
    state.isDefibCharged = false;

    // Sprawdzamy czy strzał był uzasadniony EBM
    bool isShockable =
        (state.monitorRhythm == PatientRhythm.vf ||
        state.monitorRhythm == PatientRhythm.pvt);
    if (!isShockable) {
      state.log = [
        ...state.log,
        "BŁĄD: Defibrylacja w rytmie nie do wyładowania!",
      ];
    } else {
      state.log = [...state.log, "SUKCES: Poprawna defibrylacja."];
    }

    notifyListeners();
  }

  void startCpr() {
    state.isCprActive = true;
    state.cprSecondsRemaining = 120;
    state.currentPhase = ResuscitationPhase.cprCycle;
    notifyListeners();
  }

  void chargeDefibrillator() {
    state.isDefibCharged = true;
    notifyListeners();
  }

  Future<void> prepareDrug(String drugName, String dose) async {
    if (state.preparedDrugs.length >= 2) return;

    state.isPreparingDrug = true;
    state.preparedDrugs = [
      ...state.preparedDrugs,
      "Przygotowywanie: $drugName...",
    ];
    notifyListeners();

    await Future.delayed(const Duration(seconds: 4));

    List<String> updatedList = List.from(state.preparedDrugs);
    updatedList.removeLast();
    updatedList.add("$drugName $dose");

    state.preparedDrugs = updatedList;
    state.isPreparingDrug = false;
    notifyListeners();
  }

  void administerDrug(int index) {
    if (index < state.preparedDrugs.length) {
      print("Podano lek: ${state.preparedDrugs[index]}");
      List<String> updatedList = List.from(state.preparedDrugs);
      updatedList.removeAt(index);
      state.preparedDrugs = updatedList;
      notifyListeners();
    }
  }

  @override
  void dispose() {
    _globalTimer?.cancel();
    super.dispose();
  }
}
