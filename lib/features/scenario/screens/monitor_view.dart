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
                    "RKO Timer",
                    "${state.cprSecondsRemaining} s",
                    state.isCprActive
                        ? Colors.greenAccent
                        : (state.cprSecondsRemaining == 0
                              ? Colors.redAccent
                              : Colors.grey),
                  ),
                  _buildMetric(
                    "ETCO2",
                    state.isCapnographyAttached ? '${state.etco2} mmHg' : '--',
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
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 20),
                decoration: BoxDecoration(
                  color: Colors.green[900]?.withOpacity(0.3),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Center(
                  child: Text(
                    state.currentPhase == ResuscitationPhase.analyzing
                        ? 'ANALIZA EKG...'
                        : 'EKG: ${state.monitorRhythm.name.toUpperCase()}',
                    style: TextStyle(
                      fontSize: 36,
                      color: state.currentPhase == ResuscitationPhase.analyzing
                          ? Colors.yellow
                          : Colors.greenAccent,
                      fontWeight: FontWeight.bold,
                    ),
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
