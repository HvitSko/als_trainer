import 'package:flutter/material.dart';
import '../logic/game_engine.dart';
import '../models/als_state.dart';

class MonitorView extends StatelessWidget {
  final GameEngine engine;

  const MonitorView({super.key, required this.engine});

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: engine,
      builder: (context, _) {
        final state = engine.state;

        return Container(
          color: Colors.black87,
          padding: const EdgeInsets.all(16),
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
                    "SpO2",
                    state.isSpO2Attached
                        ? (state.patient.hasPulse
                              ? '${state.patient.spO2}%'
                              : '--%')
                        : 'Odł.',
                    Colors.cyanAccent,
                  ), // ZMIANA!
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
                        state.currentPhase == ResuscitationPhase.assessmentABCDE
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
                      onChanged: (state.isDefibCharging || state.isDefibCharged)
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
              Expanded(
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.black,
                    border: Border.all(color: Colors.grey[800]!),
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
                                logItem.contains('BŁĄD EBM')) {
                              textColor = Colors.redAccent;
                            } else if (logItem.contains('SUKCES'))
                              // ignore: curly_braces_in_flow_control_structures
                              textColor = Colors.greenAccent;
                            else if (logItem.contains('DIAGNOZA'))
                              // ignore: curly_braces_in_flow_control_structures
                              textColor = Colors.orangeAccent;
                            else if (logItem.contains('OSTRZEŻENIE'))
                              // ignore: curly_braces_in_flow_control_structures
                              textColor = Colors.yellowAccent;
                            return Padding(
                              padding: const EdgeInsets.only(bottom: 4.0),
                              child: Text(
                                logItem,
                                style: TextStyle(
                                  color: textColor,
                                  fontSize: 13,
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 80), // Margines na globalny pasek narzędzi
            ],
          ),
        );
      },
    );
  }

  Widget _buildMetric(String label, String value, Color color) {
    return Column(
      children: [
        Text(label, style: const TextStyle(color: Colors.grey, fontSize: 12)),
        Text(
          value,
          style: TextStyle(
            fontSize: 32,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
      ],
    );
  }
}
