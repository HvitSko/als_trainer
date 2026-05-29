import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import '../models/als_state.dart';
import '../models/scenario_model.dart';
import '../models/patient_model.dart';
import '../../../app_localization.dart'; // IMPORT TŁUMACZA

class GameEngine extends ChangeNotifier {
  AlsScenarioState state = AlsScenarioState();
  Timer? _globalTimer;

  GameEngine(Scenario scenario, GameMode mode) {
    state.patient = scenario.generatePatient();
    state.monitorRhythm = scenario.initialRhythm;
    state.mode = mode; // ZAPISUJEMY TRYB!
    _startGlobalTimer();
  }

  void _startGlobalTimer() {
    _globalTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      state.totalElapsedGameTime++;
      // AUDYT WENTYLACJI
      bool isProperlyVentilated =
          (state.airwayStatus != AirwayType.none && state.oxygenFlow >= 15);
      if (!isProperlyVentilated && !state.patient.hasPulse) {
        state.secondsWithoutVentilation++;
        if (state.secondsWithoutVentilation > 30 &&
            !state.airwayNeglectFlagged) {
          _logEvent(
            AppLoc.tr(
              "KRYTYCZNY BŁĄD EBM: Pacjent bez skutecznej wentylacji (O2 + drogi) od ponad 30s! Mózg umiera.",
              "EBM CRITICAL ERROR: Patient without effective ventilation (O2 + airway) for over 30s! Brain is dying.",
            ),
            isError: true,
          );
          state.instructorFeedback.add(
            AppLoc.tr(
              "KRYTYCZNE: Dopuściłeś do głębokiego niedotlenienia. Przez ponad 30 sekund nie prowadziłeś tlenoterapii (min. 15l/min) i udrożnienia dróg.",
              "CRITICAL: You allowed severe hypoxia. For over 30 seconds you did not provide oxygen therapy (min. 15 L/min) and airway management.",
            ),
          );
          state.airwayNeglectFlagged = true;
        }
      } else {
        state.secondsWithoutVentilation =
            0; // Resetujemy, gdy pacjent dostaje tlen
      }

      // LOGIKA ODSTĘPÓW (HANDS-OFF TIME)
      if (!state.isCprActive &&
          state.currentPhase != ResuscitationPhase.assessmentABCDE &&
          state.currentPhase != ResuscitationPhase.postResuscitation) {
        state.cprInactiveSeconds++;
        if (state.cprInactiveSeconds % 10 == 0) {
          _logEvent(
            AppLoc.tr(
              "KRYTYCZNY BŁĄD EBM: Ręce oderwane od klatki już od ${state.cprInactiveSeconds} sekund! Mózg pacjenta umiera!",
              "EBM CRITICAL ERROR: Hands off the chest for ${state.cprInactiveSeconds} seconds! Patient's brain is dying!",
            ),
          );
        }
      } else {
        state.cprInactiveSeconds = 0;
      }

      // LOGIKA PĘTLI RKO
      if (state.isCprActive) {
        state.totalCprSeconds++; // ŚLEDZIMY CZAS Uciśnięć (Do CPR Fraction)
        if (state.cprSecondsRemaining > 0) {
          state.cprSecondsRemaining--;
        }

        if (state.cprSecondsRemaining == 0) {
          if (state.totalElapsedGameTime % 15 == 0) {
            _logEvent(
              AppLoc.tr(
                "OSTRZEŻENIE: Czas cyklu RKO minął! ZATRZYMAJ uciśnięcia, aby ocenić rytm!",
                "WARNING: CPR cycle time is up! STOP compressions to assess the rhythm!",
              ),
              isError: true,
            );
          }
        }
      }

      // FIZJOLOGIA: KAPNOGRAFIA (ETCO2)
      if (state.isCapnographyAttached) {
        if (state.intubationStatus == IntubationStatus.esophageal) {
          state.patient.etCo2 = 0;
        } else if (state.airwayStatus != AirwayType.none &&
            state.airwayStatus != AirwayType.basic) {
          if (state.isCprActive) {
            if (state.patient.hiddenCause ==
                    ReversibleCause.tensionPneumothorax ||
                state.patient.hiddenCause == ReversibleCause.thrombosis ||
                state.patient.hiddenCause == ReversibleCause.tamponade) {
              state.patient.etCo2 = 4 + Random().nextInt(6);
            } else if (state.oxygenFlow < 15) {
              state.patient.etCo2 = 5 + Random().nextInt(6);
            } else {
              state.patient.etCo2 = 12 + Random().nextInt(11);
            }
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
        _logEvent(
          AppLoc.tr(
            "KONIEC SCENARIUSZA: Osiągnięto limit 10 minut.",
            "END OF SCENARIO: 10-minute limit reached.",
          ),
        );
      }

      notifyListeners();
    });
  }

  Future<void> connectMonitor() async {
    if (state.currentPhase != ResuscitationPhase.assessmentABCDE) return;

    state.currentPhase = ResuscitationPhase.analyzing;
    _logEvent(
      AppLoc.tr(
        "INFO: Zespół nakleja elektrody na klatkę. Trwa analiza rytmu...",
        "INFO: Team applying chest pads. Rhythm analysis in progress...",
      ),
    );
    notifyListeners();

    await Future.delayed(const Duration(seconds: 3));

    state.currentPhase = ResuscitationPhase.rhythmCheck;
    _logEvent(
      AppLoc.tr(
        "DIAGNOZA: Wykryto ${state.monitorRhythm.name.toUpperCase()} na monitorze.",
        "DIAGNOSIS: ${state.monitorRhythm.name.toUpperCase()} detected on the monitor.",
      ),
    );
    notifyListeners();
  }

  void toggleMonitor() {
    state.isMonitorOn = !state.isMonitorOn;
    if (state.isMonitorOn &&
        state.currentPhase == ResuscitationPhase.assessmentABCDE) {
      connectMonitor();
    } else if (!state.isMonitorOn) {
      _logEvent(
        AppLoc.tr(
          "INFO: Kardiomonitor został wyłączony.",
          "INFO: Cardiac monitor has been turned off.",
        ),
      );
    }
    notifyListeners();
  }

  void setEcgGain(double gain) {
    if (!state.isMonitorOn) return;
    state.ecgGain = gain;

    if (state.monitorRhythm == PatientRhythm.asystole && gain >= 2.0) {
      state.isAsystoleConfirmed = true;
      _logEvent(
        AppLoc.tr(
          "SUKCES EBM: Zwiększono cechę zapisu do x$gain. Wykluczono niskonapięciowe migotanie komór (fine VF).",
          "EBM SUCCESS: ECG gain increased to x$gain. Fine ventricular fibrillation (fine VF) ruled out.",
        ),
      );
    } else {
      _logEvent(
        AppLoc.tr(
          "INFO: Zmieniono cechę wzmocnienia EKG na x$gain.",
          "INFO: ECG gain changed to x$gain.",
        ),
      );
    }
    notifyListeners();
  }

  void togglePacer() {
    if (!state.isMonitorOn) return;
    _logEvent(
      AppLoc.tr(
        "INFO: Włączono tryb stymulatora zewnętrznego (PACER).",
        "INFO: Transcutaneous pacing mode (PACER) activated.",
      ),
    );
    notifyListeners();
  }

  void stopCprAndAssess() async {
    if (!state.isCprActive) return;
    state.isCprActive = false;
    state.cprCyclesCompleted++;
    state.currentPhase = ResuscitationPhase.analyzing;

    if (state.isMonitorOn) {
      _logEvent(
        AppLoc.tr(
          "AKCJA: RKO zatrzymane. Analiza EKG...",
          "ACTION: CPR paused. ECG analysis...",
        ),
      );
    } else {
      _logEvent(
        AppLoc.tr(
          "AKCJA: RKO zatrzymane. Kardiomonitor jest wyłączony - brak możliwości oceny rytmu!",
          "ACTION: CPR paused. Cardiac monitor is OFF - unable to assess rhythm!",
        ),
      );
    }

    notifyListeners();
    await Future.delayed(const Duration(seconds: 3));

    String causeKey = _mapCauseToKey(state.patient.hiddenCause);
    bool isCauseResolved = causeKey.isEmpty
        ? true
        : state.h4tStatus[causeKey] == 1;

    // NOWE: Czy gracz zgadł, jaka jest ukryta przyczyna pacjenta?
    bool isDominantCauseCorrectlyIdentified =
        (state.identifiedDominantCause == causeKey) && causeKey.isNotEmpty;

    bool isAlsCareProvided =
        state.airwayStatus != AirwayType.none ||
        state.shocksDelivered > 0 ||
        state.administeredDrugs.isNotEmpty;

    int roscChance = 0;
    if (!isAlsCareProvided) {
      roscChance = 0;
    } else if (state.patient.hiddenCause == ReversibleCause.none) {
      roscChance = 25;
    } else {
      // EBM MAGIA: Jeśli przyczyna jest wyleczona LUB została bezbłędnie wskazana jako dominująca (np. Tamponada)
      roscChance = (isCauseResolved || isDominantCauseCorrectlyIdentified)
          ? 70
          : 0;
    }

    roscChance -= (state.criticalErrorsCount * 10);
    if (roscChance < 0) roscChance = 0;

    if (state.cprCyclesCompleted >= 2 && Random().nextInt(100) < roscChance) {
      state.monitorRhythm = PatientRhythm.pea;
      state.patient.hasPulse = true;
      state.currentPhase = ResuscitationPhase.postResuscitation;
      _logEvent(
        AppLoc.tr(
          "SUKCES: Wykryto powrót fali tętna! ROSC! Zatrzymanie scenariusza.",
          "SUCCESS: Return of spontaneous circulation detected! ROSC! Scenario paused.",
        ),
      );

      if (state.patient.hiddenCause == ReversibleCause.none ||
          state.patient.hiddenCause == ReversibleCause.thrombosis) {
        state.instructorFeedback.add(
          AppLoc.tr(
            "SUKCES: Prowadziłeś interwencję zgodnie z wytycznymi ALS. Poprawnie przeanalizowałeś i wykluczyłeś/zabezpieczyłeś odwracalne przyczyny zatrzymania krążenia (4H4T)",
            "SUCCESS: Intervention conducted according to ALS guidelines. Reversible causes of cardiac arrest (4H4T) correctly analyzed and ruled out/secured.",
          ),
        );
      } else {
        state.instructorFeedback.add(
          AppLoc.tr(
            "SUKCES: Poprawnie zdiagnozowałeś główną przyczynę ($causeKey)",
            "SUCCESS: Correctly diagnosed the primary cause ($causeKey).",
          ),
        );
      }

      notifyListeners();
      return;
    }

    int rand = Random().nextInt(100);
    if (rand < 20) {
      state.monitorRhythm = state.monitorRhythm == PatientRhythm.vf
          ? PatientRhythm.asystole
          : PatientRhythm.vf;
    }

    state.currentPhase = ResuscitationPhase.rhythmCheck;

    if (state.isMonitorOn) {
      _logEvent(
        AppLoc.tr(
          "DIAGNOZA: Aktualny rytm to ${state.monitorRhythm.name.toUpperCase()}",
          "DIAGNOSIS: Current rhythm is ${state.monitorRhythm.name.toUpperCase()}.",
        ),
      );
    }
    notifyListeners();
  }

