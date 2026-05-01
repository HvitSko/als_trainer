import 'package:flutter/material.dart';
import '../../logic/game_engine.dart';

class DiagnosticsDialog extends StatefulWidget {
  final GameEngine engine;

  const DiagnosticsDialog({super.key, required this.engine});

  @override
  State<DiagnosticsDialog> createState() => _DiagnosticsDialogState();
}

class _DiagnosticsDialogState extends State<DiagnosticsDialog> {
  final List<String> hCauses = [
    "Hipoksja",
    "Hipowolemia",
    "Hipo/Hiperkaliemia",
    "Hipotermia",
  ];
  final List<String> tCauses = [
    "Tamponada",
    "Toxins (Zatrucia)",
    "Tension pneumothorax (Odma)",
    "Thrombosis (Zator)",
  ];

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: widget.engine,
      builder: (context, _) {
        final state = widget.engine.state;

        return AlertDialog(
          backgroundColor: Colors.grey[900],
          title: const Text(
            'Diagnostyka & 4H4T',
            style: TextStyle(color: Colors.orangeAccent),
          ),
          content: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  '1. Badania Fizykalne (Wymagają czasu)',
                  style: TextStyle(color: Colors.grey),
                ),
                const SizedBox(height: 10),
                Wrap(
                  spacing: 10,
                  runSpacing: 10,
                  children: [
                    ElevatedButton.icon(
                      icon: const Icon(Icons.bloodtype),
                      label: Text(
                        state.isGlucoseMeasured
                            ? 'Glukoza: ${state.bloodGlucose}'
                            : 'Mierz Glukozę',
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: state.isGlucoseMeasured
                            ? Colors.green
                            : Colors.red[800],
                      ),
                      onPressed: state.isGlucoseMeasured
                          ? null
                          : () => widget.engine.measureGlucose(),
                    ),
                    ElevatedButton.icon(
                      icon: const Icon(Icons.thermostat),
                      label: Text(
                        state.isTempMeasured
                            ? 'Temp: ${state.temperature.toStringAsFixed(1)}°C'
                            : 'Mierz Temp.',
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: state.isTempMeasured
                            ? Colors.green
                            : Colors.blue[800],
                      ),
                      onPressed: state.isTempMeasured
                          ? null
                          : () => widget.engine.measureTemperature(),
                    ),
                    ElevatedButton.icon(
                      icon: const Icon(Icons.accessibility_new),
                      label: const Text('Badanie Urazowe (Exposure)'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: state.isPhysicalExamDone
                            ? Colors.green
                            : Colors.purple[800],
                      ),
                      onPressed: state.isPhysicalExamDone
                          ? null
                          : () => widget.engine.performPhysicalExam(),
                    ),
                  ],
                ),
                const Divider(color: Colors.grey, height: 30),

                const Text(
                  '2. Checklista Odwracalnych Przyczyn (Głośne myślenie)',
                  style: TextStyle(color: Colors.grey),
                ),
                const SizedBox(height: 10),
                const Text(
                  '4H',
                  style: TextStyle(
                    color: Colors.cyanAccent,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: hCauses.map((cause) {
                    bool considered = state.considered4H4T.contains(cause);
                    return ActionChip(
                      label: Text(
                        cause,
                        style: TextStyle(
                          color: considered ? Colors.black : Colors.white,
                        ),
                      ),
                      backgroundColor: considered
                          ? Colors.cyanAccent
                          : Colors.grey[800],
                      onPressed: considered
                          ? null
                          : () => widget.engine.considerCause(cause),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 10),
                const Text(
                  '4T',
                  style: TextStyle(
                    color: Colors.redAccent,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: tCauses.map((cause) {
                    bool considered = state.considered4H4T.contains(cause);
                    return ActionChip(
                      label: Text(
                        cause,
                        style: TextStyle(
                          color: considered ? Colors.black : Colors.white,
                        ),
                      ),
                      backgroundColor: considered
                          ? Colors.redAccent
                          : Colors.grey[800],
                      onPressed: considered
                          ? null
                          : () => widget.engine.considerCause(cause),
                    );
                  }).toList(),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text(
                'ZAMKNIJ',
                style: TextStyle(color: Colors.white),
              ),
            ),
          ],
        );
      },
    );
  }
}
