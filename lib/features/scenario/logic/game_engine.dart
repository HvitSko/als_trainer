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
            // ZMIANA: Jeśli tlen < 15, jakość wentylacji jest dramatyczna, co sztucznie zaniża parametry w naszej symulacji
            if (state.oxygenFlow < 15) {
              state.patient.etCo2 =
                  5 + Random().nextInt(6); // 5-10 mmHg (Bardzo źle)
            } else {
              state.patient.etCo2 =
                  12 + Random().nextInt(11); // 12-22 mmHg (Prawidłowo przy RKO)
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

    // LOGIKA ROSC (Powrót Spontanicznego Krążenia)
    bool isCauseResolved =
        state.h4tStatus[state.patient.hiddenCause.name.split('.').last] == 1;

    // Szansa bazowa zależy od tego, czy wykluczono odwracalną przyczynę
    int roscChance = isCauseResolved ? 60 : 5;

    // Kary za błędy
    roscChance -= (state.criticalErrorsCount * 15);
    roscChance -= (state.warningErrorsCount * 5);

    // Jeśli mija 2 cykl, i rzut kostką się udał (ROSC)
    if (state.cprCyclesCompleted >= 2 && Random().nextInt(100) < roscChance) {
      state.monitorRhythm =
          PatientRhythm.pea; // Pokazujemy na monitorze rytm zorganizowany
      state.patient.hasPulse = true;
      state.currentPhase = ResuscitationPhase.postResuscitation;
      _logEvent(
        "SUKCES: Wykryto powrót fali tętna! ROSC! Zatrzymanie scenariusza.",
      );
      notifyListeners();
      return; // Kończymy! Nasłuchiwacz przeniesie nas na ekran podsumowania.
    }

    // Jeśli brak ROSC, prosta ewolucja rytmu (VF -> Asystolia itp)
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

    bool isShockable =
        state.monitorRhythm == PatientRhythm.vf ||
        state.monitorRhythm == PatientRhythm.pvt;

    if (drugName == "Adrenalina") {
      if (dose != "1 mg") {
        _logEvent(
          "KRYTYCZNY BŁĄD EBM: Adrenalina w NZK to zawsze 1 mg! Podałeś $dose.",
          isError: true,
        );
      } else if (flush != "0.9% NaCl") {
        _logEvent(
          "BŁĄD EBM: Adrenalinę w NZK trzeba popić bolusem ok. 20ml NaCl, żeby dopchnąć ją do krążenia centralnego! Podałeś z: $flush.",
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
      _logEvent("INFO: Podałeś lek: $drugName $dose (Popitka: $flush).");
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

  void startIntubationMinigame() {
    if (state.intubationAttemptInProgress) return;
    if (!state.isPreoxygenated) {
      _logEvent(
        "KRYTYCZNY BŁĄD EBM: Brak preoksygenacji przed ETI!",
        isError: true,
      );
    }
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
        "DIAGNOZA (USG): Potężna przestrzeń płynowa w osierdziu! Serce pływa (TAMPONADA)!",
        isError: true,
      );
    } else if (state.patient.hiddenCause ==
        ReversibleCause.tensionPneumothorax) {
      _logEvent(
        "DIAGNOZA (USG): Brak objawu ślizgania opłucnej! Kod kreskowy w M-Mode! (ODMA PRĘŻNA)!",
        isError: true,
      );
    } else if (state.patient.hiddenCause == ReversibleCause.hypovolemia) {
      _logEvent(
        "DIAGNOZA (USG): Żyła główna dolna (IVC) całkowicie zapadnięta. Hipowolemia!",
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

  Future<void> performPhysicalExam() async {
    if (state.isPhysicalExamDone) return;
    _logEvent("AKCJA: Szybkie badanie urazowe (Exposure)...");
    notifyListeners();
    await Future.delayed(const Duration(seconds: 4));
    state.isPhysicalExamDone = true;
    _logEvent("DIAGNOZA (Badanie): Żyły szyjne zapadnięte. Źrenice szerokie.");
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
      if (!state.isUsgDone && !state.isPhysicalExamDone) {
        success = false;
        _logEvent(
          "BŁĄD EBM: Jak chcesz ocenić wolemię w NZK bez zbadania żył szyjnych (Exposure) lub USG IVC?!",
          isError: true,
        );
      } else {
        success = true;
        _logEvent(
          "SUKCES EBM: Hipowolemia zabezpieczona/wykluczona diagnostycznie.",
        );
      }
    } else if (cause == "Tamponada" || cause == "Thrombosis (Zator)") {
      if (!state.isUsgDone && !state.isPhysicalExamDone) {
        success = false;
        _logEvent(
          "BŁĄD EBM: $cause bez USG lub oceny wypełnienia żył szyjnych?! Wrzuć głowicę na klatkę (Hokus POCUS) lub zrób badanie urazowe!",
          isError: true,
        );
      } else {
        success = true;
        _logEvent(
          "SUKCES EBM: Przyczyna $cause wykluczona na podstawie USG/Badania fizykalnego.",
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
    _logEvent(
      "AKCJA: Rozpoczęto aktywne ogrzewanie pacjenta / zapewniono komfort termiczny.",
    );
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
      if (message.contains("KRYTYCZNY")) {
        state.criticalErrorsCount++;
      } else {
        state.warningErrorsCount++;
      }
    }
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
