import 'package:flutter/material.dart';
import '../../logic/game_engine.dart';

class DiagnosticsDialog extends StatelessWidget {
  final GameEngine engine;
  const DiagnosticsDialog({super.key, required this.engine});

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: engine,
      builder: (context, _) {
        final state = engine.state;
        return AlertDialog(
          backgroundColor: Colors.grey[900],
          title: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Torba Medyczna R1/ALS',
                style: TextStyle(color: Colors.orangeAccent),
              ),
              IconButton(
                icon: const Icon(Icons.close, color: Colors.red),
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
                onPressed: () => Navigator.of(context).pop(),
              ),
            ],
          ),
          content: SingleChildScrollView(
            child: Wrap(
              spacing: 10,
              runSpacing: 10,
              children: [
                ElevatedButton.icon(
                  icon: const Icon(Icons.bloodtype),
                  label: Text(
                    state.isGlucoseMeasured
                        ? 'Glukoza: ${state.patient.bloodGlucose}'
                        : 'Glikemia',
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: state.isGlucoseMeasured
                        ? Colors.green
                        : Colors.red[800],
                  ),
                  onPressed: state.isGlucoseMeasured
                      ? null
                      : () => engine.measureGlucose(),
                ),
                ElevatedButton.icon(
                  icon: const Icon(Icons.thermostat),
                  label: Text(
                    state.isTempMeasured
                        ? 'Temp: ${state.patient.temperature.toStringAsFixed(1)}°C'
                        : 'Termometr',
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: state.isTempMeasured
                        ? Colors.green
                        : Colors.blue[800],
                  ),
                  onPressed: state.isTempMeasured
                      ? null
                      : () => engine.measureTemperature(),
                ),
                ElevatedButton.icon(
                  icon: const Icon(Icons.monitor_heart_outlined),
                  label: Text(
                    state.isSpO2Attached ? 'SpO2: Podłączono' : 'Podłącz SpO2',
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: state.isSpO2Attached
                        ? Colors.green
                        : Colors.teal[700],
                  ),
                  onPressed: () => engine.attachSpO2(),
                ),
                ElevatedButton.icon(
                  icon: const Icon(Icons.visibility),
                  label: const Text('Exposure (Urazowe)'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: state.isPhysicalExamDone
                        ? Colors.green
                        : Colors.purple[800],
                  ),
                  onPressed: state.isPhysicalExamDone
                      ? null
                      : () => engine.performPhysicalExam(),
                ),
                ElevatedButton.icon(
                  icon: const Icon(Icons.waves),
                  label: Text(
                    state.isUsgDone
                        ? 'USG: eFAST zrobione'
                        : 'USG: Hokus POCUS',
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: state.isUsgDone
                        ? Colors.green
                        : Colors.indigo[800],
                  ),
                  onPressed: state.isUsgDone
                      ? null
                      : () {
                          Navigator.of(context).pop();
                          engine.performUSG();
                        },
                ),
                // NOWE - TERAPIA
                const Divider(color: Colors.grey),
                ElevatedButton.icon(
                  icon: const Icon(Icons.ac_unit),
                  label: Text(
                    state.isWarmingProvided
                        ? 'Ogrzewanie wdrożone'
                        : 'Okryj / Ogrzej (Folia NRC)',
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: state.isWarmingProvided
                        ? Colors.green
                        : Colors.deepOrange[800],
                  ),
                  onPressed: state.isWarmingProvided
                      ? null
                      : () => engine.provideThermalComfort(),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