  void startCpr() {
    int lastAnalysisIndex = state.auditLog.indexWhere(
      (log) => log.contains(AppLoc.tr("Analiza EKG", "ECG analysis")),
    );
    if (lastAnalysisIndex == -1) lastAnalysisIndex = state.auditLog.length;

    bool pulseCheckedRecently = state.auditLog
        .sublist(0, lastAnalysisIndex)
        .any(
          (log) =>
              log.contains(AppLoc.tr("Palec - Szyja", "Finger - Neck")) ||
              log.contains(AppLoc.tr("Palec - Nadgarstek", "Finger - Wrist")),
        );

    // NOWE: Czy tętno było zbadane kiedykolwiek (na starcie)?
    bool pulseCheckedEver = state.auditLog.any(
      (log) =>
          log.contains(AppLoc.tr("Palec - Szyja", "Finger - Neck")) ||
          log.contains(AppLoc.tr("Palec - Nadgarstek", "Finger - Wrist")),
    );

    // Błąd wystąpi w 1szym cyklu tylko jeśli NIGDY nie sprawdził tętna
    if (state.totalCprSeconds == 0 && !pulseCheckedEver) {
      state.criticalErrorsCount++;
      _logEvent(
        AppLoc.tr(
          "BŁĄD KRYTYCZNY EBM: Rozpoczęto RKO bez uprzedniego zbadania tętna na dużej tętnicy (Szyja)!",
          "EBM CRITICAL ERROR: Commenced CPR without prior pulse check on a major artery (Neck)!",
        ),
        isError: true,
      );
    } else if (state.totalCprSeconds > 0 &&
        (state.monitorRhythm == PatientRhythm.pea ||
            state.monitorRhythm == PatientRhythm.pvt) &&
        !pulseCheckedRecently) {
      state.criticalErrorsCount++;
      _logEvent(
        AppLoc.tr(
          "BŁĄD KRYTYCZNY EBM: Powrót do RKO przy rytmie zorganizowanym (PEA/VT) bez uprzedniego sprawdzenia tętna Palcem!",
          "EBM CRITICAL ERROR: Resumed CPR in an organized rhythm (PEA/VT) without prior manual pulse check!",
        ),
        isError: true,
      );
    }

    state.isCprActive = true;
    state.cprSecondsRemaining = 120;
    state.currentPhase = ResuscitationPhase.cprCycle;
    _logEvent(
      AppLoc.tr(
        "AKCJA: Rozpoczęto uciśnięcia klatki piersiowej (2 minuty).",
        "ACTION: Commenced chest compressions (2 minutes).",
      ),
    );
    notifyListeners();
  }

  void setEnergy(int energy) {
    state.selectedEnergy = energy;
    notifyListeners();
  }

  Future<void> chargeDefibrillator() async {
    if (state.isDefibCharged || state.isDefibCharging) return;
    state.isDefibCharging = true;
    _logEvent(
      AppLoc.tr(
        "INFO: Ładowanie do ${state.selectedEnergy}J...",
        "INFO: Charging to ${state.selectedEnergy}J...",
      ),
    );
    notifyListeners();
    await Future.delayed(const Duration(seconds: 4));
    state.isDefibCharging = false;
    state.isDefibCharged = true;
    state.chargedEnergy = state.selectedEnergy;
    _logEvent(
      AppLoc.tr(
        "INFO: Defibrylator naładowany (${state.chargedEnergy}J).",
        "INFO: Defibrillator fully charged (${state.chargedEnergy}J).",
      ),
    );
    notifyListeners();
  }

  void disarmDefibrillator() {
    if (!state.isDefibCharged) return;
    state.isDefibCharged = false;
    state.chargedEnergy = 0;
    _logEvent(
      AppLoc.tr(
        "AKCJA: Defibrylator bezpiecznie rozładowany (Internal Discharge).",
        "ACTION: Defibrillator safely disarmed (Internal Discharge).",
      ),
    );
    notifyListeners();
  }

  void deliverShock() {
    if (!state.isMonitorOn || !state.isDefibCharged) return;

    int shockEnergy = state.selectedEnergy;

    int lastAnalysisIndex = state.auditLog.indexWhere(
      (log) => log.contains(AppLoc.tr("Analiza EKG", "ECG analysis")),
    );
    if (lastAnalysisIndex == -1) lastAnalysisIndex = state.auditLog.length;

    bool pulseCheckedRecently = state.auditLog
        .sublist(0, lastAnalysisIndex)
        .any(
          (log) =>
              log.contains(AppLoc.tr("Palec - Szyja", "Finger - Neck")) ||
              log.contains(AppLoc.tr("Palec - Nadgarstek", "Finger - Wrist")),
        );

    if (state.monitorRhythm == PatientRhythm.pvt && !pulseCheckedRecently) {
      state.criticalErrorsCount++;
      _logEvent(
        AppLoc.tr(
          "BŁĄD KRYTYCZNY EBM: Wykonano defibrylację w rytmie zorganizowanym (VT) bez sprawdzenia tętna! A co jeśli to był częstoskurcz z tętnem (ROSC)?!",
          "EBM CRITICAL ERROR: Defibrillation performed on an organized rhythm (VT) without checking pulse! What if it was a perfusing tachycardia (ROSC)?!",
        ),
        isError: true,
      );
    }
    _logEvent(
      AppLoc.tr(
        "BŁYSK: Wykonano defibrylację energią $shockEnergy J.",
        "SHOCK: Defibrillation delivered with $shockEnergy J.",
      ),
    );

    state.isDefibCharged = false;
    state.isDefibCharging = false;
    bool isFirstShock = state.shocksDelivered == 0;
    bool isValidShockTiming =
        isFirstShock ||
        !state.isCprActive ||
        (state.isCprActive && state.cprSecondsRemaining > 110);

    if (!isValidShockTiming)
      _logEvent(
        AppLoc.tr(
          "KRYTYCZNY BŁĄD EBM: Wyładowanie w połowie cyklu!",
          "EBM CRITICAL ERROR: Shock delivered mid-cycle!",
        ),
        isError: true,
      );

    if (!isFirstShock &&
        state.chargedEnergy <= state.lastShockEnergy &&
        state.chargedEnergy < 360) {
      _logEvent(
        AppLoc.tr(
          "OSTRZEŻENIE EBM: ERC zaleca eskalację energii przy kolejnych wyładowaniach (np. 150J -> 200J -> 300J -> 360J).",
          "EBM WARNING: ERC recommends energy escalation for subsequent shocks (e.g., 150J -> 200J -> 300J -> 360J).",
        ),
        isError: true,
      );
    }

    if (state.monitorRhythm == PatientRhythm.vf ||
        state.monitorRhythm == PatientRhythm.pvt) {
      state.shocksDelivered++;
      state.lastShockEnergy = state.chargedEnergy;
      _logEvent(
        AppLoc.tr(
          "SUKCES: Defibrylacja nr ${state.shocksDelivered} energią ${state.chargedEnergy}J dostarczona.",
          "SUCCESS: Defibrillation #${state.shocksDelivered} at ${state.chargedEnergy}J delivered.",
        ),
      );
      state.isCprActive = true;
      state.cprSecondsRemaining = 120;
      state.currentPhase = ResuscitationPhase.cprCycle;
    } else {
      _logEvent(
        AppLoc.tr(
          "KRYTYCZNY BŁĄD: Wyładowanie ${state.chargedEnergy}J w rytmie ${state.monitorRhythm.name.toUpperCase()}!",
          "CRITICAL ERROR: Shock of ${state.chargedEnergy}J delivered in ${state.monitorRhythm.name.toUpperCase()} rhythm!",
        ),
        isError: true,
      );
    }
    state.isDefibCharged = false;
    notifyListeners();
  }

