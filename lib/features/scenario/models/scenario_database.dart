import 'dart:math';
import 'scenario_model.dart';
import 'patient_model.dart';
import 'als_state.dart';

class ScenarioDatabase {
  static List<Scenario> getAllScenarios() {
    return [
      // 1. ZATRUCIE (TOXINS)
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
          pupils: 'Szpilkowate (szczególnie wąskie), brak reakcji na światło!',
        ),
      ),

      // 2. HIPOTERMIA
      Scenario(
        id: "nzk_hypothermia_01",
        title: "Mroźny Poranek (Hipotermia)",
        dispatchInfo:
            "ZRM zadysponowany do mężczyzny leżącego na przystanku autobusowym. Temperatura otoczenia -5°C. Pacjent bezdomny, brak reakcji, brak oddechu.",
        sceneSizeUp:
            "Pustostan. Brak ogrzewania. Pacjent leży na betonie w mokrym ubraniu. Czuć silną woń alkoholu.",
        initialRhythm:
            PatientRhythm.pea, // Zwykle bradykardia przechodząca w PEA
        generatePatient: () => PatientModel(
          heartRate: 0,
          hasPulse: false,
          systolicBP: 0,
          diastolicBP: 0,
          spO2: null,
          etCo2: 0,
          temperature: 28.5, // EBM: Głęboka hipotermia! Gra wymusi folię NRC.
          bloodGlucose: 65,
          weight: 65.0,
          hiddenCause: ReversibleCause.hypothermia,
          skinCondition: "Lodowata, blada, marmurkowata",
          chestMovement: "Brak",
          pupils: "Szerokie, sztywne",
        ),
      ),

      // 3. HIPOWOLEMIA
      Scenario(
        id: "nzk_hypovolemia_01",
        title: "Czarne Wymioty (Hipowolemia)",
        dispatchInfo:
            "Kobieta ze znaną chorobą alkoholową i marskością wątroby. Zgłoszono masywne, fusowate wymioty. Zespół wchodzi, pacjentka traci przytomność i przestaje oddychać.",
        sceneSizeUp:
            "Kałuża fusowatych treści i jasnoczerwonej krwi na podłodze. Skrajne odwodnienie. Środowisko bezpieczne.",
        initialRhythm: PatientRhythm.pea, // Klasyka dla utraty płynów
        generatePatient: () => PatientModel(
          heartRate: 0,
          hasPulse: false,
          systolicBP: 0,
          diastolicBP: 0,
          spO2: null,
          etCo2: 0,
          temperature: 35.5,
          bloodGlucose: 110,
          weight: 65.0,
          hiddenCause: ReversibleCause
              .hypovolemia, // Gra wymusi obejrzenie klatki, brzucha i nóg.
          skinCondition: "Ekstremalnie blada, zlana zimnym potem.",
          chestMovement: "Brak ruchów oddechowych",
          pupils: "Szerokie, reagujące leniwie",
        ),
      ),

      // 4. ODMA PRĘŻNA
      Scenario(
        id: "nzk_pneumothorax_01",
        title: "Duszność i Cisza (Odma Prężna)",
        dispatchInfo:
            "19-latek z ciężką astmą oskrzelową. Nagłe, gwałtowne pogorszenie, silna duszność, a potem zatrzymanie krążenia przed przybyciem ZRM.",
        sceneSizeUp:
            "Pacjent leży na podłodze w pokoju. W wywiadzie od rodziny wielokrotne hospitalizacje z powodu astmy. Klatka piersiowa beczkowata.",
        initialRhythm: PatientRhythm.pea,
        generatePatient: () => PatientModel(
          heartRate: 0,
          hasPulse: false,
          systolicBP: 0,
          diastolicBP: 0,
          spO2: null,
          etCo2: 0,
          temperature: 36.6,
          bloodGlucose: 105,
          weight: 72.0,
          hiddenCause: ReversibleCause
              .tensionPneumothorax, // Nasz silnik wywoła tu "NADMIERNIE WYPEŁNIONE ŻYŁY SZYJNE"!
          skinCondition: "Masywna sinica twarzy i szyi.",
          chestMovement: "Brak własnych ruchów oddechowych",
          pupils: "Umiarkowanie szerokie",
        ),
      ),

