import 'package:flutter/material.dart';
import '../logic/game_engine.dart';
import '../models/als_state.dart';

class MonitorView extends StatelessWidget {
  final GameEngine engine;

  const MonitorView({super.key, required this.engine});

  Color? get textColor => null;

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: engine,
      builder: (context, _) {
        final state = engine.state;

        return Container(
          color: Colors.black87,
          // Przenosimy stary padding do SingleChildScrollView, żeby zyskać na kontroli!
          child: SafeArea(
            child: SingleChildScrollView(
              // 120 pikseli na dole ratuje życie (i UI) przed zgnieceniem przez dolne przyciski!
              padding: const EdgeInsets.only(
                left: 16,
                top: 16,
                right: 16,
                bottom: 120,
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.start,
                children: [
                  // --- GÓRNY PASEK PARAMETRÓW ---
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _buildMetric(
                        "Czas akcji",
                        "${(state.totalElapsedGameTime ~/ 60).toString().padLeft(2, '0')}:${(state.totalElapsedGameTime % 60).toString().padLeft(2, '0')}",
                        Colors.white,
                      ),
                      _buildMetric(
                        "RKO",
                        "${state.cprSecondsRemaining} s",
                        state.isCprActive
                            ? Colors.greenAccent
                            : (state.cprSecondsRemaining == 0
                                  ? Colors.redAccent
                                  : Colors.grey),
                      ), // POWRÓT SYNA MARNOTRAWNEGO
                      _buildMetric(
                        "SpO2",
                        state.isSpO2Attached
                            ? (state.patient.hasPulse
                                  ? '${state.patient.spO2}%'
                                  : '--%')
                            : 'Odł.',
                        Colors.cyanAccent,
                      ),
                      _buildMetric(
                        "ETCO2",
                        state.isCapnographyAttached
                            ? '${state.patient.etCo2} mmHg'
                            : '--',
                        Colors.yellowAccent,
                      ),
                    ],
                  ),
                  const Divider(color: Colors.grey, height: 30),

                  // --- EKG I STAN ---
                  Text(
                    'Faza: ${state.currentPhase.name.toUpperCase()}',
                    style: const TextStyle(fontSize: 16, color: Colors.blue),
                  ),
                  const SizedBox(height: 10),
                  // --- EKG I STAN ---
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(vertical: 20),
                    decoration: BoxDecoration(
                      color: Colors.green[900]?.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Center(
                      child: Builder(
                        builder: (context) {
                          String ekgText;
                          Color ekgColor;

                          if (state.currentPhase ==
                              ResuscitationPhase.assessmentABCDE) {
                            ekgText = 'BRAK SYGNAŁU (PODŁĄCZ MONITOR)';
                            ekgColor = Colors.grey;
                          } else if (state.currentPhase ==
                              ResuscitationPhase.analyzing) {
                            ekgText = 'ANALIZA EKG...';
                            ekgColor = Colors.yellow;
                          } else {
                            ekgText =
                                'EKG: ${state.monitorRhythm.name.toUpperCase()}';
                            ekgColor = Colors.greenAccent;
                          }

                          return Text(
                            ekgText,
                            style: TextStyle(
                              fontSize: 28,
                              color: ekgColor,
                              fontWeight: FontWeight.bold,
                            ),
                          );
                        },
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),

                  // --- KLAWIATURA STERUJĄCA MONITORA ---
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
                      color: Colors.grey[850],
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
                        ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: state.isDefibCharged
                                ? Colors.blueGrey[700]
                                : Colors.grey[900],
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
                  const SizedBox(height: 20),

                  // --- DZIENNIK ZDARZEŃ ---
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.grey[900],
                      borderRadius: BorderRadius.circular(8),
                    ),
                    padding: const EdgeInsets.all(8),
                    // ... reszta ustawień Twojego kontenera ...
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        const Text(
                          "DZIENNIK ZDARZEŃ",
                          style: TextStyle(color: Colors.grey),
                        ),
                        const SizedBox(height: 8),

                        // Sam ListView.builder, ALE Z DWOMA NOWYMI LINIKAMI!
                        ListView.builder(
                          shrinkWrap:
                              true, // ZMUSZA LISTĘ DO ZAJĘCIA TYLKO TYLE MIEJSCA, ILE POTRZEBUJĄ JEJ ELEMENTY!
                          physics:
                              const NeverScrollableScrollPhysics(), // WYŁĄCZA WEWNĘTRZNE PRZEWIJANIE (przewija się cały monitor)
                          itemCount: state.log.length,
                          itemBuilder: (context, index) {
                            String logMsg = state.log[index];
                            // ... tu zostaje Twoja logika kolorowania tekstów ...
                            return Padding(
                              padding: const EdgeInsets.only(bottom: 4.0),
                              child: Text(
                                logMsg,
                                style: TextStyle(
                                  color: textColor,
                                  fontSize: 13,
                                ),
                              ),
                            );
                          },
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(
                    height: 80,
                  ), // Margines na globalny pasek narzędzi
                ], // To zamyka listę children w Column
              ), // Zamyka Column
            ), // Zamyka SingleChildScrollView
          ), // Zamyka SafeArea
        ); // Zamyka Container
      }, // Zamyka builder w AnimatedBuilder
    ); // Zamyka AnimatedBuilder (return)
  } // Zamyka metodę build(BuildContext context)

  Widget _buildMetric(String label, String value, Color color) {
    return Column(
      children: [
        Text(label, style: const TextStyle(color: Colors.grey, fontSize: 12)),
        Text(
          value,
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
      ],
    );
  }
}