  Future<void> prepareDrug(String drugName, String dose) async {
    if (state.preparedDrugs.length >= 2 || state.isPreparingDrug) return;
    state.isPreparingDrug = true;
    state.preparedDrugs.add(
      AppLoc.tr("Przygotowywanie: $drugName...", "Preparing: $drugName..."),
    );
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
    String flush = parts.length > 2 ? parts[2] : "Brak";
    int currentTime = state.totalElapsedGameTime;

    state.administeredDrugs.add(drugName);
    state.preparedDrugs.removeAt(index);

    if (!state.isIvInserted) {
      _logEvent(
        AppLoc.tr(
          "KRYTYCZNY BŁĄD EBM: Próba podaży leku dożylnego ($drugName) bez dostępu naczyniowego (brak wkłucia IV/IO)!",
          "EBM CRITICAL ERROR: Attempted to administer IV drug ($drugName) without vascular access (no IV/IO line)!",
        ),
        isError: true,
      );
      state.instructorFeedback.add(
        AppLoc.tr(
          "FARMACJA: Wylałeś $drugName na pacjenta. Musisz najpierw uzyskać dostęp naczyniowy (wenflon).",
          "PHARMACOLOGY: You poured $drugName on the patient. Obtain vascular access (IV) first.",
        ),
      );
      return;
    }

    bool isShockable =
        state.monitorRhythm == PatientRhythm.vf ||
        state.monitorRhythm == PatientRhythm.pvt;

    if (drugName == "Nalokson") {
      _logEvent(
        AppLoc.tr(
          "AKCJA: Podano Nalokson ($dose).",
          "ACTION: Naloxone ($dose) administered.",
        ),
      );
      try {
        if (state.patient.hiddenCause == ReversibleCause.toxins) {
          _logEvent(
            AppLoc.tr(
              "SUKCES EBM: Odtrutka podana właściwie",
              "EBM SUCCESS: Antidote administered correctly.",
            ),
          );
        } else {
          _logEvent(
            AppLoc.tr(
              "INFO: Brak nagłej reakcji po podaniu Naloksonu.",
              "INFO: No sudden reaction after Naloxone administration.",
            ),
          );
        }
      } catch (e) {
        print("Skippy uratował apkę przed crashem: $e");
      }
      notifyListeners();
      return;
    }

    if (drugName == "Adrenalina") {
      if (dose != "1 mg") {
        _logEvent(
          AppLoc.tr(
            "KRYTYCZNY BŁĄD EBM: Adrenalina w NZK to zawsze 1 mg! Podałeś $dose.",
            "EBM CRITICAL ERROR: Adrenaline in cardiac arrest is always 1 mg! You gave $dose.",
          ),
          isError: true,
        );
      } else if (flush != "0.9% NaCl") {
        _logEvent(
          AppLoc.tr(
            "BŁĄD EBM: Adrenalinę w NZK trzeba podać z 0.9% NaCl, żeby dopchnąć ją do krążenia centralnego! Podałeś z: $flush.",
            "EBM ERROR: Adrenaline in cardiac arrest must be flushed with 0.9% NaCl to push it to central circulation! You flushed with: $flush.",
          ),
          isError: true,
        );
      } else {
        if (isShockable && state.shocksDelivered < 3) {
          _logEvent(
            AppLoc.tr(
              "BŁĄD EBM: W rytmach do defibrylacji Adrenalinę podajemy dopiero PO 3. wyładowaniu!",
              "EBM ERROR: In shockable rhythms, Adrenaline is given only AFTER the 3rd shock!",
            ),
            isError: true,
          );
        } else {
          _validateAdrenalineTiming(currentTime);
        }
      }
    } else if (drugName == "Amiodaron") {
      if (!isShockable) {
        _logEvent(
          AppLoc.tr(
            "KRYTYCZNY BŁĄD EBM: Amiodaron w Asystolii/PEA?!",
            "EBM CRITICAL ERROR: Amiodarone in Asystole/PEA?!",
          ),
          isError: true,
        );
      } else if (flush == "0.9% NaCl (Bolus 20ml)") {
        _logEvent(
          AppLoc.tr(
            "KRYTYCZNY BŁĄD EBM: Zmieszałeś Amiodaron z solą fizjologiczną?! Wytrąciły się kryształy! Ten lek podajemy WYŁĄCZNIE z 5% Glukozą!",
            "EBM CRITICAL ERROR: Mixed Amiodarone with normal saline?! Crystals precipitated! This drug is given ONLY with 5% Dextrose!",
          ),
          isError: true,
        );
      } else {
        if (state.shocksDelivered < 3) {
          _logEvent(
            AppLoc.tr(
              "BŁĄD EBM: Amiodaron podajemy dopiero po 3. wyładowaniu (300 mg).",
              "EBM ERROR: Amiodarone is given only after the 3rd shock (300 mg).",
            ),
            isError: true,
          );
        } else if (state.shocksDelivered >= 3 && state.shocksDelivered < 5) {
          if (dose == "300 mg")
            _logEvent(
              AppLoc.tr(
                "SUKCES: Amiodaron 300 mg (z Glukozą 5%) podany prawidłowo.",
                "SUCCESS: Amiodarone 300 mg (with 5% Dextrose) administered correctly.",
              ),
            );
          else
            _logEvent(
              AppLoc.tr(
                "BŁĄD EBM: Zła dawka! Po 3. wyładowaniu podajemy 300 mg.",
                "EBM ERROR: Wrong dose! Give 300 mg after the 3rd shock.",
              ),
              isError: true,
            );
        } else if (state.shocksDelivered >= 5) {
          if (dose == "150 mg")
            _logEvent(
              AppLoc.tr(
                "SUKCES: Amiodaron 150 mg podany prawidłowo po 5. defibrylacji.",
                "SUCCESS: Amiodarone 150 mg administered correctly after the 5th shock.",
              ),
            );
          else
            _logEvent(
              AppLoc.tr(
                "BŁĄD EBM: Zła dawka! Po 5. wyładowaniu podajemy 150 mg.",
                "EBM ERROR: Wrong dose! Give 150 mg after the 5th shock.",
              ),
              isError: true,
            );
        }
      }
    } else {
      if (!state.patient.hasPulse &&
          drugName != "0.9% NaCl (Kroplówka)" &&
          drugName != "Płyn Wieloelektrolitowy (PWE)") {
        _logEvent(
          AppLoc.tr(
            "OSTRZEŻENIE EBM: Podałeś $drugName w trakcie NZK! Z wyjątkiem specyficznych odtrutek (np. przy 4H4T), podawanie leków nieujętych w algorytmie ALS (innych niż Adrenalina/Amiodaron) nie poprawia przeżywalności, a rozprasza zespół!",
            "EBM WARNING: You gave $drugName during cardiac arrest! Except for specific antidotes (e.g., in 4H4T), administering non-ALS algorithm drugs does not improve survival and distracts the team!",
          ),
          isError: true,
        );
        state.instructorFeedback.add(
          AppLoc.tr(
            "FARMACJA: Podałeś lek '$drugName' pacjentowi bez tętna. To nie jest zgodne z uniwersalnym algorytmem ALS.",
            "PHARMACOLOGY: You gave '$drugName' to a pulseless patient. This is not in line with the universal ALS algorithm.",
          ),
        );
      } else {
        _logEvent(
          AppLoc.tr(
            "INFO: Podałeś: $drugName $dose (Nośnik: $flush).",
            "INFO: Administered: $drugName $dose (Flush: $flush).",
          ),
        );
      }
    }

    notifyListeners();
  }

  void _validateAdrenalineTiming(int currentTime) {
    if (state.lastAdrenalineTime > 0) {
      int diffSeconds = currentTime - state.lastAdrenalineTime;
      if (diffSeconds < 180) {
        _logEvent(
          AppLoc.tr(
            "BŁĄD EBM: Adrenalinę podajemy co 3-5 minut! Podałeś za wcześnie (odstęp: $diffSeconds s). Zwiększasz zapotrzebowanie serca na tlen!",
            "EBM ERROR: Adrenaline is given every 3-5 minutes! Given too early (interval: $diffSeconds s). You are increasing myocardial oxygen demand!",
          ),
        );
      } else if (diffSeconds > 300) {
        _logEvent(
          AppLoc.tr(
            "OSTRZEŻENIE EBM: Przekroczono okno podaży Adrenaliny! Odstęp wyniósł $diffSeconds s.",
            "EBM WARNING: Adrenaline administration window exceeded! Interval was $diffSeconds s.",
          ),
        );
        state.lastAdrenalineTime = currentTime;
      } else {
        _logEvent(
          AppLoc.tr(
            "SUKCES: Adrenalina 1 mg podana w idealnym oknie czasowym (odstęp: $diffSeconds s).",
            "SUCCESS: Adrenaline 1 mg given in the optimal time window (interval: $diffSeconds s).",
          ),
        );
        state.lastAdrenalineTime = currentTime;
      }
    } else {
      _logEvent(
        AppLoc.tr(
          "SUKCES: Pierwsza dawka Adrenaliny (1 mg) podana prawidłowo.",
          "SUCCESS: First dose of Adrenaline (1 mg) administered correctly.",
        ),
      );
      state.lastAdrenalineTime = currentTime;
    }
  }

  void openAirway() {
    if (state.airwayStatus != AirwayType.none) return;
    state.airwayStatus = AirwayType.basic;

    // NOWE: Sprawdzamy czy ma tętno (w NZK nie ma, więc nie oddycha)
    String breathMsg = state.patient.hasPulse
        ? AppLoc.tr("Pacjent oddycha.", "Patient is breathing.")
        : AppLoc.tr("BRAK PRAWIDŁOWEGO ODDECHU!", "NO NORMAL BREATHING!");

    _logEvent(
      AppLoc.tr(
        "AKCJA: Udrożniono drogi oddechowe (rękoczyn czoło-żuchwa). $breathMsg",
        "ACTION: Airway opened (head tilt-chin lift maneuver). $breathMsg",
      ),
    );
    notifyListeners();
  }

  void setOxygenFlow(int flow) {
    state.oxygenFlow = flow;
    if (flow > 0 && flow < 15) {
      _logEvent(
        AppLoc.tr(
          "BŁĄD EBM: Przepływ $flow l/min! W NZK do wentylacji BVM wymagane jest min. 15 l/min (100% O2)!",
          "EBM ERROR: Flow $flow L/min! In cardiac arrest, BVM ventilation requires at least 15 L/min (100% O2)!",
        ),
      );
    } else if (flow >= 15) {
      _logEvent(
        AppLoc.tr(
          "SUKCES: Ustawiono właściwy przepływ O2: $flow l/min.",
          "SUCCESS: Correct O2 flow set: $flow L/min.",
        ),
      );
    } else {
      _logEvent(
        AppLoc.tr(
          "INFO: Zakręcono przepływ tlenu.",
          "INFO: Oxygen flow turned off.",
        ),
      );
    }
    notifyListeners();
  }

