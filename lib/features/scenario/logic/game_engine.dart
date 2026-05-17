import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import '../models/als_state.dart';
import '../models/scenario_model.dart';
import '../models/patient_model.dart';

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
            "KRYTYCZNY BŁĄD EBM: Pacjent bez skutecznej wentylacji (O2 + drogi) od ponad 30s! Mózg umiera.",
            isError: true,
          );
          state.instructorFeedback.add(
            "KRYTYCZNE: Dopuściłeś do głębokiego niedotlenienia. Przez ponad 30 sekund nie prowadziłeś tlenoterapii (min. 15l/min) i udrożnienia dróg.",
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
            "KRYTYCZNY BŁĄD EBM: Ręce oderwane od klatki już od ${state.cprInactiveSeconds} sekund! Mózg pacjenta umiera!",
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

        // Zabezpieczenie przed spamem: logujemy powiadomienie tylko raz, dokładnie w sekundzie '0',
        // a potem np. przypominamy co 15 sekund (żeby gracz nie zapomniał przerwać uciśnięć).
        if (state.cprSecondsRemaining == 0) {
          if (state.totalElapsedGameTime % 15 == 0) {
            // Spamuje co 15 sekund zamiast co sekundę
            _logEvent(
              "OSTRZEŻENIE: Czas cyklu RKO minął! ZATRZYMAJ uciśnięcia, aby ocenić rytm!",
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
            // GLOBALNA REGUŁA: Zator, Odma, Tamponada drastycznie obniżają EtCO2 przez blokadę rzutu (wstrząs obturacyjny)!
            if (state.patient.hiddenCause ==
                    ReversibleCause.tensionPneumothorax ||
                state.patient.hiddenCause == ReversibleCause.thrombosis ||
                state.patient.hiddenCause == ReversibleCause.tamponade) {
              state.patient.etCo2 =
                  4 +
                  Random().nextInt(
                    6,
                  ); // Niskie wartości pomimo dobrego RKO (4-9 mmHg)
            } else if (state.oxygenFlow < 15) {
              state.patient.etCo2 = 5 + Random().nextInt(6);
            } else {
              state.patient.etCo2 = 12 + Random().nextInt(11); // Norma przy RKO
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

  void toggleMonitor() {
    state.isMonitorOn = !state.isMonitorOn;
    if (state.isMonitorOn &&
        state.currentPhase == ResuscitationPhase.assessmentABCDE) {
      connectMonitor(); // Auto-podłączenie przy pierwszym uruchomieniu
    } else if (!state.isMonitorOn) {
      _logEvent("INFO: Kardiomonitor został wyłączony.");
    }
    notifyListeners();
  }

  void setEcgGain(double gain) {
    if (!state.isMonitorOn) return;
    state.ecgGain = gain;

    // Wytyczne EBM: Jeśli jest asystolia, gracz MUSI zwiększyć cechę (min. x2.0 / x4.0), aby ją potwierdzić!
    if (state.monitorRhythm == PatientRhythm.asystole && gain >= 2.0) {
      state.isAsystoleConfirmed = true;
      _logEvent(
        "SUKCES EBM: Zwiększono cechę zapisu do x$gain. Wykluczono niskonapięciowe migotanie komór (fine VF).",
      );
    } else {
      _logEvent("INFO: Zmieniono cechę wzmocnienia EKG na x$gain.");
    }
    notifyListeners();
  }

  void togglePacer() {
    if (!state.isMonitorOn) return;
    _logEvent("INFO: Włączono tryb stymulatora zewnętrznego (PACER).");
    notifyListeners();
  }

  void stopCprAndAssess() async {
    if (!state.isCprActive) return;
    state.isCprActive = false;
    state.cprCyclesCompleted++;
    state.currentPhase = ResuscitationPhase.analyzing;
    _logEvent("AKCJA: RKO zatrzymane. Analiza EKG...");
    notifyListeners();
    await Future.delayed(const Duration(seconds: 3));

    // NAPRAWIONY ROSC I ZDROWA LOGIKA!
    String causeKey = _mapCauseToKey(state.patient.hiddenCause);
    bool isCauseResolved = causeKey.isEmpty
        ? true
        : state.h4tStatus[causeKey] == 1;

    // Sprawdzamy czy zespół ALS podjął JAKIEKOLWIEK zaawansowane działania (żeby nie było darmowego ROSC po 2 cyklach gapienia się w pacjenta)
    bool isAlsCareProvided =
        state.airwayStatus != AirwayType.none ||
        state.shocksDelivered > 0 ||
        state.administeredDrugs.isNotEmpty;

    int roscChance = 0;
    if (!isAlsCareProvided) {
      roscChance = 0; // Brak ALS = Brak szans na ROSC w naszej symulacji
    } else if (state.patient.hiddenCause == ReversibleCause.none) {
      roscChance =
          25; // Standardowe NZK bez przyczyny specjalnej - 25% szans co pętlę przy poprawnym ALS
    } else {
      roscChance = isCauseResolved
          ? 70
          : 0; // Jeśli jest konkretna przyczyna, bez jej wyleczenia szansa to 0%!
    }

    roscChance -=
        (state.criticalErrorsCount * 10); // Kary za morderstwa po drodze
    if (roscChance < 0) roscChance = 0;

    if (state.cprCyclesCompleted >= 2 && Random().nextInt(100) < roscChance) {
      state.monitorRhythm = PatientRhythm.pea;
      state.patient.hasPulse = true;
      state.currentPhase = ResuscitationPhase.postResuscitation;
      _logEvent(
        "SUKCES: Wykryto powrót fali tętna! ROSC! Zatrzymanie scenariusza.",
      );

      // MAGIA SKIPPY'EGO: Jeśli to "zwykłe" NZK LUB Zator (którego w ZRM nie leczymy przyczynowo w trakcie RKO)
      if (state.patient.hiddenCause == ReversibleCause.none ||
          state.patient.hiddenCause == ReversibleCause.thrombosis) {
        state.instructorFeedback.add(
          "SUKCES: Prowadziłeś interwencję zgodnie z wytycznymi ALS. Poprawnie przeanalizowałeś i wykluczyłeś/zabezpieczyłeś odwracalne przyczyny zatrzymania krążenia (4H4T)",
        );
      } else {
        // Dla innych przyczyn (np. Hipoksja, Hipotermia), które realnie ZABEZPIECZAMY
        state.instructorFeedback.add(
          "SUKCES: Poprawnie zdiagnozowałeś główną przyczynę ($causeKey)",
        );
      }

      notifyListeners();
      return;
    }

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
    // --- WERYFIKACJA EBM: BADANIE TĘTNA ---
    int lastAnalysisIndex = state.auditLog.indexWhere(
      (log) => log.contains("Analiza EKG"),
    );
    if (lastAnalysisIndex == -1) lastAnalysisIndex = state.auditLog.length;

    // Sprawdzamy czy od momentu ostatniego zatrzymania RKO zbadano tętno na dużej tętnicy
    bool pulseCheckedRecently = state.auditLog
        .sublist(0, lastAnalysisIndex)
        .any(
          (log) =>
              log.contains("Palec - Szyja") ||
              log.contains("Palec - Nadgarstek"),
        );

    if (state.totalCprSeconds == 0 && !pulseCheckedRecently) {
      state.criticalErrorsCount++;
      _logEvent(
        "BŁĄD KRYTYCZNY EBM: Rozpoczęto RKO bez uprzedniego zbadania tętna na dużej tętnicy (Szyja)!",
        isError: true,
      );
    } else if (state.totalCprSeconds > 0 &&
        (state.monitorRhythm == PatientRhythm.pea ||
            state.monitorRhythm == PatientRhythm.pvt) &&
        !pulseCheckedRecently) {
      state.criticalErrorsCount++;
      _logEvent(
        "BŁĄD KRYTYCZNY EBM: Powrót do RKO przy rytmie zorganizowanym (PEA/VT) bez uprzedniego sprawdzenia tętna Palcem!",
        isError: true,
      );
    }
    // --------------------------------------

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
    if (!state.isMonitorOn || !state.isDefibCharged) return;

    int shockEnergy = state.selectedEnergy;

    // --- WERYFIKACJA EBM: TĘTNO PRZY VT ---
    int lastAnalysisIndex = state.auditLog.indexWhere(
      (log) => log.contains("Analiza EKG"),
    );
    if (lastAnalysisIndex == -1) lastAnalysisIndex = state.auditLog.length;

    bool pulseCheckedRecently = state.auditLog
        .sublist(0, lastAnalysisIndex)
        .any(
          (log) =>
              log.contains("Palec - Szyja") ||
              log.contains("Palec - Nadgarstek"),
        );

    if (state.monitorRhythm == PatientRhythm.pvt && !pulseCheckedRecently) {
      state.criticalErrorsCount++;
      _logEvent(
        "BŁĄD KRYTYCZNY EBM: Wykonano defibrylację w rytmie zorganizowanym (VT) bez sprawdzenia tętna! A co jeśli to był częstoskurcz z tętnem (ROSC)?!",
        isError: true,
      );
    }
    _logEvent("BŁYSK: Wykonano defibrylację energią $shockEnergy J.");

    state.isDefibCharged = false;
    state.isDefibCharging = false;
    bool isFirstShock = state.shocksDelivered == 0;
    bool isValidShockTiming =
        isFirstShock ||
        !state.isCprActive ||
        (state.isCprActive && state.cprSecondsRemaining > 110);

    if (!isValidShockTiming)
      _logEvent(
        "KRYTYCZNY BŁĄD EBM: Wyładowanie w połowie cyklu!",
        isError: true,
      );

    // ZMIANA: Audyt eskalacji prądu
    if (!isFirstShock &&
        state.chargedEnergy <= state.lastShockEnergy &&
        state.chargedEnergy < 360) {
      _logEvent(
        "OSTRZEŻENIE EBM: ERC zaleca eskalację energii przy kolejnych wyładowaniach (np. 150J -> 200J -> 300J -> 360J).",
        isError: true,
      );
    }

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
        isError: true,
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

    // Rozszyfrowujemy nasz nowy, zaawansowany format leków z Ampularium
    String fullDrugInfo = state.preparedDrugs[index];
    List<String> parts = fullDrugInfo.split('|');
    String drugName = parts[0];
    String dose = parts.length > 1 ? parts[1] : "";
    String flush = parts.length > 2 ? parts[2] : "Brak";
    int currentTime = state.totalElapsedGameTime;

    state.administeredDrugs.add(drugName);
    state.preparedDrugs.removeAt(index);
    // BLOKADA: Brak wkłucia = Brak leków!
    if (!state.isIvInserted) {
      _logEvent(
        "KRYTYCZNY BŁĄD EBM: Próba podaży leku dożylnego ($drugName) bez dostępu naczyniowego (brak wkłucia IV/IO)!",
        isError: true,
      );
      state.instructorFeedback.add(
        "FARMACJA: Wylałeś $drugName na pacjenta. Musisz najpierw uzyskać dostęp naczyniowy (wenflon).",
      );
      return;
    }

    bool isShockable =
        state.monitorRhythm == PatientRhythm.vf ||
        state.monitorRhythm == PatientRhythm.pvt;
    if (drugName == "Nalokson") {
      _logEvent("AKCJA: Podano Nalokson ($dose).");
      try {
        if (state.patient.hiddenCause == ReversibleCause.toxins) {
          _logEvent("SUKCES EBM: Odtrutka podana właściwie");
        } else {
          _logEvent("INFO: Brak nagłej reakcji po podaniu Naloksonu.");
        }
      } catch (e) {
        print("Skippy uratował apkę przed crashem: $e");
      }
      notifyListeners();
      return; // Koniec tury dla tego leku
    }

    if (drugName == "Adrenalina") {
      if (dose != "1 mg") {
        _logEvent(
          "KRYTYCZNY BŁĄD EBM: Adrenalina w NZK to zawsze 1 mg! Podałeś $dose.",
          isError: true,
        );
      } else if (flush != "0.9% NaCl") {
        _logEvent(
          "BŁĄD EBM: Adrenalinę w NZK trzeba podać z 0.9% NaCl, żeby dopchnąć ją do krążenia centralnego! Podałeś z: $flush.",
          isError: true,
        );
      } else {
        if (isShockable && state.shocksDelivered < 3) {
          _logEvent(
            "BŁĄD EBM: W rytmach do defibrylacji Adrenalinę podajemy dopiero PO 3. wyładowaniu!",
            isError: true,
          );
        } else {
          _validateAdrenalineTiming(currentTime);
        }
      }
    } else if (drugName == "Amiodaron") {
      if (!isShockable) {
        _logEvent(
          "KRYTYCZNY BŁĄD EBM: Amiodaron w Asystolii/PEA?!",
          isError: true,
        );
      } else if (flush == "0.9% NaCl (Bolus 20ml)") {
        _logEvent(
          "KRYTYCZNY BŁĄD EBM: Zmieszałeś Amiodaron z solą fizjologiczną?! Wytrąciły się kryształy! Ten lek podajemy WYŁĄCZNIE z 5% Glukozą!",
          isError: true,
        );
      } else {
        if (state.shocksDelivered < 3) {
          _logEvent(
            "BŁĄD EBM: Amiodaron podajemy dopiero po 3. wyładowaniu (300 mg).",
            isError: true,
          );
        } else if (state.shocksDelivered >= 3 && state.shocksDelivered < 5) {
          if (dose == "300 mg")
            _logEvent(
              "SUKCES: Amiodaron 300 mg (z Glukozą 5%) podany prawidłowo.",
            );
          else
            _logEvent(
              "BŁĄD EBM: Zła dawka! Po 3. wyładowaniu podajemy 300 mg.",
              isError: true,
            );
        } else if (state.shocksDelivered >= 5) {
          if (dose == "150 mg")
            _logEvent(
              "SUKCES: Amiodaron 150 mg podany prawidłowo po 5. defibrylacji.",
            );
          else
            _logEvent(
              "BŁĄD EBM: Zła dawka! Po 5. wyładowaniu podajemy 150 mg.",
              isError: true,
            );
        }
      }
    } else {
      // Jeśli to nie jest Adrenalina, Amiodaron, ani Nalokson (który ma własną logikę w 4H4T), a pacjent jest w NZK:
      if (!state.patient.hasPulse &&
          drugName != "0.9% NaCl (Kroplówka)" &&
          drugName != "Płyn Wieloelektrolitowy (PWE)") {
        _logEvent(
          "OSTRZEŻENIE EBM: Podałeś $drugName w trakcie NZK! Z wyjątkiem specyficznych odtrutek (np. przy 4H4T), podawanie leków nieujętych w algorytmie ALS (innych niż Adrenalina/Amiodaron) nie poprawia przeżywalności, a rozprasza zespół!",
          isError: true,
        );
        state.instructorFeedback.add(
          "FARMACJA: Podałeś lek '$drugName' pacjentowi bez tętna. To nie jest zgodne z uniwersalnym algorytmem ALS.",
        );
      } else {
        _logEvent("INFO: Podałeś: $drugName $dose (Nośnik: $flush).");
      }
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
    closeMenus(); // Zamykamy HUD, żeby zrobić miejsce na ekranie pacjenta!

    // Logika EBM: Nie da się preoksygenować powietrzem z pokoju i bez sprzętu
    if ((state.airwayStatus != AirwayType.bvm &&
            state.airwayStatus != AirwayType.igel) ||
        state.oxygenFlow < 15) {
      _logEvent(
        "BŁĄD EBM: Preoksygenacja wymaga założonego worka BVM lub I-gela oraz przepływu tlenu min. 15 l/min!",
        isError: true,
      );
      notifyListeners();
      return;
    }

    _logEvent("INFO: Zespół preoksygenuje pacjenta (100% O2)...");
    notifyListeners(); // Odświeżamy UI, żeby pokazać info w nowym HUD

    await Future.delayed(const Duration(seconds: 4)); // Symulacja czasu w grze

    state.isPreoxygenated = true;
    _logEvent("SUKCES EBM: Pacjent odpowiednio natleniony.");
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
    _logEvent("INFO: Rurka wprowadzona. Zweryfikuj jej położenie!");
    notifyListeners();
  }

  void startIntubationMinigame() {
    if (state.intubationAttemptInProgress) return;
    state.intubationAttemptInProgress = true;
    _logEvent("AKCJA: Rozpoczęto wprowadzanie laryngoskopu (Minigra ETI).");
    notifyListeners();
  }

  void finishIntubationMinigame(bool hitTrachea, bool correctDepth) {
    if (!hitTrachea) {
      state.intubationStatus = IntubationStatus.esophageal; // Przełyk
    } else if (!correctDepth) {
      state.intubationStatus =
          IntubationStatus.rightMainstem; // Za głęboko (prawe oskrzele)
    } else {
      state.intubationStatus = IntubationStatus.correct; // Perfekt
    }

    state.airwayStatus = AirwayType.endotracheal;
    state.intubationAttemptInProgress = false;
    state.isIntubationVerified = false;
    _logEvent("INFO: Rurka wprowadzona. Zweryfikuj jej położenie!");
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
        _logEvent("DIAGNOZA: Szmery słyszalne");
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
  // W game_engine.dart (sekcja Diagnostyka):

  void attachSpO2() {
    if (state.isSpO2Attached) return;
    state.isSpO2Attached = true;
    _logEvent("AKCJA: Założono pulsoksymetr...");
    if (!state.patient.hasPulse) {
      _logEvent(
        "DIAGNOZA (SpO2): Urządzenie pika, brak krzywej. W NZK pulsoksymetr nie czyta tętna! (SpO2: --%)",
        isError: true,
      );
    } else {
      _logEvent("DIAGNOZA (SpO2): ${state.patient.spO2}%");
    }
    notifyListeners();
  }

  Future<void> performUSG() async {
    if (state.isUsgDone) return;
    state.isUsgDone = true; // ZAPIS W STANIE
    _logEvent("AKCJA: Głowica przyłożona (Hokus POCUS - eFAST)...");
    notifyListeners();
    await Future.delayed(const Duration(seconds: 4));

    if (state.patient.hiddenCause == ReversibleCause.tamponade) {
      _logEvent(
        "DIAGNOZA (USG): Potężna przestrzeń płynowa w osierdziu!",
        isError: true,
      );
    } else if (state.patient.hiddenCause ==
        ReversibleCause.tensionPneumothorax) {
      _logEvent(
        "DIAGNOZA (USG): Brak objawu ślizgania opłucnej! Kod kreskowy w M-Mode!",
        isError: true,
      );
    } else if (state.patient.hiddenCause == ReversibleCause.hypovolemia) {
      _logEvent(
        "DIAGNOZA (USG): Żyła główna dolna (IVC) całkowicie zapadnięta.",
        isError: true,
      );
    } else {
      _logEvent(
        "DIAGNOZA (USG): eFAST ujemny. Brak wolnego płynu, opłucna ślizga się symetrycznie.",
      );
    }
    notifyListeners();
  }

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

  void performPhysicalExam() {
    if (state.isPhysicalExamDone) return;

    state.isPhysicalExamDone = true;
    _logEvent(
      "AKCJA: Rozcięto ubrania. Wykonano badanie urazowe (Exposure / ABCDE).",
    );

    // Dynamiczne zbieranie objawów ze wszystkich stref zależnie od przyczyny NZK!
    List<String> findings = [];
    findings.add("Skóra: ${state.patient.skinCondition}");
    findings.add("Źrenice: ${state.patient.pupils}");

    if (state.patient.hiddenCause == ReversibleCause.tamponade)
      findings.add("Klatka: Masywny ślad po uderzeniu na mostku");
    if (state.patient.hiddenCause == ReversibleCause.tensionPneumothorax ||
        state.patient.hiddenCause == ReversibleCause.tamponade)
      findings.add("Szyja: Przepełnione żyły szyjne");
    if (state.patient.hiddenCause == ReversibleCause.toxins)
      findings.add("Ręce: Ślady po wkłuciach dożylnych");
    if (state.patient.hiddenCause == ReversibleCause.hypoHyperkalemia)
      findings.add(
        "Ręce: Czynna przetoka dializacyjna | Nogi: Obrzęki ciastowate",
      );
    if (state.patient.hiddenCause == ReversibleCause.thrombosis)
      findings.add("Nogi: Asymetryczny obrzęk jednej łydki (DVT)");
    if (state.patient.hiddenCause == ReversibleCause.hypovolemia)
      findings.add("Brzuch: Napięty, wzdęty (wodobrzusze)");
    if (state.patient.hiddenCause == ReversibleCause.hypoxia)
      findings.add("Głowa: Ciało obce / Piana w jamie ustnej");

    _logEvent("DIAGNOZA (Fizykalne Całościowe): ${findings.join(' | ')}");
    notifyListeners();
  }

  // --- NOWY SYSTEM: INTERAKTYWNE BADANIE (DRAG & DROP) ---
  String performTargetedExam(String tool, String target) {
    state.isPhysicalExamDone = true;
    if (tool == "Palec") {
      String result = "";
      if (target.contains("Nadgarstek")) {
        result = state.patient.hasPulse
            ? "Tętno promieniowe wyczuwalne."
            : "Brak tętna na tętnicach promieniowych.";
      } else if (target.contains("Stopa")) {
        result = state.patient.hasPulse
            ? "Tętno na grzbiecie stopy obecne."
            : "Brak tętna na stopach.";
      } else if (target.contains("Szyja")) {
        result = state.patient.hasPulse
            ? "Tętno na tętnicach szyjnych mocne."
            : "BRAK TĘTNA na tętnicach szyjnych!";
      } else if (target.contains("Klatka")) {
        result = "Skóra blada, chłodna, lepka od potu.";
      } else if (target.contains("brzusze")) {
        result = "Brzuch miękki, niebolesny.";
      } else {
        result = "Brak specyficznych odchyleń.";
      }

      // MAGIA SKIPPY'EGO: Gra w końcu "widzi", że użyłeś palca!
      _logEvent("BADANIE (Palec - $target): $result");
      notifyListeners();
      return result;
    }

    if (tool == "Latarka" && target == "Głowa") {
      _logEvent(
        "BADANIE: Oceniono źrenice (Latarka). Wynik: ${state.patient.pupils}.",
      );
      notifyListeners();
      return "Źrenice:\n${state.patient.pupils}";
    } else if (tool == "Stetoskop") {
      state.isAuscultated = true;
      if (target == "Nadbrzusze") {
        String stomach =
            (state.airwayStatus == AirwayType.endotracheal &&
                state.intubationStatus == IntubationStatus.esophageal)
            ? "BULGOTANIE! (Rurka w przełyku!)"
            : "Cisza (Prawidłowo)";
        _logEvent("BADANIE: Osłuchiwanie żołądka. Wynik: $stomach.");
        notifyListeners();
        return "Żołądek:\n$stomach";
      } else if (target.contains("Klatka") || target.contains("Bok")) {
        bool isLeft = target.contains("Lew"); // Wykrywa Lewą Klatkę / Lewy Bok
        String sounds = "Brak szmerów / Zbyt cicho";

        // GLOBALNA REGUŁA: Odma zawsze wycisza szmer po zajętej stronie (tu domyślnie lewej dla uproszczenia mechaniki)
        if (state.patient.hiddenCause == ReversibleCause.tensionPneumothorax &&
            isLeft) {
          sounds = "CISZA! Zupełny brak szmeru pęcherzykowego!";
        } else if (state.airwayStatus == AirwayType.endotracheal) {
          if (state.intubationStatus == IntubationStatus.esophageal)
            sounds = "Brak szmerów";
          else if (state.intubationStatus == IntubationStatus.rightMainstem &&
              isLeft)
            sounds = "CISZA! (Rurka za głęboko)";
          else if (state.intubationStatus == IntubationStatus.rightMainstem &&
              !isLeft)
            sounds = "Czysty szmer pęcherzykowy";
          else
            sounds = "Szmer pęcherzykowy symetryczny";
        } else if (state.airwayStatus == AirwayType.igel ||
            state.airwayStatus == AirwayType.bvm) {
          sounds = "Szmer pęcherzykowy (Wentylacja wymuszona)";
        }
        _logEvent("BADANIE: Osłuchiwanie ($target). Wynik: $sounds.");
        notifyListeners();
        return "Osłuchiwanie:\n$sounds";
      }
    } else if (tool == "Termometr" &&
        (target == "Głowa" || target == "Szyja")) {
      state.isTempMeasured = true;
      _logEvent(
        "BADANIE: Zmierzono temperaturę ciała: ${state.patient.temperature}°C.",
      );
      notifyListeners();
      return "Temperatura:\n${state.patient.temperature}°C";
    }
    // ZMIANA: Nawiasy zabezpieczające logikę Boole'a!
    else if (tool == "Glukometr" &&
        (target.contains("Dłoń") ||
            target.contains("Stopa") || // ZMIANA Z "Noga" NA "Stopa"
            target.contains("Zgięcie"))) {
      state.isGlucoseMeasured = true;
      _logEvent(
        "BADANIE: Zmierzono glikemię z $target. Wynik: ${state.patient.bloodGlucose} mg/dL.",
      );
      notifyListeners();
      return "Glikemia:\n${state.patient.bloodGlucose} mg/dL";
    } else if (tool == "Pulsoksymetr" &&
        (target.contains("Dłoń") || target.contains("Stopa"))) {
      // ZMIANA Z "Noga" NA "Stopa"
      attachSpO2();
      return "Założono klips SpO2\n(Odczyt na monitorze)";
    } else if (tool == "USG: Hokus POCUS") {
      state.isUsgDone = true;
      if (target == "Nadbrzusze") {
        bool tamp = state.patient.hiddenCause == ReversibleCause.tamponade;
        _logEvent(
          "USG: Podmostkowa. ${tamp ? 'PŁYN W OSIERDZIU!' : 'Brak płynu.'}",
        );
        notifyListeners();
        return "USG (Serce):\n${tamp ? 'PŁYN W OSIERDZIU!' : 'Norma'}";
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
          // BRAK WENTYLACJI = BRAK RUCHU PŁUC = BRAK SLIDINGU!
          _logEvent(
            "USG: Opłucna ($target). BRAK SLIDINGU! (Pacjent nie oddycha i nie jest wentylowany - płuca się nie poruszają).",
          );
          notifyListeners();
          return "USG (Opłucna):\nBrak ślizgania!";
        } else if (pneumo) {
          // W przyszłości zrobimy odmę lewo/prawo stronną
          _logEvent("USG: Opłucna ($target). BRAK SLIDINGU (Kod Kreskowy)!");
          notifyListeners();
          return "USG (Opłucna):\nBrak ślizgania!";
        } else if (rightMainstem && isLeft) {
          _logEvent("USG: Opłucna ($target). BRAK SLIDINGU!");
          notifyListeners();
          return "USG (Opłucna):\nBrak ślizgania!";
        } else {
          _logEvent("USG: Opłucna ($target). Ślizganie obecne.");
          notifyListeners();
          return "USG (Opłucna):\nŚlizganie obecne";
        }
      } else if (target == "Bok Prawy") {
        bool hypo = state.patient.hiddenCause == ReversibleCause.hypovolemia;
        _logEvent(
          "USG: Zachyłek Morisona / IVC. ${hypo ? 'IVC Zapadnięta' : 'Brak wolnego płynu, IVC w normie.'}",
        );
        notifyListeners();
        return "USG (Morison):\n${hypo ? 'IVC Zapadnięta!' : 'Czysto'}";
      } else if (target == "Bok Lewy" || target == "Podbrzusze") {
        _logEvent("USG: $target. Brak wolnego płynu.");
        notifyListeners();
        return "USG ($target):\nBrak wolnego płynu";
      }
    } else if (tool == "Folia NRC" &&
        (target.contains("Klatka") || target.contains("brzusze"))) {
      provideThermalComfort();
      return "Pacjent zabezpieczony termicznie.";
    }
    if (tool == "Oglądanie" || tool == "Badanie Fizykalne") {
      if (target.contains("Klatka")) {
        state.isChestExamined = true; // TWARDA FLAGA

        bool isVentilated =
            state.airwayStatus == AirwayType.bvm ||
            state.airwayStatus == AirwayType.igel ||
            state.airwayStatus == AirwayType.endotracheal;
        String chestMove = "BRAK własnych ruchów oddechowych.";
        if (isVentilated) {
          chestMove =
              (state.patient.hiddenCause == ReversibleCause.tensionPneumothorax)
              ? "Klatka unosi się ASYMETRYCZNIE (prawa strona mocniej)!"
              : "Klatka unosi się symetrycznie (sztuczna wentylacja).";
        }

        // GLOBALNA REGUŁA: Zasinienie przy Tamponadzie (uraz tępy klatki)
        String trauma = (state.patient.hiddenCause == ReversibleCause.tamponade)
            ? "UWAGA: Masywne zasinienie i ślad po uderzeniu na mostku!"
            : "Brak ran i krwotoków zewnętrznych.";

        _logEvent(
          "BADANIE: Klatka piersiowa. $chestMove $trauma Waga: ~${state.patient.weight.toStringAsFixed(0)} kg.",
        );
        notifyListeners();
        return "$chestMove\n$trauma\nWaga: ~${state.patient.weight.toStringAsFixed(0)} kg";
      } else if (target.contains("brzusze")) {
        state.isAbdomenExamined = true;

        // GLOBALNA REGUŁA: Wodobrzusze przy krwawieniu z żylaków przełyku (Hipowolemia wtórna do marskości)
        String abdDesc =
            "Powłoki brzuszne wysklepione. Brak widocznych krwotoków.";
        if (state.patient.hiddenCause == ReversibleCause.hypovolemia) {
          abdDesc =
              "Brzuch wzdęty, napięty (Wodobrzusze). Widoczne krążenie oboczne (marskość).";
        }

        _logEvent("BADANIE: Brzuch. $abdDesc");
        notifyListeners();
        return abdDesc;
      } else if (target == "Szyja") {
        state.isNeckExamined = true;
        bool isDistended =
            (state.patient.hiddenCause == ReversibleCause.tensionPneumothorax ||
            state.patient.hiddenCause == ReversibleCause.tamponade);
        String jvdText = isDistended
            ? "Żyły szyjne NADMIERNIE WYPEŁNIONE!"
            : "Żyły szyjne płaskie/zapadnięte.";
        _logEvent("BADANIE: Oceniono szyję. $jvdText");
        notifyListeners();
        return "Szyja:\n$jvdText";
      } else if (target.contains("Noga") || target.contains("Stopa")) {
        // NOGI OSOBNO
        state.isLegsExamined = true;
        String legsDesc = "Kończyny symetryczne. Brak obrzęków.";
        if (state.patient.hiddenCause == ReversibleCause.thrombosis) {
          legsDesc =
              "Znaczny, ASYMETRYCZNY obrzęk i zasinienie jednej z łydek (podejrzenie DVT)!";
        } else if (state.patient.hiddenCause ==
            ReversibleCause.hypoHyperkalemia) {
          legsDesc = "Masywne, symetryczne obrzęki ciastowate obu podudzi.";
        }
        _logEvent("BADANIE: Nogi. $legsDesc Brak widocznych krwotoków.");
        notifyListeners();
        return "$legsDesc\nBrak krwotoków.";
      } else if (target.contains("Nadgarstek") ||
          target.contains("Dłoń") ||
          target.contains("Zgięcie")) {
        // RĘCE OSOBNO (Tego wcześniej nie mieliśmy!)
        String armsDesc = "Kończyny górne symetryczne. Brak obrzęków.";
        if (state.patient.hiddenCause == ReversibleCause.toxins) {
          armsDesc =
              "UWAGA: Widoczne liczne, świeże i stare ślady po wkłuciach dożylnych!";
        } else if (state.patient.hiddenCause ==
            ReversibleCause.hypoHyperkalemia) {
          armsDesc =
              "UWAGA: Widoczna czynna przetoka tętniczo-żylna (dializacyjna) na przedramieniu!";
        }
        _logEvent("BADANIE: Ręce. $armsDesc Brak widocznych krwotoków.");
        notifyListeners();
        return armsDesc;
      } else if (target == "Głowa") {
        String headDesc =
            "Twarz:\nSkóra ${state.patient.skinCondition.toLowerCase()}";
        String extra = "";

        // GLOBALNA REGUŁA: Zablokowane drogi oddechowe
        if (state.patient.hiddenCause == ReversibleCause.hypoxia) {
          extra = " UWAGA: Widoczne ciało obce / piana w ustach!";
          headDesc += "\nObecne ciało obce / piana w ustach!";
        }

        _logEvent(
          "BADANIE: Twarz/Głowa. Skóra ${state.patient.skinCondition.toLowerCase()}.$extra",
        );
        notifyListeners();
        return headDesc;
      } else {
        _logEvent(
          "BADANIE: $target. Skóra: ${state.patient.skinCondition}. Brak zewnętrznych krwotoków.",
        );
        notifyListeners();
        return "Skóra blada. Brak uszkodzeń w tej strefie.";
      }
    }
    // --- NOWY BLOK: NARZĘDZIA ODDECHOWE (DRAG & DROP) ---
    else if (tool == "Worek BVM" && target == "Głowa") {
      state.airwayStatus = AirwayType.bvm;
      _logEvent(
        "AKCJA: Wdrożono wentylację workiem samorozprężalnym z maską twarzową (BVM).",
      );
      notifyListeners();
      return "Worek (BVM):\nWentylacja w toku";
    } else if (tool.startsWith("I-gel") && target == "Głowa") {
      int size = int.parse(tool.split("#")[1]);
      double weight = state.patient.weight;
      bool isCorrect =
          (size == 3 && weight < 50) ||
          (size == 4 && weight >= 50 && weight <= 90) ||
          (size == 5 && weight > 90);

      state.airwayStatus = AirwayType.igel;
      if (!isCorrect) {
        _logEvent(
          "BŁĄD: Założono I-gel rozm. $size dla pacjenta o wadze ${weight.toStringAsFixed(0)}kg! Masywna nieszczelność dróg oddechowych.",
          isError: true,
        );
        state.patient.etCo2 = (state.patient.etCo2 * 0.5)
            .toInt(); // Fizjologiczna kara za nieszczelność
      } else {
        _logEvent(
          "AKCJA: Poprawnie zabezpieczono drogi oddechowe (I-gel rozm. $size).",
        );
      }
      notifyListeners();
      return "I-gel założony";
    } else if (tool.startsWith("Kaniula") && target.contains("Zgięcie")) {
      return "IV_MINIGAME";
    }

    _logEvent(
      "AKCJA: Próba użycia '$tool' na '$target'. Brak logicznej procedury EBM.",
      isError: true,
    );
    return "Niewłaściwe użycie sprzętu";
  }

  // --- KONTROLERY MENU UI ---
  void toggleBag() {
    state.isBagOpen = !state.isBagOpen;
    if (state.isBagOpen) state.isAirwayMenuOpen = false; // Zamyka drugie menu
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

  // --- WERYFIKACJA EBM PRZED OTWARCIEM MINIGRY ETI ---
  void verifyPreoxygenationBeforeETI() {
    if (!state.isPreoxygenated) {
      _logEvent(
        "KRYTYCZNY BŁĄD EBM: Próba ETI bez preoksygenacji (100% O2)! Ryzyko gwałtownej desaturacji!",
        isError: true,
      );
      // Sprawdzamy, czy już tego nie dodaliśmy, żeby nie spamować Instruktora
      if (!state.instructorFeedback.any(
        (msg) => msg.contains("bez preoksygenacji"),
      )) {
        state.instructorFeedback.add(
          "DROGI ODDECHOWE: Zaintubowałeś pacjenta bez preoksygenacji. Zawsze natleniaj biernie przed próbą ETI!",
        );
      }
      notifyListeners();
    }
  }

  void performManualAirwayManeuver() async {
    closeMenus();
    _logEvent(
      "AKCJA: Wykonano rękoczyn udrożnienia dróg oddechowych (uniesienie żuchwy/odchylenie głowy).",
    );
    notifyListeners();
    await Future.delayed(const Duration(seconds: 3));
    if (!state.patient.hasPulse) {
      _logEvent(
        "DIAGNOZA: Po udrożnieniu -> BRAK SAMODZIELNEGO ODDECHU.",
        isError: true,
      );
    } else {
      _logEvent("DIAGNOZA: Po udrożnieniu -> Pacjent oddycha.");
    }
    notifyListeners();
  }

  void evaluate4H4TCause(String cause) {
    bool success = false;

    if (cause == "Hipotermia") {
      if (!state.isTempMeasured) {
        success = false;
        _logEvent(
          "BŁĄD EBM: Chcesz wykluczyć hipotermię 'na oko'?! Zmierz najpierw temperaturę centralną!",
          isError: true,
        );
      } else if (state.patient.temperature < 35.0 && !state.isWarmingProvided) {
        success = false;
        _logEvent(
          "BŁĄD EBM: Oznaczasz Hipotermię jako zabezpieczoną, ale pacjent ma ${state.patient.temperature}°C i nie wdrożono ogrzewania!",
          isError: true,
        );
      } else {
        success = true;
        _logEvent("SUKCES EBM: Hipotermia wykluczona lub odpowiednio leczona.");
      }
    } else if (cause == "Hipowolemia") {
      // SKIPPY FIX: Pancerna weryfikacja na podstawie twardych flag!
      if (!state.isUsgDone &&
          !(state.isChestExamined &&
              state.isAbdomenExamined &&
              state.isLegsExamined)) {
        success = false;
        _logEvent(
          "BŁĄD EBM: Aby wykluczyć krwotok/hipowolemię bez USG (IVC), musisz obejrzeć klatkę, brzuch i kończyny pacjenta!",
          isError: true,
        );
      } else {
        success = true;
        _logEvent(
          "SUKCES EBM: Hipowolemia zabezpieczona/wykluczona diagnostycznie.",
        );
      }
    } else if (cause == "Tamponada") {
      if (!state.isUsgDone && !state.isNeckExamined) {
        success = false;
        _logEvent(
          "BŁĄD EBM: Tamponada bez USG (Serce) lub oceny wypełnienia żył szyjnych?! Użyj głowicy lub zbadaj szyję!",
          isError: true,
        );
      } else {
        success = true;
        _logEvent(
          "SUKCES EBM: Przyczyna $cause wykluczona na podstawie USG/Badania fizykalnego.",
        );
      }
    } else if (cause == "Thrombosis (Zator)") {
      if (!state.isNeckExamined || !state.isLegsExamined) {
        success = false;
        _logEvent(
          "BŁĄD EBM: Aby rozpoznać/wykluczyć zator w NZK, obejrzyj żyły szyjne oraz kończyny dolne (obrzęki/DVT)!",
          isError: true,
        );
      } else {
        success = true;
        _logEvent(
          "SUKCES EBM: Diagnostyka zatorowości przeprowadzona. Wdrożono optymalne postępowanie.",
        );
      }
    } else if (cause == "Tension pneumothorax (Odma)") {
      if (!state.isAuscultated && !state.isUsgDone) {
        success = false;
        _logEvent(
          "BŁĄD EBM: Odma?! A gdzie osłuchiwanie klatki lub objaw ślizgania opłucnej w USG?! Strzelasz w ciemno!",
          isError: true,
        );
      } else {
        success = true;
        _logEvent("SUKCES EBM: Odma prężna zweryfikowana/wykluczona.");
      }
    }
    // ... Stare sekcje dla Toxins i Hipoksji pozostają bez zmian (wklej je tu poniżej)
    else if (cause == "Toxins (Zatrucia)") {
      if (state.patient.pupils.contains("Szpilkowate") &&
          !state.administeredDrugs.contains("Nalokson")) {
        success = false;
        // ZMIANA: Usunięto spoiler o Naloksonie i zawężono podpowiedź.
        _logEvent(
          "BŁĄD EBM: Zignorowano specyficzne objawy kliniczne! Brak wdrożenia celowanej farmakoterapii odtrutkowej.",
          isError: true,
        );
      } else if (state.patient.pupils.contains("Szpilkowate") &&
          state.administeredDrugs.contains("Nalokson")) {
        success = true;
        // ZMIANA: Usunięto jawną nazwę leku z logu sukcesu
        _logEvent(
          "SUKCES EBM: Podejrzenie zatrucia odpowiednio zabezpieczone właściwym antidotum.",
        );
      } else {
        success = true;
        _logEvent(
          "INFO: Przyczyna toksykologiczna wstępnie wykluczona na podstawie oceny klinicznej.",
        );
      }
    } else if (cause == "Hipoksja") {
      bool hasAirway =
          state.airwayStatus == AirwayType.bvm ||
          state.airwayStatus == AirwayType.igel ||
          state.airwayStatus == AirwayType.endotracheal;
      bool hasOxygen = state.oxygenFlow >= 15;
      if (!hasAirway || !hasOxygen) {
        success = false;
        _logEvent(
          "BŁĄD EBM: Pacjent wymaga tlenoterapii (min. 15 l/min) i wsparcia wentylacji (BVM/SGA/ETI) przed wykluczeniem hipoksji!",
          isError: true,
        );
      } else {
        success = true;
        _logEvent("SUKCES EBM: Hipoksja zabezpieczona wentylacją z 100% O2.");
      }
    } else {
      success = true;
      _logEvent("INFO: Wykluczono przyczynę: $cause.");
    }

    state.h4tStatus[cause] = success ? 1 : -1;
    notifyListeners();
  }

  void provideThermalComfort() {
    state.isWarmingProvided = true;
    _logEvent("AKCJA: zapewniono komfort termiczny.");
    notifyListeners();
  }

  void considerCause(String cause) {
    if (state.considered4H4T.contains(cause)) return;
    state.considered4H4T.add(cause);
    _logEvent("ZESPÓŁ ROZWAŻA: $cause.");
    notifyListeners();
  }

  void _logEvent(String message, {bool isError = false}) {
    String formattedMsg =
        "[${_formatTime(state.totalElapsedGameTime)}] $message";
    state.auditLog.insert(0, formattedMsg);

    if (isError) {
      if (message.contains("KRYTYCZNY"))
        state.criticalErrorsCount++;
      else
        state.warningErrorsCount++;
    }

    // W trybie TEST ukrywamy KRYTYCZNE, SUKCESY i BŁĘDY. Pokazujemy tylko diagnostykę.
    if (state.mode == GameMode.test &&
        (isError || message.contains("SUKCES") || message.contains("BŁĄD"))) {
      // Cisza w eterze, egzaminator tylko notuje!
    } else {
      state.log.insert(0, formattedMsg); // W trybie Practice leci wszystko
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

  String _mapCauseToKey(ReversibleCause cause) {
    switch (cause) {
      case ReversibleCause.hypoxia:
        return "Hipoksja";
      case ReversibleCause.hypovolemia:
        return "Hipowolemia";
      case ReversibleCause.hypoHyperkalemia:
        return "Hipo/Hiperkaliemia";
      case ReversibleCause.hypothermia:
        return "Hipotermia";
      case ReversibleCause.tamponade:
        return "Tamponada";
      case ReversibleCause.toxins:
        return "Toxins (Zatrucia)";
      case ReversibleCause.tensionPneumothorax:
        return "Tension pneumothorax (Odma)";
      case ReversibleCause.thrombosis:
        return "Thrombosis (Zator)";
      default:
        return "";
    }
  }
}
