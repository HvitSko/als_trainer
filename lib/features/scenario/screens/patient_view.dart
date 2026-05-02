import 'package:flutter/material.dart';
import '../logic/game_engine.dart';

class PatientView extends StatelessWidget {
  final GameEngine engine;

  const PatientView({super.key, required this.engine});

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: engine,
      builder: (context, _) {
        // ZACZYNAMY KORZYSTAĆ Z PATIENT MODELU!
        final state = engine.state;
        final patient = state.patient;

        return Container(
          color: Colors.blueGrey[900],
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.personal_injury,
                size: 100,
                color: Colors.white54,
              ),
              const SizedBox(height: 20),
              const Text(
                "PACJENT",
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 2,
                ),
              ),
              const Text(
                "Wiek: ~55 lat | Płeć: Mężczyzna",
                style: TextStyle(color: Colors.grey, fontSize: 16),
              ),
              const SizedBox(height: 40),

              Card(
                color: Colors.black54,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        "Badanie Fizykalne (ABCDE)",
                        style: TextStyle(
                          color: Colors.orangeAccent,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const Divider(color: Colors.grey),
                      _buildAssessmentRow("Skóra:", patient.skinCondition),
                      _buildAssessmentRow(
                        "Klatka piersiowa:",
                        patient.chestMovement,
                      ),
                      // ZMIANA: Źrenice są ukryte do momentu wykonania badania!
                      _buildAssessmentRow(
                        "Źrenice (D):",
                        state.isPhysicalExamDone
                            ? patient.pupils
                            : "Niezbadane (wymaga oceny)",
                      ),
                      _buildAssessmentRow(
                        "Szacowana waga:",
                        "${patient.weight.toStringAsFixed(0)} kg",
                      ),
                      const SizedBox(height: 10),
                      if (state.isTempMeasured)
                        _buildAssessmentRow(
                          "Temperatura:",
                          "${patient.temperature.toStringAsFixed(1)} °C",
                          color: Colors.cyan,
                        ),
                      if (state.isGlucoseMeasured)
                        _buildAssessmentRow(
                          "Glikemia:",
                          "${patient.bloodGlucose} mg/dL",
                          color: Colors.redAccent,
                        ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildAssessmentRow(
    String title,
    String value, {
    Color color = Colors.white,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(title, style: const TextStyle(color: Colors.grey, fontSize: 14)),
          Expanded(
            child: Text(
              value,
              textAlign: TextAlign.right,
              style: TextStyle(
                color: color,
                fontSize: 14,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