  void setupBVM() {
    if (state.patient.hiddenCause == ReversibleCause.hypoxia &&
        !state.isAirwayCleared) {
      _logEvent(
        AppLoc.tr(
          "KRYTYCZNY BŁĄD EBM: Próba wentylacji zanieczyszczonych dróg oddechowych! Użyj ssaka przed nałożeniem maski BVM!",
          "EBM CRITICAL ERROR: Attempted ventilation of obstructed airway! Use suction before applying BVM!",
        ),
        isError: true,
      );
      return;
    }
    state.airwayStatus = AirwayType.bvm;
    _logEvent(
      AppLoc.tr(
        "AKCJA: Założono maskę z workiem (BVM).",
        "ACTION: Bag-Valve-Mask (BVM) applied.",
      ),
    );
    notifyListeners();
  }

  Future<void> preoxygenate() async {
    closeMenus();

    if ((state.airwayStatus != AirwayType.bvm &&
            state.airwayStatus != AirwayType.igel) ||
        state.oxygenFlow < 15) {
      _logEvent(
        AppLoc.tr(
          "BŁĄD EBM: Preoksygenacja wymaga założonego worka BVM lub I-gela oraz przepływu tlenu min. 15 l/min!",
          "EBM ERROR: Preoxygenation requires a BVM or I-gel and oxygen flow of at least 15 L/min!",
        ),
        isError: true,
      );
      notifyListeners();
      return;
    }

    _logEvent(
      AppLoc.tr(
        "INFO: Zespół preoksygenuje pacjenta (100% O2)...",
        "INFO: Team is preoxygenating the patient (100% O2)...",
      ),
    );
    notifyListeners();

    await Future.delayed(const Duration(seconds: 4));

    state.isPreoxygenated = true;
    _logEvent(
      AppLoc.tr(
        "SUKCES EBM: Pacjent odpowiednio natleniony.",
        "EBM SUCCESS: Patient adequately oxygenated.",
      ),
    );
    notifyListeners();
  }

  void insertIGel(int size) {
    if (state.airwayStatus == AirwayType.endotracheal) {
      _logEvent(
        AppLoc.tr(
          "INFO: Pacjent jest już zaintubowany (ETI). Ignoruję I-gel.",
          "INFO: Patient is already intubated (ETI). Ignoring I-gel.",
        ),
      );
      return;
    }

    int expectedSize = 4;
    if (state.patient.weight > 90) expectedSize = 5;
    if (state.patient.weight < 50) expectedSize = 3;

    if (size != expectedSize) {
      _logEvent(
        AppLoc.tr(
          "KRYTYCZNY BŁĄD EBM: Próba założenia I-gel #$size u pacjenta o wadze ${state.patient.weight.toStringAsFixed(0)} kg! Narzędzie jest niedopasowane. Próba nieudana.",
          "EBM CRITICAL ERROR: Attempted to insert I-gel #$size in a ${state.patient.weight.toStringAsFixed(0)} kg patient! Inappropriate size. Attempt failed.",
        ),
      );
      return;
    }

    state.airwayStatus = AirwayType.igel;
    _logEvent(
      AppLoc.tr(
        "SUKCES: Założono I-gel w rozmiarze $size. Prawidłowo dobrany do wagi.",
        "SUCCESS: I-gel size $size inserted. Correctly matched to weight.",
      ),
    );
    notifyListeners();
  }

  Future<void> attemptIntubation() async {
    if (state.patient.hiddenCause == ReversibleCause.hypoxia &&
        !state.isAirwayCleared) {
      _logEvent(
        AppLoc.tr(
          "KRYTYCZNY BŁĄD EBM: Laryngoskopia w zanieczyszczonych drogach! Brak widoczności strun głosowych, użyj ssaka!",
          "EBM CRITICAL ERROR: Laryngoscopy in obstructed airway! No vocal cord visibility, use suction!",
        ),
        isError: true,
      );
      return;
    }
    if (state.intubationAttemptInProgress) return;
    state.intubationAttemptInProgress = true;
    _logEvent(
      AppLoc.tr(
        "AKCJA: Laryngoskopia i próba intubacji...",
        "ACTION: Laryngoscopy and intubation attempt...",
      ),
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
    state.isIntubationVerified = false;
    _logEvent(
      AppLoc.tr(
        "INFO: Rurka wprowadzona. Zweryfikuj jej położenie!",
        "INFO: Tube inserted. Verify its position!",
      ),
    );
    notifyListeners();
  }

  void startIntubationMinigame() {
    if (state.patient.hiddenCause == ReversibleCause.hypoxia &&
        !state.isAirwayCleared) {
      _logEvent(
        AppLoc.tr(
          "KRYTYCZNY BŁĄD EBM: Laryngoskopia w zanieczyszczonych drogach! Brak widoczności strun głosowych, użyj ssaka!",
          "EBM CRITICAL ERROR: Laryngoscopy in obstructed airway! No vocal cord visibility, use suction!",
        ),
        isError: true,
      );
      return;
    }
    if (state.intubationAttemptInProgress) return;
    state.intubationAttemptInProgress = true;
    _logEvent(
      AppLoc.tr(
        "AKCJA: Rozpoczęto wprowadzanie laryngoskopu (Minigra ETI).",
        "ACTION: Commenced laryngoscope insertion (ETI Minigame).",
      ),
    );
    notifyListeners();
  }

  void finishIntubationMinigame(bool hitTrachea, bool correctDepth) {
    if (!hitTrachea) {
      state.intubationStatus = IntubationStatus.esophageal;
    } else if (!correctDepth) {
      state.intubationStatus = IntubationStatus.rightMainstem;
    } else {
      state.intubationStatus = IntubationStatus.correct;
    }

    state.airwayStatus = AirwayType.endotracheal;
    state.intubationAttemptInProgress = false;
    state.isIntubationVerified = false;
    _logEvent(
      AppLoc.tr(
        "INFO: Rurka wprowadzona. Zweryfikuj jej położenie!",
        "INFO: Tube inserted. Verify its position!",
      ),
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
        AppLoc.tr(
          "DIAGNOZA (Osłuchiwanie): Szmer pęcherzykowy słyszalny obustronnie.",
          "DIAGNOSIS (Auscultation): Vesicular breath sounds heard bilaterally.",
        ),
      );
      notifyListeners();
      return;
    }
    if (state.airwayStatus == AirwayType.endotracheal) {
      state.isIntubationVerified = true;
      if (state.intubationStatus == IntubationStatus.correct)
        _logEvent(
          AppLoc.tr(
            "DIAGNOZA: Szmery słyszalne",
            "DIAGNOSIS: Breath sounds audible",
          ),
        );
      else
        _logEvent(
          AppLoc.tr(
            "DIAGNOZA: Problem! Rurka w przełyku lub za głęboko!",
            "DIAGNOSIS: Problem! Tube in esophagus or too deep!",
          ),
        );
    }
    notifyListeners();
  }

  void attachCapnography() {
    state.isCapnographyAttached = true;
    if (state.airwayStatus == AirwayType.endotracheal)
      state.isIntubationVerified = true;
    _logEvent(
      AppLoc.tr(
        "DIAGNOZA: Podłączono Kapnografię.",
        "DIAGNOSIS: Capnography attached.",
      ),
    );
    notifyListeners();
  }

  void attachSpO2() {
    if (state.isSpO2Attached) return;
    state.isSpO2Attached = true;
    _logEvent(
      AppLoc.tr(
        "AKCJA: Założono pulsoksymetr...",
        "ACTION: Pulse oximeter attached...",
      ),
    );
    if (!state.patient.hasPulse) {
      _logEvent(
        AppLoc.tr(
          "DIAGNOZA (SpO2): Urządzenie pika, brak krzywej. W NZK pulsoksymetr nie czyta tętna! (SpO2: --%)",
          "DIAGNOSIS (SpO2): Device beeping, no waveform. Pulse oximeter cannot read a pulse in cardiac arrest! (SpO2: --%)",
        ),
        isError: true,
      );
    } else {
      _logEvent(
        AppLoc.tr(
          "DIAGNOZA (SpO2): ${state.patient.spO2}%",
          "DIAGNOSIS (SpO2): ${state.patient.spO2}%",
        ),
      );
    }
    notifyListeners();
  }

  Future<void> performUSG() async {
    if (state.isUsgDone) return;
    state.isUsgDone = true;
    _logEvent(
      AppLoc.tr(
        "AKCJA: Głowica przyłożona (Hokus POCUS - eFAST)...",
        "ACTION: Probe applied (Hokus POCUS - eFAST)...",
      ),
    );
    notifyListeners();
    await Future.delayed(const Duration(seconds: 4));

    if (state.patient.hiddenCause == ReversibleCause.tamponade) {
      _logEvent(
        AppLoc.tr(
          "DIAGNOZA (USG): Potężna przestrzeń płynowa w osierdziu!",
          "DIAGNOSIS (USG): Massive fluid collection in the pericardium!",
        ),
        isError: true,
      );
    } else if (state.patient.hiddenCause ==
        ReversibleCause.tensionPneumothorax) {
      _logEvent(
        AppLoc.tr(
          "DIAGNOZA (USG): Brak objawu ślizgania opłucnej! Kod kreskowy w M-Mode!",
          "DIAGNOSIS (USG): Absent lung sliding! Barcode sign in M-Mode!",
        ),
        isError: true,
      );
    } else if (state.patient.hiddenCause == ReversibleCause.hypovolemia) {
      _logEvent(
        AppLoc.tr(
          "DIAGNOZA (USG): Żyła główna dolna (IVC) całkowicie zapadnięta.",
          "DIAGNOSIS (USG): Inferior Vena Cava (IVC) completely collapsed.",
        ),
        isError: true,
      );
    } else {
      _logEvent(
        AppLoc.tr(
          "DIAGNOZA (USG): eFAST ujemny. Brak wolnego płynu, opłucna ślizga się symetrycznie.",
          "DIAGNOSIS (USG): eFAST negative. No free fluid, symmetrical lung sliding.",
        ),
      );
    }
    notifyListeners();
  }

  Future<void> measureGlucose() async {
    if (state.isGlucoseMeasured) return;
    _logEvent(
      AppLoc.tr(
        "AKCJA: Zespół nakłuwa palec...",
        "ACTION: Team pricks the finger...",
      ),
    );
    notifyListeners();
    await Future.delayed(const Duration(seconds: 3));
    state.isGlucoseMeasured = true;
    _logEvent(
      AppLoc.tr(
        "DIAGNOZA: Glikemia ${state.patient.bloodGlucose} mg/dL.",
        "DIAGNOSIS: Blood glucose ${state.patient.bloodGlucose} mg/dL.",
      ),
    );
    notifyListeners();
  }

