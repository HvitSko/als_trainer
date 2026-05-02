import 'package:flutter/material.dart';
import '../models/scenario_database.dart';
import '../models/scenario_model.dart';
import 'main_game_screen.dart';

class ScenarioIntroScreen extends StatefulWidget {
  const ScenarioIntroScreen({super.key});

  @override
  State<ScenarioIntroScreen> createState() => _ScenarioIntroScreenState();
}

class _ScenarioIntroScreenState extends State<ScenarioIntroScreen> {
  late Scenario _currentScenario;

  @override
  void initState() {
    super.initState();
    // Losujemy scenariusz przy wejściu do gry
    _currentScenario = ScenarioDatabase.getRandomScenario();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Center(
          child: Container(
            constraints: const BoxConstraints(maxWidth: 600),
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Icon(Icons.emergency, color: Colors.redAccent, size: 80),
                const SizedBox(height: 20),
                Text(
                  "KARTA ZLECENIA WYJAZDU ZRM",
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Colors.red[400],
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 2,
                  ),
                ),
                const Divider(color: Colors.grey, height: 40),

                _buildInfoBlock(
                  "PRIORYTET WEZWANIA:",
                  "KOD 1 (Zagrożenie Życia / Kardiologiczne)",
                  Colors.redAccent,
                ),
                _buildInfoBlock(
                  "DYSPOZYTORNIA MEDYCZNA:",
                  _currentScenario.dispatchInfo,
                  Colors.white,
                ),
                _buildInfoBlock(
                  "ROZPOZNANIE MIEJSCA (SCENE SIZE-UP):",
                  _currentScenario.sceneSizeUp,
                  Colors.cyanAccent,
                ),

                const Spacer(),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green[700],
                    padding: const EdgeInsets.symmetric(vertical: 20),
                    textStyle: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  onPressed: () {
                    // Startujemy grę i przekazujemy scenariusz
                    Navigator.of(context).pushReplacement(
                      MaterialPageRoute(
                        builder: (context) =>
                            MainGameScreen(scenario: _currentScenario),
                      ),
                    );
                  },
                  child: const Text("ROZPOCZNIJ MEDYCZNE CZYNNOŚCI RATUNKOWE"),
                ),
                const SizedBox(height: 20),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildInfoBlock(String title, String content, Color contentColor) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 20.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              color: Colors.grey,
              fontSize: 14,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(content, style: TextStyle(color: contentColor, fontSize: 18)),
        ],
      ),
    );
  }
}
