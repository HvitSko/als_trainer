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
    double cprFraction = 0;
    if (state.totalElapsedGameTime > 0) {
      cprFraction = (state.totalCprSeconds / state.totalElapsedGameTime) * 100;
    }

    String airwayFeedback = "";
    Color airwayColor = Colors.grey;
    if (state.airwayStatus == AirwayType.endotracheal &&
        state.intubationStatus == IntubationStatus.correct) {
      airwayFeedback = "Rurka ETI (Złoty Standard! Asynchroniczna wentylacja).";
      airwayColor = Colors.greenAccent;
    } else if (state.airwayStatus == AirwayType.igel) {
      airwayFeedback =
          "SGA / I-gel (Szybkie i skuteczne, asynchronia możliwa).";
      airwayColor = Colors.blueAccent;
    } else if (state.airwayStatus == AirwayType.bvm) {
      airwayFeedback = "Tylko Worek BVM (Wymagało przerw w RKO 30:2!).";
      airwayColor = Colors.orangeAccent;
    } else {
      airwayFeedback = "BRAK ZABEZPIECZENIA DRÓG!";
      airwayColor = Colors.redAccent;
    }

    bool isRosc = state.patient.hasPulse;

    // FILTROWANIE LOGÓW AUDYTU (Dziennik interwencji)
    final successes = state.auditLog
        .where((l) => l.contains("SUKCES"))
        .toList();
    final errors = state.auditLog
        .where(
          (l) =>
              l.contains("BŁĄD") ||
              l.contains("OSTRZEŻENIE") ||
              l.contains("STRATA CZASU"),
        )
        .toList();
    final neutral = state.auditLog
        .where(
          (l) =>
              !l.contains("SUKCES") &&
              !l.contains("BŁĄD") &&
              !l.contains("OSTRZEŻENIE") &&
              !l.contains("STRATA CZASU"),
        )
        .toList();

    // MAGIA SKIPPY'EGO: FILTROWANIE WSKAZÓWEK INSTRUKTORA
    final positiveFeedback = state.instructorFeedback
        .where((f) => f.contains("SUKCES"))
        .toList();
    final negativeFeedback = state.instructorFeedback
        .where((f) => !f.contains("SUKCES"))
        .toList();

    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: SingleChildScrollView(
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

              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _buildStatCard(
                    "Ułamek RKO",
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
              const SizedBox(height: 10),

              Card(
                color: Colors.grey[850],
                child: Padding(
                  padding: const EdgeInsets.all(12.0),
                  child: Row(
                    children: [
                      const Icon(Icons.air, color: Colors.grey),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          "Drogi oddechowe:\n$airwayFeedback",
                          style: TextStyle(
                            color: airwayColor,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 20),

              const Text(
                "Prawdziwa Przyczyna Zatrzymania:",
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

              // SEKCJA 1: SUKCESY EBM (ZIELONA RAMKA)
              if (successes.isNotEmpty || positiveFeedback.isNotEmpty) ...[
                const Text(
                  "SUKCESY I DOBRE PRAKTYKI (EBM)",
                  style: TextStyle(
                    color: Colors.greenAccent,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 5),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.green[900]!.withOpacity(0.2),
                    border: Border.all(color: Colors.green),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      ...positiveFeedback.map(
                        (fb) => Padding(
                          padding: const EdgeInsets.only(bottom: 6),
                          child: Text(
                            "🏆 $fb",
                            style: const TextStyle(
                              color: Colors.greenAccent,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                      ...successes.map(
                        (s) => Padding(
                          padding: const EdgeInsets.only(bottom: 6),
                          child: Text(
                            "✅ ${s.substring(s.indexOf(']') + 2)}",
                            style: const TextStyle(color: Colors.white),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
              ],

              // SEKCJA 2: BŁĘDY I OSTRZEŻENIA (CZERWONA RAMKA)
              if (errors.isNotEmpty || negativeFeedback.isNotEmpty) ...[
                const Text(
                  "BŁĘDY KRYTYCZNE I OSTRZEŻENIA",
                  style: TextStyle(
                    color: Colors.redAccent,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 5),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.red[900]!.withOpacity(0.2),
                    border: Border.all(color: Colors.red),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      ...negativeFeedback.map(
                        (fb) => Padding(
                          padding: const EdgeInsets.only(bottom: 6),
                          child: Text(
                            "💀 $fb",
                            style: const TextStyle(
                              color: Colors.redAccent,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                      ...errors.map(
                        (e) => Padding(
                          padding: const EdgeInsets.only(bottom: 6),
                          child: Text(
                            "❌ ${e.substring(e.indexOf(']') + 2)}",
                            style: const TextStyle(color: Colors.white70),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
              ],

              // SEKCJA 3: DZIENNIK ZDARZEŃ (SZARA RAMKA)
              const Text(
                "PEŁEN DZIENNIK INTERWENCJI",
                style: TextStyle(
                  color: Colors.grey,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 5),
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.grey[900],
                  borderRadius: BorderRadius.circular(8),
                ),
                child: ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: neutral.length,
                  itemBuilder: (context, index) => Padding(
                    padding: const EdgeInsets.symmetric(vertical: 2.0),
                    child: Text(
                      "• ${neutral[index]}",
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 12,
                      ),
                    ),
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
                  "POWRÓT DO DYSPOZYTORNI",
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