  Future<void> measureTemperature() async {
    if (state.isTempMeasured) return;
    _logEvent(
      AppLoc.tr(
        "AKCJA: Zespół mierzy temperaturę...",
        "ACTION: Team checks temperature...",
      ),
    );
    notifyListeners();
    await Future.delayed(const Duration(seconds: 3));
    state.isTempMeasured = true;
    _logEvent(
      AppLoc.tr(
        "DIAGNOZA: Temperatura ${state.patient.temperature.toStringAsFixed(1)} °C.",
        "DIAGNOSIS: Temperature ${state.patient.temperature.toStringAsFixed(1)} °C.",
      ),
    );
    notifyListeners();
  }

  void performPhysicalExam() {
    if (state.isPhysicalExamDone) return;

    state.isPhysicalExamDone = true;
    _logEvent(
      AppLoc.tr(
        "AKCJA: Rozcięto ubrania. Wykonano badanie urazowe (Exposure / ABCDE).",
        "ACTION: Clothes cut open. Trauma examination performed (Exposure / ABCDE).",
      ),
    );

    List<String> findings = [];
    findings.add(
      AppLoc.tr(
        "Skóra: ${state.patient.skinCondition}",
        "Skin: ${state.patient.skinCondition}",
      ),
    );
    findings.add(
      AppLoc.tr(
        "Źrenice: ${state.patient.pupils}",
        "Pupils: ${state.patient.pupils}",
      ),
    );

    if (state.patient.hiddenCause == ReversibleCause.tamponade)
      findings.add(
        AppLoc.tr(
          "Klatka: Masywny ślad po uderzeniu na mostku",
          "Chest: Massive bruise from impact on sternum",
        ),
      );
    if (state.patient.hiddenCause == ReversibleCause.tensionPneumothorax ||
        state.patient.hiddenCause == ReversibleCause.tamponade)
      findings.add(
        AppLoc.tr(
          "Szyja: Przepełnione żyły szyjne",
          "Neck: Distended jugular veins",
        ),
      );
    if (state.patient.hiddenCause == ReversibleCause.toxins)
      findings.add(
        AppLoc.tr(
          "Ręce: Ślady po wkłuciach dożylnych",
          "Arms: IV needle track marks",
        ),
      );
    if (state.patient.hiddenCause == ReversibleCause.hypoHyperkalemia)
      findings.add(
        AppLoc.tr(
          "Ręce: Czynna przetoka dializacyjna | Nogi: Obrzęki ciastowate",
          "Arms: Active AV fistula | Legs: Pitting edema",
        ),
      );
    if (state.patient.hiddenCause == ReversibleCause.thrombosis)
      findings.add(
        AppLoc.tr(
          "Nogi: Asymetryczny obrzęk jednej łydki (DVT)",
          "Legs: Asymmetrical swelling of one calf (DVT)",
        ),
      );
    if (state.patient.hiddenCause == ReversibleCause.hypovolemia)
      findings.add(
        AppLoc.tr(
          "Brzuch: Napięty, wzdęty (wodobrzusze)",
          "Abdomen: Distended, tense (ascites)",
        ),
      );
    if (state.patient.hiddenCause == ReversibleCause.hypoxia)
      findings.add(
        AppLoc.tr(
          "Głowa: Ciało obce / Piana w jamie ustnej",
          "Head: Foreign body / Froth in oral cavity",
        ),
      );

    _logEvent(
      AppLoc.tr(
            "DIAGNOZA (Fizykalne Całościowe): ",
            "DIAGNOSIS (Comprehensive Physical): ",
          ) +
          "${findings.join(' | ')}",
    );
    notifyListeners();
  }

