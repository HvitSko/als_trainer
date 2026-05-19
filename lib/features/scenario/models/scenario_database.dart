import 'dart:math';
import 'scenario_model.dart';
import 'patient_model.dart';
import 'als_state.dart';
import '../../../app_localization.dart'; // IMPORT TŁUMACZA

class ScenarioDatabase {
  static List<Scenario> getAllScenarios() {
    return [
      // 1. ZATRUCIE (TOXINS)
      Scenario(
        id: 'tox_opioid_01',
        title: AppLoc.tr(
          'Zatrucie Opioidami (Toxins)',
          'Opioid Overdose (Toxins)',
        ),
        dispatchInfo: AppLoc.tr(
          'Wezwanie z CPR: Mężczyzna, ok. 30 lat, nieprzytomny, nie oddycha. Zgłasza sąsiadka, która znalazła go na klatce schodowej.',
          'Dispatch: Male, approx. 30 y/o, unconscious, not breathing. Reported by a neighbor who found him in the stairwell.',
        ),
        sceneSizeUp: AppLoc.tr(
          'Mieszkanie otwarte. Pacjent leży na podłodze. Obok leżą puste blistry po Fentanylu i Tramadolu. Brak innych osób. Środowisko bezpieczne.',
          'Door open. Patient lying on the floor. Empty Fentanyl and Tramadol blister packs nearby. No bystanders. Scene is safe.',
        ),
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
          skinCondition: AppLoc.tr(
            'Zasiniona (centralnie i obwodowo), chłodna, lepka',
            'Cyanotic (central and peripheral), cool, clammy',
          ),
          chestMovement: AppLoc.tr(
            'Brak ruchów oddechowych',
            'No respiratory effort',
          ),
          pupils: AppLoc.tr(
            'Szpilkowate (szczególnie wąskie), brak reakcji na światło!',
            'Pinpoint, non-reactive to light!',
          ),
        ),
      ),

      // 2. HIPOTERMIA
      Scenario(
        id: "nzk_hypothermia_01",
        title: AppLoc.tr(
          "Mroźny Poranek (Hipotermia)",
          "Freezing Morning (Hypothermia)",
        ),
        dispatchInfo: AppLoc.tr(
          "ZRM zadysponowany do mężczyzny leżącego na przystanku autobusowym. Temperatura otoczenia -5°C. Pacjent bezdomny, brak reakcji, brak oddechu.",
          "EMS dispatched to a male lying at a bus stop. Ambient temp -5°C (23°F). Homeless patient, unresponsive, apneic.",
        ),
        sceneSizeUp: AppLoc.tr(
          "Pustostan. Brak ogrzewania. Pacjent leży na betonie w mokrym ubraniu. Czuć silną woń alkoholu.",
          "Abandoned building. No heating. Patient lying on concrete in wet clothes. Strong odor of alcohol.",
        ),
        initialRhythm: PatientRhythm.pea,
        generatePatient: () => PatientModel(
          heartRate: 0,
          hasPulse: false,
          systolicBP: 0,
          diastolicBP: 0,
          spO2: null,
          etCo2: 0,
          temperature: 28.5,
          bloodGlucose: 65,
          weight: 65.0,
          hiddenCause: ReversibleCause.hypothermia,
          skinCondition: AppLoc.tr(
            "Lodowata, blada, marmurkowata",
            "Ice-cold, pale, mottled",
          ),
          chestMovement: AppLoc.tr("Brak", "None"),
          pupils: AppLoc.tr("Szerokie, sztywne", "Dilated, fixed"),
        ),
      ),

      // 3. HIPOWOLEMIA
      Scenario(
        id: "nzk_hypovolemia_01",
        title: AppLoc.tr(
          "Czarne Wymioty (Hipowolemia)",
          "Black Vomit (Hypovolemia)",
        ),
        dispatchInfo: AppLoc.tr(
          "Kobieta ze znaną chorobą alkoholową i marskością wątroby. Zgłoszono masywne, fusowate wymioty. Zespół wchodzi, pacjentka traci przytomność i przestaje oddychać.",
          "Female with known history of alcoholism and liver cirrhosis. Massive coffee-ground emesis reported. Patient loses consciousness and stops breathing upon EMS arrival.",
        ),
        sceneSizeUp: AppLoc.tr(
          "Kałuża fusowatych treści i jasnoczerwonej krwi na podłodze. Skrajne odwodnienie. Środowisko bezpieczne.",
          "Pool of coffee-ground emesis and bright red blood on the floor. Severe dehydration. Scene is safe.",
        ),
        initialRhythm: PatientRhythm.pea,
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
          hiddenCause: ReversibleCause.hypovolemia,
          skinCondition: AppLoc.tr(
            "Ekstremalnie blada, zlana zimnym potem.",
            "Extremely pale, diaphoretic.",
          ),
          chestMovement: AppLoc.tr(
            "Brak ruchów oddechowych",
            "No respiratory effort",
          ),
          pupils: AppLoc.tr(
            "Szerokie, reagujące leniwie",
            "Dilated, sluggish reaction",
          ),
        ),
      ),

