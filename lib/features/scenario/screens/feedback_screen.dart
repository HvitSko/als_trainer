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
              // MĄDROŚCI INSTRUKTORA (Błędy Krytyczne)
              if (state.instructorFeedback.isNotEmpty) ...[
                const Text(
                  "BŁĘDY KRYTYCZNE (ZAGROŻENIE ŻYCIA):",
                  style: TextStyle(
                    color: Colors.redAccent,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 10),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.red[900]?.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.red),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: state.instructorFeedback
                        .map(
                          (fb) => Padding(
                            padding: const EdgeInsets.only(bottom: 6.0),
                            child: Text(
                              "• $fb",
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 14,
                              ),
                            ),
                          ),
                        )
                        .toList(),
                  ),
                ),
                const SizedBox(height: 20),
              ],

              // OBSZARY DO POPRAWY (Mniejsze błędy EBM i przeoczenia)
              Builder(
                builder: (context) {
                  List<String> minorErrors = state.auditLog
                      .where(
                        (log) =>
                            (log.contains("BŁĄD EBM") ||
                                log.contains("OSTRZEŻENIE")) &&
                            !log.contains("KRYTYCZNY"),
                      )
                      .toList();
                  if (minorErrors.isEmpty) return const SizedBox.shrink();
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        "OBSZARY DO POPRAWY (Wytyczne EBM):",
                        style: TextStyle(
                          color: Colors.orangeAccent,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 10),
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.orange[900]?.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: minorErrors
                              .map(
                                (err) => Padding(
                                  padding: const EdgeInsets.only(bottom: 6.0),
                                  // Wycinamy znacznik czasu dla lepszej czytelności w podsumowaniu
                                  child: Text(
                                    "• ${err.substring(err.indexOf(']') + 2)}",
                                    style: const TextStyle(
                                      color: Colors.white70,
                                      fontSize: 13,
                                    ),
                                  ),
                                ),
                              )
                              .toList(),
                        ),
                      ),
                      const SizedBox(height: 20),
                    ],
                  );
                },
              ),

              // CO POSZŁO DOBRZE (Sukcesy EBM)
              Builder(
                builder: (context) {
                  List<String> successes = state.auditLog
                      .where((log) => log.contains("SUKCES EBM"))
                      .toList();
                  if (successes.isEmpty) return const SizedBox.shrink();
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        "CO ZROBIONO DOBRZE:",
                        style: TextStyle(
                          color: Colors.greenAccent,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 10),
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.green[900]?.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: successes
                              .map(
                                (suc) => Padding(
                                  padding: const EdgeInsets.only(bottom: 6.0),
                                  child: Text(
                                    "• ${suc.substring(suc.indexOf(']') + 2)}",
                                    style: const TextStyle(
                                      color: Colors.white70,
                                      fontSize: 13,
                                    ),
                                  ),
                                ),
                              )
                              .toList(),
                        ),
                      ),
                      const SizedBox(height: 20),
                    ],
                  );
                },
              ),

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