  String performTargetedExam(String tool, String target) {
    state.isPhysicalExamDone = true;
    if (tool == "Palec") {
      String result = "";
      if (target.contains("Nadgarstek")) {
        result = state.patient.hasPulse
            ? AppLoc.tr(
                "Tętno promieniowe wyczuwalne.",
                "Radial pulse palpable.",
              )
            : AppLoc.tr(
                "Brak tętna na tętnicach promieniowych.",
                "No pulse on radial arteries.",
              );
      } else if (target.contains("Stopa")) {
        result = state.patient.hasPulse
            ? AppLoc.tr(
                "Tętno na grzbiecie stopy obecne.",
                "Pedal pulse palpable.",
              )
            : AppLoc.tr("Brak tętna na stopach.", "No pulse on feet.");
      } else if (target.contains("Szyja")) {
        result = state.patient.hasPulse
            ? AppLoc.tr(
                "Tętno na tętnicach szyjnych mocne.",
                "Carotid pulse strong.",
              )
            : AppLoc.tr(
                "BRAK TĘTNA na tętnicach szyjnych!",
                "NO PULSE on carotid arteries!",
              );
      } else if (target.contains("Klatka")) {
        result = AppLoc.tr(
          "Skóra blada, chłodna, lepka od potu.",
          "Skin pale, cool, clammy with sweat.",
        );
      } else if (target.contains("brzusze")) {
        result = AppLoc.tr(
          "Brzuch miękki, niebolesny.",
          "Abdomen soft, non-tender.",
        );
      } else {
        result = AppLoc.tr(
          "Brak specyficznych odchyleń.",
          "No specific abnormalities.",
        );
      }

      _logEvent(
        AppLoc.tr(
          "BADANIE (Palec - $target): $result",
          "EXAMINATION (Finger - $target): $result",
        ),
      );
      notifyListeners();
      return result;
    }

    if (tool == "Latarka" && target == "Głowa") {
      _logEvent(
        AppLoc.tr(
          "BADANIE: Oceniono źrenice (Latarka). Wynik: ${state.patient.pupils}.",
          "EXAMINATION: Pupils assessed (Flashlight). Result: ${state.patient.pupils}.",
        ),
      );
      notifyListeners();
      return AppLoc.tr(
        "Źrenice:\n${state.patient.pupils}",
        "Pupils:\n${state.patient.pupils}",
      );
    } else if (tool == "Stetoskop") {
      state.isAuscultated = true;
      if (target == "Nadbrzusze") {
        String stomach =
            (state.airwayStatus == AirwayType.endotracheal &&
                state.intubationStatus == IntubationStatus.esophageal)
            ? AppLoc.tr(
                "BULGOTANIE! (Rurka w przełyku!)",
                "GURGLING! (Tube in esophagus!)",
              )
            : AppLoc.tr("Cisza (Prawidłowo)", "Silence (Normal)");
        _logEvent(
          AppLoc.tr(
            "BADANIE: Osłuchiwanie żołądka. Wynik: $stomach.",
            "EXAMINATION: Stomach auscultation. Result: $stomach.",
          ),
        );
        notifyListeners();
        return AppLoc.tr("Żołądek:\n$stomach", "Stomach:\n$stomach");
      } else if (target.contains("Klatka") || target.contains("Bok")) {
        bool isLeft = target.contains("Lew");
        String sounds = AppLoc.tr(
          "Brak szmerów / Zbyt cicho",
          "No breath sounds / Too quiet",
        );

        if (state.patient.hiddenCause == ReversibleCause.tensionPneumothorax &&
            isLeft) {
          sounds = AppLoc.tr(
            "CISZA! Zupełny brak szmeru pęcherzykowego!",
            "SILENCE! Complete absence of breath sounds!",
          );
        } else if (state.airwayStatus == AirwayType.endotracheal) {
          if (state.intubationStatus == IntubationStatus.esophageal)
            sounds = AppLoc.tr("Brak szmerów", "No breath sounds");
          else if (state.intubationStatus == IntubationStatus.rightMainstem &&
              isLeft)
            sounds = AppLoc.tr(
              "CISZA! (Rurka za głęboko)",
              "SILENCE! (Tube too deep)",
            );
          else if (state.intubationStatus == IntubationStatus.rightMainstem &&
              !isLeft)
            sounds = AppLoc.tr(
              "Czysty szmer pęcherzykowy",
              "Clear breath sounds",
            );
          else
            sounds = AppLoc.tr(
              "Szmer pęcherzykowy symetryczny",
              "Breath sounds symmetrical",
            );
        } else if (state.airwayStatus == AirwayType.igel ||
            state.airwayStatus == AirwayType.bvm) {
          sounds = AppLoc.tr(
            "Szmer pęcherzykowy (Wentylacja wymuszona)",
            "Breath sounds (Forced ventilation)",
          );
        }
        _logEvent(
          AppLoc.tr(
            "BADANIE: Osłuchiwanie ($target). Wynik: $sounds.",
            "EXAMINATION: Auscultation ($target). Result: $sounds.",
          ),
        );
        notifyListeners();
        return AppLoc.tr("Osłuchiwanie:\n$sounds", "Auscultation:\n$sounds");
      }
    } else if (tool == "Termometr" &&
        (target == "Głowa" || target == "Szyja")) {
      state.isTempMeasured = true;
      _logEvent(
        AppLoc.tr(
          "BADANIE: Zmierzono temperaturę ciała: ${state.patient.temperature}°C.",
          "EXAMINATION: Body temperature measured: ${state.patient.temperature}°C.",
        ),
      );
      notifyListeners();
      return AppLoc.tr(
        "Temperatura:\n${state.patient.temperature}°C",
        "Temperature:\n${state.patient.temperature}°C",
      );
    } else if (tool == "Glukometr" &&
        (target.contains("Dłoń") ||
            target.contains("Stopa") ||
            target.contains("Zgięcie"))) {
      state.isGlucoseMeasured = true;
      _logEvent(
        AppLoc.tr(
          "BADANIE: Zmierzono glikemię z $target. Wynik: ${state.patient.bloodGlucose} mg/dL.",
          "EXAMINATION: Glucose measured from $target. Result: ${state.patient.bloodGlucose} mg/dL.",
        ),
      );
      notifyListeners();
      return AppLoc.tr(
        "Glikemia:\n${state.patient.bloodGlucose} mg/dL",
        "Glucose:\n${state.patient.bloodGlucose} mg/dL",
      );
    } else if (tool == "Pulsoksymetr" &&
        (target.contains("Dłoń") || target.contains("Stopa"))) {
      attachSpO2();
      return AppLoc.tr(
        "Założono klips SpO2\n(Odczyt na monitorze)",
        "SpO2 probe attached\n(Reading on monitor)",
      );
    } else if (tool == "Ssak") {
      if (target == "Głowa") {
        state.isAirwayCleared = true;
        _logEvent(
          AppLoc.tr(
            "AKCJA: Użyto ssaka / szczypiec Magilla. Oczyszczono drogi oddechowe.",
            "ACTION: Suction / Magill forceps used. Airway cleared.",
          ),
        );
        notifyListeners();
        return AppLoc.tr("Drogi oddechowe czyste.", "Airway clear.");
      } else {
        return AppLoc.tr(
          "Ssak używamy tylko w obrębie jamy ustnej!",
          "Suction is only used in the oral cavity!",
        );
      }
    } else if (tool == "USG: Hokus POCUS") {
      state.isUsgDone = true;
      if (target == "Nadbrzusze") {
        bool tamp = state.patient.hiddenCause == ReversibleCause.tamponade;
        _logEvent(
          AppLoc.tr(
            "USG: Podmostkowa. ${tamp ? 'PŁYN W OSIERDZIU!' : 'Brak płynu.'}",
            "USG: Subxiphoid. ${tamp ? 'PERICARDIAL EFFUSION!' : 'No fluid.'}",
          ),
        );
        notifyListeners();
        return AppLoc.tr(
          "USG (Serce):\n${tamp ? 'PŁYN W OSIERDZIU!' : 'Norma'}",
          "USG (Heart):\n${tamp ? 'EFFUSION!' : 'Normal'}",
        );
      } else if (target.contains("Klatka")) {
        bool isLeft = target.contains("Lew");
        bool pneumo =
            state.patient.hiddenCause == ReversibleCause.tensionPneumothorax;
        bool rightMainstem =
            (state.airwayStatus == AirwayType.endotracheal &&
            state.intubationStatus == IntubationStatus.rightMainstem);
        bool isVentilated =
            state.airwayStatus == AirwayType.bvm ||
            state.airwayStatus == AirwayType.igel ||
            state.airwayStatus == AirwayType.endotracheal;

        if (!isVentilated) {
          _logEvent(
            AppLoc.tr(
              "USG: Opłucna ($target). BRAK SLIDINGU! (Pacjent nie oddycha i nie jest wentylowany - płuca się nie poruszają).",
              "USG: Pleura ($target). NO SLIDING! (Patient is apneic and not ventilated - lungs not moving).",
            ),
          );
          notifyListeners();
          return AppLoc.tr(
            "USG (Opłucna):\nBrak ślizgania!",
            "USG (Pleura):\nNo sliding!",
          );
        } else if (pneumo && isLeft) {
          _logEvent(
            AppLoc.tr(
              "USG: Opłucna ($target). BRAK SLIDINGU (Kod Kreskowy)!",
              "USG: Pleura ($target). NO SLIDING (Barcode Sign)!",
            ),
          );
          notifyListeners();
          return AppLoc.tr(
            "USG (Opłucna):\nBRAK ŚLIZGANIA (Odma)!",
            "USG (Pleura):\nNO SLIDING (Pneumothorax)!",
          );
        } else if (pneumo && !isLeft) {
          _logEvent(
            AppLoc.tr(
              "USG: Opłucna ($target). Prawidłowy objaw ślizgania (Seashore Sign).",
              "USG: Pleura ($target). Normal lung sliding (Seashore Sign).",
            ),
          );
          notifyListeners();
          return AppLoc.tr(
            "USG (Opłucna):\nŚlizganie obecne",
            "USG (Pleura):\nSliding present",
          );
        } else if (rightMainstem && isLeft) {
          _logEvent(
            AppLoc.tr(
              "USG: Opłucna ($target). BRAK SLIDINGU!",
              "USG: Pleura ($target). NO SLIDING!",
            ),
          );
          notifyListeners();
          return AppLoc.tr(
            "USG (Opłucna):\nBrak ślizgania!",
            "USG (Pleura):\nNo sliding!",
          );
        } else {
          _logEvent(
            AppLoc.tr(
              "USG: Opłucna ($target). Ślizganie obecne.",
              "USG: Pleura ($target). Sliding present.",
            ),
          );
          notifyListeners();
          return AppLoc.tr(
            "USG (Opłucna):\nŚlizganie obecne",
            "USG (Pleura):\nSliding present",
          );
        }
      } else if (target == "Bok Prawy") {
        bool hypo = state.patient.hiddenCause == ReversibleCause.hypovolemia;
        _logEvent(
          AppLoc.tr(
            "USG: Zachyłek Morisona / IVC. ${hypo ? 'IVC Zapadnięta' : 'Brak wolnego płynu, IVC w normie.'}",
            "USG: Morison's Pouch / IVC. ${hypo ? 'IVC Collapsed' : 'No free fluid, IVC normal.'}",
          ),
        );
        notifyListeners();
        return AppLoc.tr(
          "USG (Morison):\n${hypo ? 'IVC Zapadnięta!' : 'Czysto'}",
          "USG (Morison):\n${hypo ? 'IVC Collapsed!' : 'Clear'}",
        );
      } else if (target == "Bok Lewy" || target == "Podbrzusze") {
        _logEvent(
          AppLoc.tr(
            "USG: $target. Brak wolnego płynu.",
            "USG: $target. No free fluid.",
          ),
        );
        notifyListeners();
        return AppLoc.tr(
          "USG ($target):\nBrak wolnego płynu",
          "USG ($target):\nNo free fluid",
        );
      }
    } else if (tool == "Folia NRC" &&
        (target.contains("Klatka") || target.contains("brzusze"))) {
      provideThermalComfort();
      return AppLoc.tr(
        "Pacjent zabezpieczony termicznie.",
        "Patient thermally secured.",
      );
    }
    if (tool == "Oglądanie" || tool == "Badanie Fizykalne") {
      if (target.contains("Klatka")) {
        state.isChestExamined = true;

        bool isVentilated =
            state.airwayStatus == AirwayType.bvm ||
            state.airwayStatus == AirwayType.igel ||
            state.airwayStatus == AirwayType.endotracheal;
        String chestMove = AppLoc.tr(
          "BRAK własnych ruchów oddechowych.",
          "NO spontaneous respiratory effort.",
        );
        if (isVentilated) {
          chestMove =
              (state.patient.hiddenCause == ReversibleCause.tensionPneumothorax)
              ? AppLoc.tr(
                  "Klatka unosi się ASYMETRYCZNIE (prawa strona mocniej)!",
                  "Chest rises ASYMMETRICALLY (right side more)!",
                )
              : AppLoc.tr(
                  "Klatka unosi się symetrycznie (sztuczna wentylacja).",
                  "Chest rises symmetrically (artificial ventilation).",
                );
        }

        String trauma = (state.patient.hiddenCause == ReversibleCause.tamponade)
            ? AppLoc.tr(
                "UWAGA: Masywne zasinienie i ślad po uderzeniu na mostku!",
                "WARNING: Massive bruising and impact mark on sternum!",
              )
            : AppLoc.tr(
                "Brak ran i krwotoków zewnętrznych.",
                "No external wounds or bleeding.",
              );

        _logEvent(
          AppLoc.tr(
            "BADANIE: Klatka piersiowa. $chestMove $trauma Waga: ~${state.patient.weight.toStringAsFixed(0)} kg.",
            "EXAMINATION: Chest. $chestMove $trauma Weight: ~${state.patient.weight.toStringAsFixed(0)} kg.",
          ),
        );
        notifyListeners();
        return "$chestMove\n$trauma\n${AppLoc.tr('Waga', 'Weight')}: ~${state.patient.weight.toStringAsFixed(0)} kg";
      } else if (target.contains("brzusze")) {
        state.isAbdomenExamined = true;

        String abdDesc = AppLoc.tr(
          "Powłoki brzuszne wysklepione. Brak widocznych krwotoków.",
          "Abdomen distended. No visible bleeding.",
        );
        if (state.patient.hiddenCause == ReversibleCause.hypovolemia) {
          abdDesc = AppLoc.tr(
            "Brzuch wzdęty, napięty (Wodobrzusze). Widoczne krążenie oboczne (marskość).",
            "Abdomen tense, distended (Ascites). Visible collateral circulation (cirrhosis).",
          );
        }

        _logEvent(
          AppLoc.tr(
            "BADANIE: Brzuch. $abdDesc",
            "EXAMINATION: Abdomen. $abdDesc",
          ),
        );
        notifyListeners();
        return abdDesc;
      } else if (target == "Szyja") {
        state.isNeckExamined = true;
        bool isDistended =
            (state.patient.hiddenCause == ReversibleCause.tensionPneumothorax ||
            state.patient.hiddenCause == ReversibleCause.tamponade);
        String jvdText = isDistended
            ? AppLoc.tr(
                "Żyły szyjne NADMIERNIE WYPEŁNIONE!",
                "Jugular veins DISTENDED!",
              )
            : AppLoc.tr(
                "Żyły szyjne płaskie/zapadnięte.",
                "Jugular veins flat/collapsed.",
              );
        _logEvent(
          AppLoc.tr(
            "BADANIE: Oceniono szyję. $jvdText",
            "EXAMINATION: Neck assessed. $jvdText",
          ),
        );
        notifyListeners();
        return "${AppLoc.tr('Szyja', 'Neck')}:\n$jvdText";
      } else if (target.contains("Noga") || target.contains("Stopa")) {
        state.isLegsExamined = true;
        String legsDesc = AppLoc.tr(
          "Kończyny symetryczne. Brak obrzęków.",
          "Limbs symmetrical. No edema.",
        );
        if (state.patient.hiddenCause == ReversibleCause.thrombosis) {
          legsDesc = AppLoc.tr(
            "Znaczny, ASYMETRYCZNY obrzęk i zasinienie jednej z łydek (podejrzenie DVT)!",
            "Significant, ASYMMETRICAL swelling and cyanosis of one calf (suspected DVT)!",
          );
        } else if (state.patient.hiddenCause ==
            ReversibleCause.hypoHyperkalemia) {
          legsDesc = AppLoc.tr(
            "Masywne, symetryczne obrzęki ciastowate obu podudzi.",
            "Massive, symmetrical pitting edema of both lower legs.",
          );
        }
        _logEvent(
          AppLoc.tr(
            "BADANIE: Nogi. $legsDesc Brak widocznych krwotoków.",
            "EXAMINATION: Legs. $legsDesc No visible bleeding.",
          ),
        );
        notifyListeners();
        return "$legsDesc\n${AppLoc.tr('Brak krwotoków.', 'No bleeding.')}";
      } else if (target.contains("Nadgarstek") ||
          target.contains("Dłoń") ||
          target.contains("Zgięcie")) {
        String armsDesc = AppLoc.tr(
          "Kończyny górne symetryczne. Brak obrzęków.",
          "Upper limbs symmetrical. No edema.",
        );
        if (state.patient.hiddenCause == ReversibleCause.toxins) {
          armsDesc = AppLoc.tr(
            "UWAGA: Widoczne liczne, świeże i stare ślady po wkłuciach dożylnych!",
            "WARNING: Visible numerous, fresh and old IV track marks!",
          );
        } else if (state.patient.hiddenCause ==
            ReversibleCause.hypoHyperkalemia) {
          armsDesc = AppLoc.tr(
            "UWAGA: Widoczna czynna przetoka tętniczo-żylna (dializacyjna) na przedramieniu!",
            "WARNING: Visible active AV fistula (dialysis) on forearm!",
          );
        }
        _logEvent(
          AppLoc.tr(
            "BADANIE: Ręce. $armsDesc Brak widocznych krwotoków.",
            "EXAMINATION: Arms. $armsDesc No visible bleeding.",
          ),
        );
        notifyListeners();
        return armsDesc;
      } else if (target == "Głowa") {
        String headDesc =
            "${AppLoc.tr('Twarz', 'Face')}:\n${AppLoc.tr('Skóra', 'Skin')} ${state.patient.skinCondition.toLowerCase()}";
        String extra = "";

        if (state.patient.hiddenCause == ReversibleCause.hypoxia &&
            !state.isAirwayCleared) {
          extra = AppLoc.tr(
            " UWAGA: Widoczne ciało obce / piana w ustach!",
            " WARNING: Visible foreign body / froth in mouth!",
          );
          headDesc += AppLoc.tr(
            "\nObecne ciało obce / piana w ustach!",
            "\nForeign body / froth present in mouth!",
          );
        }

        _logEvent(
          AppLoc.tr(
            "BADANIE: Twarz/Głowa. Skóra ${state.patient.skinCondition.toLowerCase()}.$extra",
            "EXAMINATION: Face/Head. Skin ${state.patient.skinCondition.toLowerCase()}.$extra",
          ),
        );
        notifyListeners();
        return headDesc;
      } else {
        _logEvent(
          AppLoc.tr(
            "BADANIE: $target. Skóra: ${state.patient.skinCondition}. Brak zewnętrznych krwotoków.",
            "EXAMINATION: $target. Skin: ${state.patient.skinCondition}. No external bleeding.",
          ),
        );
        notifyListeners();
        return AppLoc.tr(
          "Skóra blada. Brak uszkodzeń w tej strefie.",
          "Skin pale. No injuries in this area.",
        );
      }
    } else if (tool == "Worek BVM" && target == "Głowa") {
      if (state.patient.hiddenCause == ReversibleCause.hypoxia &&
          !state.isAirwayCleared) {
        _logEvent(
          AppLoc.tr(
            "KRYTYCZNY BŁĄD EBM: Próba wentylacji zanieczyszczonych dróg (ciało obce/wydzielina)! Użyj ssaka!",
            "EBM CRITICAL ERROR: Attempted ventilation with obstructed airway! Use suction!",
          ),
          isError: true,
        );
        return AppLoc.tr(
          "Opór na worku! Użyj ssaka.",
          "BVM resistance! Use suction.",
        );
      }
      state.airwayStatus = AirwayType.bvm;
      _logEvent(
        AppLoc.tr(
          "AKCJA: Wdrożono wentylację workiem samorozprężalnym z maską twarzową (BVM).",
          "ACTION: Implemented Bag-Valve-Mask (BVM) ventilation.",
        ),
      );
      notifyListeners();
      return AppLoc.tr(
        "Worek (BVM):\nWentylacja w toku",
        "BVM:\nVentilation in progress",
      );
    } else if (tool.startsWith("I-gel") && target == "Głowa") {
      if (state.patient.hiddenCause == ReversibleCause.hypoxia &&
          !state.isAirwayCleared) {
        _logEvent(
          AppLoc.tr(
            "KRYTYCZNY BŁĄD EBM: Próba założenia I-gel do zanieczyszczonych dróg oddechowych! Użyj ssaka!",
            "EBM CRITICAL ERROR: Attempted to insert I-gel into obstructed airway! Use suction!",
          ),
          isError: true,
        );
        return AppLoc.tr("Drogi zablokowane!", "Airway blocked!");
      }
      int size = int.parse(tool.split("#")[1]);
      double weight = state.patient.weight;
      bool isCorrect =
          (size == 3 && weight < 50) ||
          (size == 4 && weight >= 50 && weight <= 90) ||
          (size == 5 && weight > 90);

      state.airwayStatus = AirwayType.igel;
      if (!isCorrect) {
        _logEvent(
          AppLoc.tr(
            "BŁĄD: Założono I-gel rozm. $size dla pacjenta o wadze ${weight.toStringAsFixed(0)}kg! Masywna nieszczelność dróg oddechowych.",
            "ERROR: Inserted I-gel size $size for a ${weight.toStringAsFixed(0)}kg patient! Massive airway leak.",
          ),
          isError: true,
        );
        state.patient.etCo2 = (state.patient.etCo2 * 0.5).toInt();
      } else {
        _logEvent(
          AppLoc.tr(
            "AKCJA: Poprawnie zabezpieczono drogi oddechowe (I-gel rozm. $size).",
            "ACTION: Airway properly secured (I-gel size $size).",
          ),
        );
      }
      notifyListeners();
      return AppLoc.tr("I-gel założony", "I-gel inserted");
    } else if (tool.startsWith("Kaniula") && target.contains("Zgięcie")) {
      return "IV_MINIGAME";
    }

    _logEvent(
      AppLoc.tr(
        "AKCJA: Próba użycia '$tool' na '$target'. Brak logicznej procedury EBM.",
        "ACTION: Attempted to use '$tool' on '$target'. No logical EBM procedure.",
      ),
      isError: true,
    );
    return AppLoc.tr("Niewłaściwe użycie sprzętu", "Improper equipment use");
  }