      // 5. ZATOROWOŚĆ
      Scenario(
        id: "nzk_thrombosis_01",
        title: "Powrót z Azji (Zatorowość)",
        dispatchInfo:
            "Kobieta zasłabła na lotnisku. Wczoraj wróciła z 14-godzinnego lotu z Tajlandii. Zgłaszała ból w klatce piersiowej i duszność.",
        sceneSizeUp:
            "Brak urazów. W wywiadzie od męża: lot długodystansowy, pacjentka przyjmuje antykoncepcję hormonalną.",
        initialRhythm: PatientRhythm.pea,
        generatePatient: () => PatientModel(
          heartRate: 0,
          hasPulse: false,
          systolicBP: 0,
          diastolicBP: 0,
          spO2: null,
          etCo2: 0,
          temperature: 36.8,
          bloodGlucose: 100,
          weight: 80.0,
          hiddenCause: ReversibleCause
              .thrombosis, // ZRM musi obejrzeć żyły szyjne oraz kończyny dolne.
          skinCondition:
              "Sina od pasa w górę, zaczerwienienie i obrzęk prawej łydki.",
          chestMovement: "Brak",
          pupils: "Szerokie",
        ),
      ),

      // 6. TAMPONADA OSIERDZIA
      Scenario(
        id: "nzk_tamponade_01",
        title: "Kierownica na Klatce (Tamponada)",
        dispatchInfo:
            "Wypadek komunikacyjny. Auto uderzyło w drzewo. Uderzenie klatką piersiową w kierownicę (brak zapiętych pasów).",
        sceneSizeUp:
            "Zatrzymanie krążenia następuje w trakcie transportu do karetki. Pacjentka na noszach.",
        initialRhythm: PatientRhythm.pea,
        generatePatient: () => PatientModel(
          heartRate: 0,
          hasPulse: false,
          systolicBP: 0,
          diastolicBP: 0,
          spO2: null,
          etCo2: 0,
          temperature: 36.2,
          bloodGlucose: 120,
          weight: 68.0,
          hiddenCause:
              ReversibleCause.tamponade, // Wymaga oceny szyi (JVD) lub USG.
          skinCondition:
              "Blada, z rozległym zasinieniem w centralnej części klatki piersiowej.",
          chestMovement: "Brak",
          pupils: "Rozszerzone, brak reakcji",
        ),
      ),

      // 7. ZAWAŁ SERCA (CZYSTE NZK DO DEFIBRYLACJI)
      Scenario(
        id: "nzk_stemi_02",
        title: "Ból w Klatce na Siłowni (Standard / VF)",
        dispatchInfo:
            "45-letni mężczyzna zgłosił silny ból w klatce piersiowej podczas wyciskania sztangi. Upadł nieprzytomny. Świadkowie podjęli RKO.",
        sceneSizeUp:
            "Siłownia. Dobrej postury mężczyzna. Na podłodze AED z naklejonymi elektrodami (nierozładowane).",
        initialRhythm: PatientRhythm.vf, // Klasyczne Migotanie Komór
        generatePatient: () => PatientModel(
          heartRate: 0,
          hasPulse: false,
          systolicBP: 0,
          diastolicBP: 0,
          spO2: null,
          etCo2: 0,
          temperature: 36.7,
          bloodGlucose: 130,
          weight: 95.0,
          hiddenCause: ReversibleCause
              .none, // Standardowy algorytm - wczesna defibrylacja kluczem.
          skinCondition: "Zlana ciepłym potem, zaczerwieniona po wysiłku.",
          chestMovement: "Brak własnych ruchów oddechowych",
          pupils: "Szerokie, wolna reakcja",
        ),
      ),

