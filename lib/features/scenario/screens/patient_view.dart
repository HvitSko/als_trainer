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
        final state = engine.state; // Docelowo pociągniemy dane z PatientModel

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
                        "Badanie Wizualne (ABCDE)",
                        style: TextStyle(
                          color: Colors.orangeAccent,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const Divider(color: Colors.grey),
                      _buildAssessmentRow(
                        "Drogi Oddechowe:",
                        state.airwayStatus.name.toUpperCase(),
                      ),
                      _buildAssessmentRow(
                        "Klatka piersiowa:",
                        "Brak własnych ruchów oddechowych",
                      ),
                      _buildAssessmentRow(
                        "Skóra:",
                        "Blada, chłodna, sinica obwodowa",
                      ),
                      _buildAssessmentRow(
                        "Waga szacunkowa:",
                        "${state.patientWeight.toStringAsFixed(0)} kg",
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

  Widget _buildAssessmentRow(String title, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(title, style: const TextStyle(color: Colors.grey, fontSize: 16)),
          Text(
            value,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}