  void toggleBag() {
    state.isBagOpen = !state.isBagOpen;
    if (state.isBagOpen) state.isAirwayMenuOpen = false;
    notifyListeners();
  }

  void toggleAirwayMenu() {
    state.isAirwayMenuOpen = !state.isAirwayMenuOpen;
    if (state.isAirwayMenuOpen) state.isBagOpen = false;
    notifyListeners();
  }

  void closeMenus() {
    state.isBagOpen = false;
    state.isAirwayMenuOpen = false;
    notifyListeners();
  }

  void verifyPreoxygenationBeforeETI() {
    if (!state.isPreoxygenated) {
      _logEvent(
        AppLoc.tr(
          "KRYTYCZNY BŁĄD EBM: Próba ETI bez preoksygenacji (100% O2)! Ryzyko gwałtownej desaturacji!",
          "EBM CRITICAL ERROR: ETI attempt without preoxygenation (100% O2)! Risk of rapid desaturation!",
        ),
        isError: true,
      );
      if (!state.instructorFeedback.any(
        (msg) => msg.contains(
          AppLoc.tr("bez preoksygenacji", "without preoxygenation"),
        ),
      )) {
        state.instructorFeedback.add(
          AppLoc.tr(
            "DROGI ODDECHOWE: Zaintubowałeś pacjenta bez preoksygenacji. Zawsze natleniaj biernie przed próbą ETI!",
            "AIRWAY: You intubated the patient without preoxygenation. Always oxygenate passively before ETI attempt!",
          ),
        );
      }
      notifyListeners();
    }
  }

  void performManualAirwayManeuver() async {
    closeMenus();
    _logEvent(
      AppLoc.tr(
        "AKCJA: Wykonano rękoczyn udrożnienia dróg oddechowych (uniesienie żuchwy/odchylenie głowy).",
        "ACTION: Manual airway maneuver performed (head tilt-chin lift).",
      ),
    );
    notifyListeners();

    // Zmniejszone opóźnienie z 3 sekund do zaledwie 500ms, aby komunikat był natychmiastowy
    await Future.delayed(const Duration(milliseconds: 500));

    if (!state.patient.hasPulse) {
      _logEvent(
        AppLoc.tr(
          "DIAGNOZA: Oceniono oddech -> BRAK PRAWIDŁOWEGO ODDECHU!",
          "DIAGNOSIS: Breathing assessed -> NO NORMAL BREATHING!",
        ),
        isError: true, // Wymusza czerwony/ostrzegawczy kolor w UI!
      );
    } else {
      _logEvent(
        AppLoc.tr(
          "DIAGNOZA: Oceniono oddech -> Pacjent oddycha prawidłowo.",
          "DIAGNOSIS: Breathing assessed -> Patient is breathing normally.",
        ),
      );
    }
    notifyListeners();
  }