      // 8. HIPOKSJA (ZADŁAWIENIE)
      Scenario(
        id: "nzk_hypoxia_01",
        title: "Niedzielny Obiad (Hipoksja)",
        dispatchInfo:
            "Mężczyzna zadławił się kawałkiem mięsa podczas obiadu rodzinnego. Próby rękoczynu Heimlicha przez bliskich nieskuteczne. Doszło do NZK.",
        sceneSizeUp:
            "Brak urazów. Zespół zastaje pacjenta na podłodze. Obecne resztki jedzenia w jamie ustnej (wskazana pilna intubacja/SGA i odsysanie).",
        initialRhythm: PatientRhythm.asystole,
        generatePatient: () => PatientModel(
          heartRate: 0,
          hasPulse: false,
          systolicBP: 0,
          diastolicBP: 0,
          spO2: null,
          etCo2: 0,
          temperature: 36.5,
          bloodGlucose: 110,
          weight: 85.0,
          hiddenCause: ReversibleCause.hypoxia,
          skinCondition: "Głęboko sina (cyjanotyczna) twarz i usta.",
          chestMovement: "Brak",
          pupils: "Rozszerzone maksymalnie",
        ),
      ),

      // 9. HIPER/HIPOKALIEMIA (DIALIZY)
      Scenario(
        id: "nzk_hyperkalemia_01",
        title: "Pominięta Dializa (Zab. Elektrolitowe)",
        dispatchInfo:
            "Starszy mężczyzna ze schyłkową niewydolnością nerek. Z powodu awarii auta pominął dwie ostatnie stacje dializ. Znaleziony rano bez funkcji życiowych.",
        sceneSizeUp:
            "Pacjent w łóżku. Widoczna przetoka tętniczo-żylna (Cimino-Brescii) na lewym przedramieniu.",
        initialRhythm: PatientRhythm
            .pvt, // Częstoskurcz bez tętna (pułapka na sprawdzenie tętna!)
        generatePatient: () => PatientModel(
          heartRate: 0,
          hasPulse: false,
          systolicBP: 0,
          diastolicBP: 0,
          spO2: null,
          etCo2: 0,
          temperature: 36.0,
          bloodGlucose: 140,
          weight: 78.0,
          hiddenCause: ReversibleCause.hypoHyperkalemia,
          skinCondition: "Szara, sucha, z obrzękami obwodowymi na nogach.",
          chestMovement: "Brak",
          pupils: "Lekko rozszerzone",
        ),
      ),

      // 10. HIPOKSJA (TONIĘCIE)
      Scenario(
        id: "nzk_hypoxia_02",
        title: "Wyciągnięty z Wody (Tonięcie)",
        dispatchInfo:
            "Zgłoszenie nad jeziorem. Młody mężczyzna wyciągnięty z wody po ok. 5 minutach pod powierzchnią. Plażowicze prowadzą chaotyczne RKO.",
        sceneSizeUp:
            "Mokry piasek, pacjent leży na plecach. Z ust i nosa wydobywa się piana. Środowisko zabezpieczone przez WOPR.",
        initialRhythm: PatientRhythm.asystole,
        generatePatient: () => PatientModel(
          heartRate: 0,
          hasPulse: false,
          systolicBP: 0,
          diastolicBP: 0,
          spO2: null,
          etCo2: 0,
          temperature: 34.0, // Lekka hipotermia wtórna do wody
          bloodGlucose: 110,
          weight: 82.0,
          hiddenCause: ReversibleCause
              .hypoxia, // Kluczem jest priorytet wentylacji w tonięciu (A-B-C zamiast C-A-B)
          skinCondition: "Mokra, sina, chłodna.",
          chestMovement: "Brak. Pienista wydzielina w ustach.",
          pupils: "Szerokie",
        ),
      ),
    ];
  }

  static Scenario getRandomScenario() {
    final scenarios = getAllScenarios();
    return scenarios[Random().nextInt(scenarios.length)];
  }
}
