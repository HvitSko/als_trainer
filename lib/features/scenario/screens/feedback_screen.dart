import 'package:flutter/material.dart';
import '../models/als_state.dart';
import '../models/scenario_model.dart';
import 'scenario_intro_screen.dart';

class FeedbackScreen extends StatelessWidget {
  final AlsScenarioState state;
  final Scenario scenario;

  const FeedbackScreen({
    super.key,
    required this.state,
    required this.scenario,
  });

  @override
  Widget build(BuildContext context) {
    // Obliczanie CPR Fraction
    double cprFraction = 0;
    if (state.totalElapsedGameTime > 0) {
      cprFraction = (state.totalCprSeconds / state.totalElapsedGameTime) * 100;
    }

    bool isRosc = state.patient.hasPulse;

    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                isRosc
                    ? "SUKCES: POWRÓT KRĄŻENIA (ROSC)"
                    : "KONIEC CZASU (ZGON PACJENTA)",
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: isRosc ? Colors.greenAccent : Colors.redAccent,
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const Divider(color: Colors.grey, height: 40),

              Text(
                "PODSUMOWANIE AKCJI RATUNKOWEJ",
                style: TextStyle(
                  color: Colors.blue[300],
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 10),

              // STATYSTYKI KLUCZOWE
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _buildStatCard(
                    "Ułamek RKO (Fraction)",
                    "${cprFraction.toStringAsFixed(0)}%",
                    cprFraction >= 60 ? Colors.green : Colors.red,
                  ),
                  _buildStatCard(
                    "Krytyczne Błędy",
                    "${state.criticalErrorsCount}",
                    state.criticalErrorsCount == 0 ? Colors.green : Colors.red,
                  ),
                  _buildStatCard(
                    "Czas Akcji",
                    "${state.totalElapsedGameTime ~/ 60}:${(state.totalElapsedGameTime % 60).toString().padLeft(2, '0')}",
                    Colors.white,
                  ),
                ],
              ),
              const SizedBox(height: 20),

              // ANALIZA 4H4T
              const Text(
                "Prawdziwa Przyczyna (Wg. Sekcji Zwłok / Kardiologa):",
                style: TextStyle(color: Colors.grey),
              ),
              Text(
                state.patient.hiddenCause.name.toUpperCase(),
                style: const TextStyle(
                  color: Colors.orangeAccent,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 20),

              // LOG AUDYTORSKI (Pełen)
              const Text(
                "PEŁEN DZIENNIK ZDARZEŃ (RAPORT Z DEFIBRYLATORA):",
                style: TextStyle(
                  color: Colors.purpleAccent,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 10),
              Expanded(
                child: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.grey[900],
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: ListView.builder(
                    itemCount: state.auditLog.length,
                    itemBuilder: (context, index) {
                      String log = state.auditLog[index];
                      Color c = Colors.white70;
                      if (log.contains("KRYTYCZNY BŁĄD"))
                        c = Colors.redAccent;
                      else if (log.contains("BŁĄD EBM") ||
                          log.contains("OSTRZEŻENIE"))
                        c = Colors.orangeAccent;
                      else if (log.contains("SUKCES"))
                        c = Colors.greenAccent;

                      return Padding(
                        padding: const EdgeInsets.symmetric(vertical: 2.0),
                        child: Text(
                          log,
                          style: TextStyle(color: c, fontSize: 12),
                        ),
                      );
                    },
                  ),
                ),
              ),
              const SizedBox(height: 20),

              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue[800],
                  padding: const EdgeInsets.symmetric(vertical: 15),
                ),
                icon: const Icon(Icons.refresh, color: Colors.white),
                label: const Text(
                  "POWRÓT DO DYSPOZYTORNI (NOWE WEZWANIE)",
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                onPressed: () {
                  Navigator.of(context).pushReplacement(
                    MaterialPageRoute(
                      builder: (context) => const ScenarioIntroScreen(),
                    ),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatCard(String title, String value, Color valueColor) {
    return Card(
      color: Colors.grey[850],
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Text(
              title,
              style: const TextStyle(color: Colors.grey, fontSize: 12),
            ),
            const SizedBox(height: 5),
            Text(
              value,
              style: TextStyle(
                color: valueColor,
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
