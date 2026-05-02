import 'dart:math';
import 'scenario_model.dart';
import 'patient_model.dart';
import 'als_state.dart';

class ScenarioDatabase {
  static List<Scenario> getAllScenarios() {
    return [
      // SCENARIUSZ 1: TOKSYNY (OPIOIDY)
      Scenario(
        id: 'tox_opioid_01',
        title: 'Zatrucie Opioidami (Toxins)',
        dispatchInfo:
            'Wezwanie z CPR: Mężczyzna, ok. 30 lat, nieprzytomny, nie oddycha. Zgłasza sąsiadka, która znalazła go na klatce schodowej.',
        sceneSizeUp:
            'Mieszkanie otwarte. Pacjent leży na podłodze. Obok leżą puste blistry po Fentanylu i Tramadolu. Brak innych osób. Środowisko bezpieczne.',
        initialRhythm: PatientRhythm.asystole,
        generatePatient: () => PatientModel(
          heartRate: 0,
          hasPulse: false,
          systolicBP: 0,
          diastolicBP: 0,
          spO2: null,
          etCo2: 0,
          temperature: 35.8,
          bloodGlucose: 110,
          weight: 75.0,
          hiddenCause: ReversibleCause.toxins,
          skinCondition: 'Zasiniona (centralnie i obwodowo), chłodna, lepka',
          chestMovement: 'Brak ruchów oddechowych',
          pupils:
              'Szpilkowate (szczególnie wąskie), brak reakcji na światło!', // KRYTYCZNA POSZLAKA
        ),
      ),

      // SCENARIUSZ 2: OZW / ZAKRZEP (STEMI)
      Scenario(
        id: 'acs_stemi_01',
        title: 'Nagłe Zatrzymanie w Miejscu Publicznym (Thrombosis)',
        dispatchInfo:
            'Wezwanie z CPR: Mężczyzna, ok. 60 lat, upadł na przystanku autobusowym. Świadkowie prowadzą RKO.',
        sceneSizeUp:
            'Ulica. Tłum gapiów. Straż Miejska zabezpiecza teren. Świadek uciska klatkę piersiową ze słabą jakością. Obok leży teczka pacjenta.',
        initialRhythm: PatientRhythm.vf,
        generatePatient: () => PatientModel(
          heartRate: 0, // Migotanie komór
          hasPulse: false,
          systolicBP: 0,
          diastolicBP: 0,
          spO2: null,
          etCo2: 0,
          temperature: 36.6,
          bloodGlucose: 140,
          weight: 95.0,
          hiddenCause: ReversibleCause.thrombosis,
          skinCondition: 'Blada, spocona',
          chestMovement: 'Brak własnych ruchów oddechowych',
          pupils: 'Szerokie, wolna reakcja',
        ),
      ),

      // SCENARIUSZ 3: HIPOTERMIA
      Scenario(
        id: 'hypo_01',
        title: 'Hipotermia (Hypothermia)',
        dispatchInfo:
            'Wezwanie z CPR: Bezdomny znaleziona w pustostanie przez patrol policji. Temperatura otoczenia -2 stopnie C.',
        sceneSizeUp:
            'Pustostan. Brak ogrzewania. Pacjent leży na betonie w mokrym ubraniu. Czuć silną woń alkoholu.',
        initialRhythm: PatientRhythm
            .pea, // Zwykle bradykardia przechodząca w PEA/Asystolię
        generatePatient: () => PatientModel(
          heartRate: 20, // Agonalne PEA na monitorze
          hasPulse: false,
          systolicBP: 0,
          diastolicBP: 0,
          spO2: null,
          etCo2: 0,
          temperature: 28.5, // KRYTYCZNA HIPOTERMIA
          bloodGlucose: 65, // Alkoholicy często mają hipoglikemię
          weight: 65.0,
          hiddenCause: ReversibleCause.hypothermia,
          skinCondition: 'Lodowata, blada, marmurkowata',
          chestMovement: 'Brak',
          pupils: 'Szerokie, sztywne (objaw hipotermii)',
        ),
      ),
    ];
  }

  static Scenario getRandomScenario() {
    final scenarios = getAllScenarios();
    return scenarios[Random().nextInt(scenarios.length)];
  }
}