  void evaluate4H4TCause(String cause) {
    bool success = false;

    if (cause == "Hipotermia" || cause == "Hypothermia") {
      if (!state.isTempMeasured) {
        success = false;
        _logEvent(
          AppLoc.tr(
            "BŁĄD EBM: Chcesz wykluczyć hipotermię 'na oko'?! Zmierz najpierw temperaturę centralną!",
            "EBM ERROR: Trying to rule out hypothermia 'by eye'?! Measure core temperature first!",
          ),
          isError: true,
        );
      } else if (state.patient.temperature < 35.0 && !state.isWarmingProvided) {
        success = false;
        _logEvent(
          AppLoc.tr(
            "BŁĄD EBM: Oznaczasz Hipotermię jako zabezpieczoną, ale pacjent ma ${state.patient.temperature}°C i nie wdrożono ogrzewania!",
            "EBM ERROR: You mark Hypothermia as secured, but patient has ${state.patient.temperature}°C and no warming provided!",
          ),
          isError: true,
        );
      } else {
        success = true;
        _logEvent(
          AppLoc.tr(
            "SUKCES EBM: Hipotermia wykluczona lub odpowiednio leczona.",
            "EBM SUCCESS: Hypothermia ruled out or adequately treated.",
          ),
        );
      }
    } else if (cause == "Hipowolemia" || cause == "Hypovolemia") {
      if (!state.isUsgDone &&
          !(state.isChestExamined &&
              state.isAbdomenExamined &&
              state.isLegsExamined)) {
        success = false;
        _logEvent(
          AppLoc.tr(
            "BŁĄD EBM: Aby wykluczyć krwotok/hipowolemię bez USG (IVC), musisz obejrzeć klatkę, brzuch i kończyny pacjenta!",
            "EBM ERROR: To rule out hemorrhage/hypovolemia without USG (IVC), you must inspect the chest, abdomen, and lower extremities!",
          ),
          isError: true,
        );
      } else {
        success = true;
        _logEvent(
          AppLoc.tr(
            "SUKCES EBM: Hipowolemia zabezpieczona/wykluczona diagnostycznie.",
            "EBM SUCCESS: Hypovolemia secured/ruled out diagnostically.",
          ),
        );
      }
    } else if (cause == "Tamponada" || cause == "Tamponade") {
      if (!state.isUsgDone && !state.isNeckExamined) {
        success = false;
        _logEvent(
          AppLoc.tr(
            "BŁĄD EBM: Tamponada bez USG (Serce) lub oceny wypełnienia żył szyjnych?! Użyj głowicy lub zbadaj szyję!",
            "EBM ERROR: Tamponade without USG (Heart) or jugular vein assessment?! Use the probe or examine the neck!",
          ),
          isError: true,
        );
      } else {
        success = true;
        _logEvent(
          AppLoc.tr(
            "SUKCES EBM: Przyczyna wykluczona na podstawie USG/Badania fizykalnego.",
            "EBM SUCCESS: Cause ruled out based on USG/Physical Exam.",
          ),
        );
      }
    } else if (cause == "Thrombosis (Zator)" || cause == "Thrombosis (PE)") {
      if (!state.isNeckExamined || !state.isLegsExamined) {
        success = false;
        _logEvent(
          AppLoc.tr(
            "BŁĄD EBM: Aby rozpoznać/wykluczyć zator w NZK, obejrzyj żyły szyjne oraz kończyny dolne (obrzęki/DVT)!",
            "EBM ERROR: To recognize/rule out pulmonary embolism in cardiac arrest, inspect jugular veins and lower extremities (edema/DVT)!",
          ),
          isError: true,
        );
      } else {
        success = true;
        _logEvent(
          AppLoc.tr(
            "SUKCES EBM: Diagnostyka zatorowości przeprowadzona. Wdrożono optymalne postępowanie.",
            "EBM SUCCESS: Pulmonary embolism diagnostics performed. Optimal management implemented.",
          ),
        );
      }
    } else if (cause == "Tension pneumothorax (Odma)" ||
        cause == "Tension pneumothorax") {
      if (!state.isAuscultated && !state.isUsgDone) {
        success = false;
        _logEvent(
          AppLoc.tr(
            "BŁĄD EBM: Odma?! A gdzie osłuchiwanie klatki lub objaw ślizgania opłucnej w USG?! Strzelasz w ciemno!",
            "EBM ERROR: Pneumothorax?! Where is chest auscultation or lung sliding in USG?! You're guessing blind!",
          ),
          isError: true,
        );
      } else {
        success = true;
        _logEvent(
          AppLoc.tr(
            "SUKCES EBM: Odma prężna zweryfikowana/wykluczona.",
            "EBM SUCCESS: Tension pneumothorax verified/ruled out.",
          ),
        );
      }
    } else if (cause == "Toxins (Zatrucia)" || cause == "Toxins") {
      if (state.patient.pupils.contains(AppLoc.tr("Szpilkowate", "Pinpoint")) &&
          !state.administeredDrugs.contains("Nalokson")) {
        success = false;
        _logEvent(
          AppLoc.tr(
            "BŁĄD EBM: Zignorowano specyficzne objawy kliniczne! Brak wdrożenia celowanej farmakoterapii odtrutkowej.",
            "EBM ERROR: Specific clinical signs ignored! Lack of targeted antidote pharmacotherapy.",
          ),
          isError: true,
        );
      } else if (state.patient.pupils.contains(
            AppLoc.tr("Szpilkowate", "Pinpoint"),
          ) &&
          state.administeredDrugs.contains("Nalokson")) {
        success = true;
        _logEvent(
          AppLoc.tr(
            "SUKCES EBM: Podejrzenie zatrucia odpowiednio zabezpieczone właściwym antidotum.",
            "EBM SUCCESS: Suspected poisoning adequately secured with the correct antidote.",
          ),
        );
      } else {
        success = true;
        _logEvent(
          AppLoc.tr(
            "INFO: Przyczyna toksykologiczna wstępnie wykluczona na podstawie oceny klinicznej.",
            "INFO: Toxicological cause provisionally ruled out based on clinical assessment.",
          ),
        );
      }
    } else if (cause == "Hipoksja" || cause == "Hypoxia") {
      bool hasAirway =
          state.airwayStatus == AirwayType.bvm ||
          state.airwayStatus == AirwayType.igel ||
          state.airwayStatus == AirwayType.endotracheal;
      bool hasOxygen = state.oxygenFlow >= 15;
      if (!hasAirway || !hasOxygen) {
        success = false;
        _logEvent(
          AppLoc.tr(
            "BŁĄD EBM: Pacjent wymaga tlenoterapii (min. 15 l/min) i wsparcia wentylacji (BVM/SGA/ETI) przed wykluczeniem hipoksji!",
            "EBM ERROR: Patient requires oxygen therapy (min. 15 L/min) and ventilation support (BVM/SGA/ETI) before ruling out hypoxia!",
          ),
          isError: true,
        );
      } else {
        success = true;
        _logEvent(
          AppLoc.tr(
            "SUKCES EBM: Hipoksja zabezpieczona wentylacją z 100% O2.",
            "EBM SUCCESS: Hypoxia secured with 100% O2 ventilation.",
          ),
        );
      }
    } else {
      success = true;
      _logEvent(
        AppLoc.tr("INFO: Wykluczono przyczynę.", "INFO: Cause ruled out."),
      );
    }

    state.h4tStatus[cause] = success ? 1 : -1;
    notifyListeners();
  }

  void provideThermalComfort() {
    state.isWarmingProvided = true;
    _logEvent(
      AppLoc.tr(
        "AKCJA: zapewniono komfort termiczny.",
        "ACTION: Thermal comfort provided.",
      ),
    );
    notifyListeners();
  }

  void considerCause(String cause) {
    if (state.considered4H4T.contains(cause)) return;
    state.considered4H4T.add(cause);
    _logEvent(
      AppLoc.tr("ZESPÓŁ ROZWAŻA: $cause.", "TEAM IS CONSIDERING: $cause."),
    );
    notifyListeners();
  }

  void _logEvent(String message, {bool isError = false}) {
    String formattedMsg =
        "[${_formatTime(state.totalElapsedGameTime)}] $message";
    state.auditLog.insert(0, formattedMsg);

    // SKIPPY FIX: Diagnoza (brak oddechu/tętna) to nie jest błąd gracza, nawet jeśli w UI ma się świecić na czerwono!
    bool isDiagnosis =
        message.contains("DIAGNOZA") || message.contains("DIAGNOSIS");

    if (isError && !isDiagnosis) {
      if (message.contains(AppLoc.tr("KRYTYCZNY", "CRITICAL")))
        state.criticalErrorsCount++;
      else
        state.warningErrorsCount++;
    }

    if (state.mode == GameMode.test &&
        (isError ||
            message.contains(AppLoc.tr("SUKCES", "SUCCESS")) ||
            message.contains(AppLoc.tr("BŁĄD", "ERROR")))) {
      // Cisza w eterze w trybie testu
    } else {
      state.log.insert(0, formattedMsg);
    }
    notifyListeners();
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

  void identifyDominantCause(String cause) {
    state.identifiedDominantCause = cause;
    _logEvent(
      AppLoc.tr(
        "DIAGNOZA: Zespół wskazał '$cause' jako dominującą przyczynę NZK. Przygotowanie do transportu/celowanej terapii.",
        "DIAGNOSIS: Team identified '$cause' as the dominant cause of cardiac arrest. Preparing for transport/targeted therapy.",
      ),
    );
    notifyListeners();
  }

  String _mapCauseToKey(ReversibleCause cause) {
    switch (cause) {
      case ReversibleCause.hypoxia:
        return AppLoc.tr("Hipoksja", "Hypoxia");
      case ReversibleCause.hypovolemia:
        return AppLoc.tr("Hipowolemia", "Hypovolemia");
      case ReversibleCause.hypoHyperkalemia:
        return AppLoc.tr("Hipo/Hiperkaliemia", "Hypo/Hyperkalemia");
      case ReversibleCause.hypothermia:
        return AppLoc.tr("Hipotermia", "Hypothermia");
      case ReversibleCause.tamponade:
        return AppLoc.tr("Tamponada", "Tamponade");
      case ReversibleCause.toxins:
        return AppLoc.tr("Toxins (Zatrucia)", "Toxins");
      case ReversibleCause.tensionPneumothorax:
        return AppLoc.tr("Tension pneumothorax (Odma)", "Tension pneumothorax");
      case ReversibleCause.thrombosis:
        return AppLoc.tr("Thrombosis (Zator)", "Thrombosis (PE)");
      default:
        return "";
    }
  }
}
