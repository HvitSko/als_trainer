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
                      icon: const Icon(Icons.ac_unit),
                      label: Text(
                        state.isWarmingProvided
                            ? 'Ogrzewanie włączone'
                            : 'Zapewnij Komfort Termiczny (Ogrzewaj)',
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: state.isWarmingProvided
                            ? Colors.green
                            : Colors.blueGrey,
                      ),
                      onPressed: state.isWarmingProvided
                          ? null
                          : () => widget.engine.provideThermalComfort(),
                    ),
                    ElevatedButton.icon(
                      icon: const Icon(Icons.bloodtype),
                      label: Text(
                        state.isGlucoseMeasured
                            ? 'Glukoza: ${state.patient.bloodGlucose}'
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
                            ? 'Temp: ${state.patient.temperature.toStringAsFixed(1)}°C'
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
                    int status = state.h4tStatus[cause] ?? 0;
                    Color bgColor = Colors.grey[800]!;
                    if (status == 1) bgColor = Colors.green[800]!;
                    if (status == -1)
                      bgColor = Colors
                          .redAccent; // Tutaj mrugałoby na czerwono (na razie dajemy statyczny czerwony)

                    return GestureDetector(
                      onLongPress: () => _showEvaluationDialog(context, cause),
                      child: ActionChip(
                        label: Text(
                          cause,
                          style: const TextStyle(color: Colors.white),
                        ),
                        backgroundColor: bgColor,
                        onPressed: () => widget.engine.considerCause(
                          cause,
                        ), // Krótkie kliknięcie = Zespół rozważa
                      ),
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
                    int status = state.h4tStatus[cause] ?? 0;
                    Color bgColor = Colors.grey[800]!;
                    if (status == 1) bgColor = Colors.green[800]!;
                    if (status == -1)
                      bgColor = Colors
                          .redAccent; // Tutaj mrugałoby na czerwono (na razie dajemy statyczny czerwony)

                    return GestureDetector(
                      onLongPress: () => _showEvaluationDialog(context, cause),
                      child: ActionChip(
                        label: Text(
                          cause,
                          style: const TextStyle(color: Colors.white),
                        ),
                        backgroundColor: bgColor,
                        onPressed: () => widget.engine.considerCause(
                          cause,
                        ), // Krótkie kliknięcie = Zespół rozważa
                      ),
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

  void _showEvaluationDialog(BuildContext context, String cause) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Colors.grey[900],
        title: Text(
          "Ocena: $cause",
          style: const TextStyle(color: Colors.orangeAccent),
        ),
        content: const Text(
          "Czy uważasz, że podjąłeś działania adekwatne do parametrów pacjenta i możemy odhaczyć ten problem?",
          style: TextStyle(color: Colors.white),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text("NIE, jeszcze nie"),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
            onPressed: () {
              Navigator.pop(ctx);
              widget.engine.evaluate4H4TCause(cause);
            },
            child: const Text("TAK, Wykluczone/Zabezpieczone"),
          ),
        ],
      ),
    );
  }
}