      // 4. ODMA PRĘŻNA
      Scenario(
        id: "nzk_pneumothorax_01",
        title: AppLoc.tr(
          "Duszność i Cisza (Odma Prężna)",
          "Dyspnea and Silence (Tension Pneumothorax)",
        ),
        dispatchInfo: AppLoc.tr(
          "19-latek z ciężką astmą oskrzelową. Nagłe, gwałtowne pogorszenie, silna duszność, a potem zatrzymanie krążenia przed przybyciem ZRM.",
          "19 y/o male with severe bronchial asthma. Sudden severe exacerbation, acute dyspnea, followed by cardiac arrest prior to EMS arrival.",
        ),
        sceneSizeUp: AppLoc.tr(
          "Pacjent leży na podłodze w pokoju. W wywiadzie od rodziny wielokrotne hospitalizacje z powodu astmy. Klatka piersiowa beczkowata.",
          "Patient lying on the floor in his room. Family reports multiple previous ICU admissions for asthma. Barrel chest.",
        ),
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
          hiddenCause: ReversibleCause.tensionPneumothorax,
          skinCondition: AppLoc.tr(
            "Masywna sinica twarzy i szyi.",
            "Massive cyanosis of the face and neck.",
          ),
          chestMovement: AppLoc.tr(
            "Brak własnych ruchów oddechowych",
            "No spontaneous respiratory effort",
          ),
          pupils: AppLoc.tr("Umiarkowanie szerokie", "Moderately dilated"),
        ),
      ),

      // 5. ZATOROWOŚĆ
      Scenario(
        id: "nzk_thrombosis_01",
        title: AppLoc.tr(
          "Powrót z Azji (Zatorowość)",
          "Return from Asia (Thrombosis/PE)",
        ),
        dispatchInfo: AppLoc.tr(
          "Kobieta zasłabła na lotnisku. Wczoraj wróciła z 14-godzinnego lotu z Tajlandii. Zgłaszała ból w klatce piersiowej i duszność.",
          "Female collapsed at the airport. Returned yesterday from a 14-hour flight from Thailand. Complained of chest pain and dyspnea.",
        ),
        sceneSizeUp: AppLoc.tr(
          "Brak urazów. W wywiadzie od męża: lot długodystansowy, pacjentka przyjmuje antykoncepcję hormonalną.",
          "No signs of trauma. Husband reports long-haul flight and that the patient is on oral contraceptives.",
        ),
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
          hiddenCause: ReversibleCause.thrombosis,
          skinCondition: AppLoc.tr(
            "Sina od pasa w górę, zaczerwienienie i obrzęk prawej łydki.",
            "Cyanotic from the waist up, erythema and swelling of the right calf.",
          ),
          chestMovement: AppLoc.tr("Brak", "None"),
          pupils: AppLoc.tr("Szerokie", "Dilated"),
        ),
      ),

      // 6. TAMPONADA OSIERDZIA
      Scenario(
        id: "nzk_tamponade_01",
        title: AppLoc.tr(
          "Kierownica na Klatce (Tamponada)",
          "Steering Wheel Trauma (Tamponade)",
        ),
        dispatchInfo: AppLoc.tr(
          "Wypadek komunikacyjny. Auto uderzyło w drzewo. Uderzenie klatką piersiową w kierownicę (brak zapiętych pasów).",
          "Motor vehicle collision. Car hit a tree. Blunt chest trauma from steering wheel impact (unrestrained driver).",
        ),
        sceneSizeUp: AppLoc.tr(
          "Zatrzymanie krążenia następuje w trakcie transportu do karetki. Pacjentka na noszach.",
          "Cardiac arrest occurs during transport to the ambulance. Patient is on the stretcher.",
        ),
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
          hiddenCause: ReversibleCause.tamponade,
          skinCondition: AppLoc.tr(
            "Blada, z rozległym zasinieniem w centralnej części klatki piersiowej.",
            "Pale, with extensive bruising over the central chest (sternum).",
          ),
          chestMovement: AppLoc.tr("Brak", "None"),
          pupils: AppLoc.tr(
            "Rozszerzone, brak reakcji",
            "Dilated, non-reactive",
          ),
        ),
      ),

      // 7. ZAWAŁ SERCA (CZYSTE NZK DO DEFIBRYLACJI)
      Scenario(
        id: "nzk_stemi_02",
        title: AppLoc.tr(
          "Ból w Klatce na Siłowni (Standard / VF)",
          "Chest Pain at the Gym (Standard / VF)",
        ),
        dispatchInfo: AppLoc.tr(
          "45-letni mężczyzna zgłosił silny ból w klatce piersiowej podczas wyciskania sztangi. Upadł nieprzytomny. Świadkowie podjęli RKO.",
          "45 y/o male reported severe chest pain while bench pressing. Collapsed unconscious. Bystander CPR in progress.",
        ),
        sceneSizeUp: AppLoc.tr(
          "Siłownia. Dobrej postury mężczyzna. Na podłodze AED z naklejonymi elektrodami (nierozładowane).",
          "Gym. Well-built male. AED with attached pads on the floor (no shocks delivered yet).",
        ),
        initialRhythm: PatientRhythm.vf,
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
          hiddenCause: ReversibleCause.none,
          skinCondition: AppLoc.tr(
            "Zlana ciepłym potem, zaczerwieniona po wysiłku.",
            "Diaphoretic (warm sweat), flushed from exertion.",
          ),
          chestMovement: AppLoc.tr(
            "Brak własnych ruchów oddechowych",
            "No spontaneous respiratory effort",
          ),
          pupils: AppLoc.tr(
            "Szerokie, wolna reakcja",
            "Dilated, sluggish reaction",
          ),
        ),
      ),

      // 8. HIPOKSJA (ZADŁAWIENIE)
      Scenario(
        id: "nzk_hypoxia_01",
        title: AppLoc.tr(
          "Niedzielny Obiad (Hipoksja)",
          "Sunday Dinner (Hypoxia)",
        ),
        dispatchInfo: AppLoc.tr(
          "Mężczyzna zadławił się kawałkiem mięsa podczas obiadu rodzinnego. Próby rękoczynu Heimlicha przez bliskich nieskuteczne. Doszło do NZK.",
          "Male choked on a piece of meat during a family dinner. Bystander Heimlich maneuver unsuccessful. Progressed to cardiac arrest.",
        ),
        sceneSizeUp: AppLoc.tr(
          "Brak urazów. Zespół zastaje pacjenta na podłodze. Obecne resztki jedzenia w jamie ustnej (wskazana pilna intubacja/SGA i odsysanie).",
          "No trauma. EMS finds patient on the floor. Food debris visible in the oral cavity (urgent suction/SGA/intubation indicated).",
        ),
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
          skinCondition: AppLoc.tr(
            "Głęboko sina (cyjanotyczna) twarz i usta.",
            "Deeply cyanotic face and lips.",
          ),
          chestMovement: AppLoc.tr("Brak", "None"),
          pupils: AppLoc.tr("Rozszerzone maksymalnie", "Maximally dilated"),
        ),
      ),

      // 9. HIPER/HIPOKALIEMIA (DIALIZY)
      Scenario(
        id: "nzk_hyperkalemia_01",
        title: AppLoc.tr(
          "Pominięta Dializa (Zab. Elektrolitowe)",
          "Missed Dialysis (Electrolytes)",
        ),
        dispatchInfo: AppLoc.tr(
          "Starszy mężczyzna ze schyłkową niewydolnością nerek. Z powodu awarii auta pominął dwie ostatnie stacje dializ. Znaleziony rano bez funkcji życiowych.",
          "Elderly male with end-stage renal disease (ESRD). Missed last two dialysis sessions due to car breakdown. Found pulseless in the morning.",
        ),
        sceneSizeUp: AppLoc.tr(
          "Pacjent w łóżku. Widoczna przetoka tętniczo-żylna (Cimino-Brescii) na lewym przedramieniu.",
          "Patient in bed. Visible arteriovenous (AV) fistula (Cimino-Brescia) on the left forearm.",
        ),
        initialRhythm: PatientRhythm.pvt,
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
          skinCondition: AppLoc.tr(
            "Szara, sucha, z obrzękami obwodowymi na nogach.",
            "Ashen, dry, with peripheral pitting edema on the legs.",
          ),
          chestMovement: AppLoc.tr("Brak", "None"),
          pupils: AppLoc.tr("Lekko rozszerzone", "Mildly dilated"),
        ),
      ),

      // 10. HIPOKSJA (TONIĘCIE)
      Scenario(
        id: "nzk_hypoxia_02",
        title: AppLoc.tr(
          "Wyciągnięty z Wody (Tonięcie)",
          "Pulled from Water (Drowning)",
        ),
        dispatchInfo: AppLoc.tr(
          "Zgłoszenie nad jeziorem. Młody mężczyzna wyciągnięty z wody po ok. 5 minutach pod powierzchnią. Plażowicze prowadzą chaotyczne RKO.",
          "Lake emergency call. Young male pulled from water after approx. 5 minutes submerged. Bystanders performing chaotic CPR.",
        ),
        sceneSizeUp: AppLoc.tr(
          "Mokry piasek, pacjent leży na plecach. Z ust i nosa wydobywa się piana. Środowisko zabezpieczone przez WOPR.",
          "Wet sand, patient lying supine. Froth exuding from mouth and nose. Scene secured by lifeguards.",
        ),
        initialRhythm: PatientRhythm.asystole,
        generatePatient: () => PatientModel(
          heartRate: 0,
          hasPulse: false,
          systolicBP: 0,
          diastolicBP: 0,
          spO2: null,
          etCo2: 0,
          temperature: 34.0,
          bloodGlucose: 110,
          weight: 82.0,
          hiddenCause: ReversibleCause.hypoxia,
          skinCondition: AppLoc.tr(
            "Mokra, sina, chłodna.",
            "Wet, cyanotic, cold.",
          ),
          chestMovement: AppLoc.tr(
            "Brak. Pienista wydzielina w ustach.",
            "None. Frothy secretions in the oral cavity.",
          ),
          pupils: AppLoc.tr("Szerokie", "Dilated"),
        ),
      ),
    ];
  }

  static Scenario getRandomScenario() {
    final scenarios = getAllScenarios();
    return scenarios[Random().nextInt(scenarios.length)];
  }
}
