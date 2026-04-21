import 'package:flutter/material.dart';
import 'logic/game_engine.dart';
import 'models/als_state.dart';
import 'widgets/inventory/ampularium.dart';

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
        title: const Text('Lifepak 15 (Wersja Małpia - Test)'),
        backgroundColor: Colors.red[900],
      ),
      body: AnimatedBuilder(
        animation: engine,
        builder: (context, child) {
          final state = engine.state;

          return Center(
            child: SingleChildScrollView(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    'Faza algorytmu: ${state.currentPhase.name.toUpperCase()}',
                    style: const TextStyle(fontSize: 20, color: Colors.blue),
                  ),
                  const SizedBox(height: 10),

                  Text(
                    state.currentPhase == ResuscitationPhase.analyzing
                        ? 'ANALIZA RYTMU...'
                        : 'Rytm: ${state.monitorRhythm.name.toUpperCase()}',
                    style: TextStyle(
                      fontSize: 32,
                      color: state.monitorRhythm == PatientRhythm.unknown
                          ? Colors.grey
                          : Colors.red,
                      fontWeight: FontWeight.bold,
                    ),
                  ),

                  const SizedBox(height: 10),

                  // Świecący wskaźnik RKO
                  if (state.isCprActive)
                    const Padding(
                      padding: EdgeInsets.all(8.0),
                      child: Text(
                        '🚨 RKO W TOKU 🚨',
                        style: TextStyle(
                          color: Colors.greenAccent,
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),

                  const SizedBox(height: 10),
                  Text(
                    'Czas do reoceny (RKO): ${state.cprSecondsRemaining} s',
                    style: const TextStyle(
                      fontSize: 48,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text('Całkowity czas akcji: ${state.totalElapsedGameTime} s'),
                  const SizedBox(height: 20),

                  Container(
                    padding: const EdgeInsets.all(16),
                    color: Colors.grey[800],
                    child: Column(
                      children: [
                        Text(
                          'Wyładowania: ${state.shocksDelivered}',
                          style: const TextStyle(fontSize: 20),
                        ),
                        Text(
                          'Defibrylator naładowany: ${state.isDefibCharged ? "TAK" : "NIE"}',
                          style: TextStyle(
                            fontSize: 20,
                            color: state.isDefibCharged
                                ? Colors.green
                                : Colors.white,
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 20),

                  Wrap(
                    spacing: 10,
                    children: [
                      ElevatedButton(
                        onPressed:
                            state.currentPhase ==
                                ResuscitationPhase.assessmentABCDE
                            ? engine.startScenario
                            : null,
                        child: const Text('PODŁĄCZ MONITOR'),
                      ),
                      ElevatedButton(
                        // Rozpocząć RKO można zawsze, gdy gra trwa i RKO jeszcze nie jest włączone
                        onPressed:
                            (state.currentPhase !=
                                    ResuscitationPhase.assessmentABCDE &&
                                !state.isCprActive)
                            ? engine.startCpr
                            : null,
                        child: const Text('ROZPOCZNIJ RKO'),
                      ),
                      ElevatedButton(
                        onPressed:
                            (state.currentPhase ==
                                    ResuscitationPhase.rhythmCheck ||
                                state.isCprActive)
                            ? engine.chargeDefibrillator
                            : null,
                        child: const Text('Ładuj Energię'),
                      ),
                      ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.orange,
                        ),
                        // Wyładowanie jest aktywne tylko i wyłącznie gdy jest energia
                        onPressed: state.isDefibCharged
                            ? engine.deliverShock
                            : null,
                        child: const Text('WYŁADOWANIE (SHOCK)'),
                      ),
                    ],
                  ),

                  const SizedBox(height: 40),

                  Container(
                    padding: const EdgeInsets.all(16),
                    color: Colors.blue[900],
                    child: Column(
                      children: [
                        ElevatedButton(
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
                          child: const Text(
                            'Otwórz Ampularium (Tacka na 2 leki)',
                          ),
                        ),
                        const SizedBox(height: 10),

                        if (state.preparedDrugs.isEmpty)
                          const Text(
                            'Tacka z lekami: PUSTA',
                            style: TextStyle(color: Colors.white, fontSize: 16),
                          ),

                        ...state.preparedDrugs.asMap().entries.map((entry) {
                          int index = entry.key;
                          String drugName = entry.value;
                          bool isReady = !drugName.startsWith(
                            'Przygotowywanie',
                          );

                          return Padding(
                            padding: const EdgeInsets.symmetric(vertical: 6.0),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  '💉 ${index + 1}: $drugName',
                                  style: TextStyle(
                                    color: isReady
                                        ? Colors.greenAccent
                                        : Colors.yellow,
                                    fontSize: 18,
                                  ),
                                ),
                                const SizedBox(width: 15),
                                if (isReady)
                                  ElevatedButton(
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: Colors.red,
                                    ),
                                    // Podać leki można tylko podczas uciśnięć!
                                    onPressed: state.isCprActive
                                        ? () => engine.administerDrug(index)
                                        : null,
                                    child: const Text('PODAĆ'),
                                  ),
                              ],
                            ),
                          );
                        }),
                      ],
                    ),
                  ),

                  // DZIENNIK BŁĘDÓW DO TESTÓW LOGIKI
                  if (state.log.isNotEmpty)
                    Container(
                      margin: const EdgeInsets.only(top: 20),
                      padding: const EdgeInsets.all(16),
                      color: Colors.black,
                      child: Column(
                        children: [
                          const Text(
                            'DZIENNIK ZDARZEŃ (Wypisze Ci błędy):',
                            style: TextStyle(
                              color: Colors.purpleAccent,
                              fontSize: 18,
                            ),
                          ),
                          ...state.log.map(
                            (logItem) => Text(
                              logItem,
                              style: TextStyle(
                                color: logItem.contains('BŁĄD')
                                    ? Colors.red
                                    : Colors.greenAccent,
                                fontSize: 16,
                              ),
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
