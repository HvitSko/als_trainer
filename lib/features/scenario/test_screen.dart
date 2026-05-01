import 'package:flutter/material.dart';
import 'logic/game_engine.dart';
import 'models/als_state.dart';
import 'widgets/inventory/ampularium.dart';
import 'widgets/inventory/airway_dialog.dart'; // NOWY IMPORT!
import 'widgets/inventory/diagnostics_dialog.dart';

class AlsTestScreen extends StatefulWidget {
  const AlsTestScreen({super.key});

  @override
  State<AlsTestScreen> createState() => _AlsTestScreenState();
}

class _AlsTestScreenState extends State<AlsTestScreen> {
  final GameEngine engine = GameEngine();

  @override
  void dispose() {
    engine.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Lifepak 15 (Zorin Edition)'),
        backgroundColor: Colors.red[900],
      ),
      body: AnimatedBuilder(
        animation: engine,
        builder: (context, child) {
          final state = engine.state;

          return Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // --- MONITOR GÓRNY ---
                  // --- MONITOR GÓRNY ---
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      Column(
                        children: [
                          const Text(
                            'Czas akcji',
                            style: TextStyle(color: Colors.grey),
                          ),
                          Text(
                            '${(state.totalElapsedGameTime ~/ 60).toString().padLeft(2, '0')}:${(state.totalElapsedGameTime % 60).toString().padLeft(2, '0')}',
                            style: const TextStyle(
                              fontSize: 32,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                      Column(
                        children: [
                          const Text(
                            'RKO Timer',
                            style: TextStyle(color: Colors.orange),
                          ),
                          Text(
                            '${state.cprSecondsRemaining} s',
                            style: TextStyle(
                              fontSize: 48,
                              fontWeight: FontWeight.bold,
                              color: state.isCprActive
                                  ? Colors.greenAccent
                                  : (state.cprSecondsRemaining == 0
                                        ? Colors.redAccent
                                        : Colors.grey),
                            ),
                          ),
                        ],
                      ),
                      // NOWE: MONITOR ETCO2
                      Column(
                        children: [
                          const Text(
                            'ETCO2',
                            style: TextStyle(color: Colors.yellowAccent),
                          ),
                          Text(
                            state.isCapnographyAttached
                                ? '${state.etco2}'
                                : '--',
                            style: const TextStyle(
                              fontSize: 32,
                              fontWeight: FontWeight.bold,
                              color: Colors.yellowAccent,
                            ),
                          ),
                          const Text(
                            'mmHg',
                            style: TextStyle(color: Colors.grey, fontSize: 12),
                          ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),

                  Text(
                    'Faza: ${state.currentPhase.name.toUpperCase()}',
                    style: const TextStyle(fontSize: 20, color: Colors.blue),
                  ),
                  const SizedBox(height: 10),

                  Text(
                    state.currentPhase == ResuscitationPhase.analyzing
                        ? 'ANALIZA EKG...'
                        : 'EKG: ${state.monitorRhythm.name.toUpperCase()}',
                    style: TextStyle(
                      fontSize: 36,
                      color: state.currentPhase == ResuscitationPhase.analyzing
                          ? Colors.yellow
                          : Colors.red,
                      fontWeight: FontWeight.bold,
                    ),
                  ),

                  const SizedBox(height: 20),

                  // --- PANEL AKCJI ---
                  Wrap(
                    spacing: 10,
                    runSpacing: 10,
                    alignment: WrapAlignment.center,
                    children: [
                      ElevatedButton(
                        onPressed:
                            state.currentPhase ==
                                ResuscitationPhase.assessmentABCDE
                            ? engine.connectMonitor
                            : null,
                        child: const Text('PODŁĄCZ MONITOR'),
                      ),
                      ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green[700],
                        ),
                        onPressed:
                            (state.currentPhase !=
                                    ResuscitationPhase.assessmentABCDE &&
                                !state.isCprActive)
                            ? engine.startCpr
                            : null,
                        child: const Text('ROZPOCZNIJ RKO'),
                      ),
                      ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.blue[600],
                        ),
                        onPressed: state.isCprActive
                            ? engine.stopCprAndAssess
                            : null,
                        child: const Text('ZATRZYMAJ RKO / OCEŃ RYTM'),
                      ),
                    ],
                  ),

                  const SizedBox(height: 10),

                  // --- PANEL DEFIBRYLATORA ---
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.grey[800],
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Wrap(
                      alignment: WrapAlignment.center,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      spacing: 10,
                      runSpacing: 10,
                      children: [
                        const Text(
                          'Energia: ',
                          style: TextStyle(color: Colors.white, fontSize: 16),
                        ),
                        DropdownButton<int>(
                          value: state.selectedEnergy,
                          dropdownColor: Colors.grey[900],
                          style: const TextStyle(
                            color: Colors.yellow,
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                          items: [150, 200, 300, 360]
                              .map(
                                (e) => DropdownMenuItem(
                                  value: e,
                                  child: Text('${e}J'),
                                ),
                              )
                              .toList(),
                          onChanged:
                              (state.isDefibCharging || state.isDefibCharged)
                              ? null
                              : (val) {
                                  if (val != null) engine.setEnergy(val);
                                },
                        ),
                        ElevatedButton(
                          onPressed:
                              (state.currentPhase !=
                                      ResuscitationPhase.assessmentABCDE) &&
                                  !state.isDefibCharged &&
                                  !state.isDefibCharging
                              ? engine.chargeDefibrillator
                              : null,
                          child: Text(
                            state.isDefibCharging ? 'ŁADOWANIE...' : 'ŁADUJ',
                          ),
                        ),
                        // NOWY PRZYCISK: ROZŁADOWANIE
                        ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: state.isDefibCharged
                                ? Colors.blueGrey[700]
                                : Colors.grey[900],
                            padding: const EdgeInsets.symmetric(
                              horizontal: 15,
                              vertical: 15,
                            ),
                          ),
                          onPressed: state.isDefibCharged
                              ? engine.disarmDefibrillator
                              : null,
                          child: const Text(
                            'ROZŁADUJ',
                            style: TextStyle(color: Colors.white),
                          ),
                        ),
                        ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: state.isDefibCharged
                                ? Colors.red
                                : Colors.grey[900],
                            padding: const EdgeInsets.symmetric(
                              horizontal: 20,
                              vertical: 15,
                            ),
                          ),
                          onPressed: state.isDefibCharged
                              ? engine.deliverShock
                              : null,
                          child: const Text(
                            'SHOCK',
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 30),

                  // --- ZASOBY I DIAGNOSTYKA ---
                  Wrap(
                    spacing: 10,
                    runSpacing: 10,
                    alignment: WrapAlignment.center,
                    children: [
                      ElevatedButton.icon(
                        icon: const Icon(Icons.medical_services),
                        label: const Text('Ampularium'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.blue[900],
                        ),
                        onPressed:
                            (state.isPreparingDrug ||
                                state.preparedDrugs.length >= 2)
                            ? null
                            : () {
                                showDialog(
                                  context: context,
                                  builder: (context) => AmpulariumDialog(
                                    onDrugPrepared: (drug, dose) =>
                                        engine.prepareDrug(drug, dose),
                                  ),
                                );
                              },
                      ),
                      ElevatedButton.icon(
                        icon: const Icon(Icons.air),
                        label: const Text('Torba Oddechowa'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.cyan[800],
                        ),
                        onPressed: () {
                          showDialog(
                            context: context,
                            builder: (context) => AirwayDialog(engine: engine),
                          );
                        },
                      ),
                      ElevatedButton.icon(
                        icon: const Icon(Icons.search),
                        label: const Text('4H4T & Badanie'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.orange[900],
                        ),
                        onPressed: () {
                          showDialog(
                            context: context,
                            builder: (context) =>
                                DiagnosticsDialog(engine: engine),
                          );
                        },
                      ),
                    ],
                  ),

                  const SizedBox(height: 10),

                  // Wyświetlanie przygotowanych leków
                  if (state.preparedDrugs.isNotEmpty)
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.black45,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Column(
                        children: state.preparedDrugs.asMap().entries.map((
                          entry,
                        ) {
                          int index = entry.key;
                          String drugNameRaw = entry.value;
                          bool isReady = !drugNameRaw.startsWith(
                            'Przygotowywanie',
                          );
                          String displayName = drugNameRaw.replaceAll('|', ' ');

                          return Padding(
                            padding: const EdgeInsets.symmetric(vertical: 4.0),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  '💉 $displayName',
                                  style: TextStyle(
                                    color: isReady
                                        ? Colors.greenAccent
                                        : Colors.yellow,
                                    fontSize: 16,
                                  ),
                                ),
                                const SizedBox(width: 15),
                                if (isReady)
                                  ElevatedButton(
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: Colors.red,
                                    ),
                                    onPressed: () =>
                                        engine.administerDrug(index),
                                    child: const Text('PODAĆ'),
                                  ),
                              ],
                            ),
                          );
                        }).toList(),
                      ),
                    ),

                  const SizedBox(height: 20),

                  // --- DZIENNIK ZDARZEŃ ---
                  Container(
                    height: 250,
                    width: double.infinity,
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.black87,
                      border: Border.all(color: Colors.grey),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'DZIENNIK ZDARZEŃ (EBM)',
                          style: TextStyle(
                            color: Colors.purpleAccent,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const Divider(color: Colors.grey),
                        Expanded(
                          child: ListView.builder(
                            itemCount: state.log.length,
                            itemBuilder: (context, index) {
                              String logItem = state.log[index];
                              Color textColor = Colors.white70;
                              if (logItem.contains('KRYTYCZNY BŁĄD') ||
                                  logItem.contains('BŁĄD EBM'))
                                textColor = Colors.redAccent;
                              else if (logItem.contains('SUKCES'))
                                textColor = Colors.greenAccent;
                              else if (logItem.contains('DIAGNOZA'))
                                textColor = Colors.orangeAccent;
                              else if (logItem.contains('OSTRZEŻENIE'))
                                textColor = Colors.yellowAccent;

                              return Padding(
                                padding: const EdgeInsets.only(bottom: 4.0),
                                child: Text(
                                  logItem,
                                  style: TextStyle(
                                    color: textColor,
                                    fontSize: 14,
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
