import 'package:flutter/material.dart';
import '../models/scenario_database.dart';
import '../models/scenario_model.dart';
import 'main_game_screen.dart';
import '../models/als_state.dart';
import '../../../app_localization.dart'; // IMPORT TŁUMACZA

class ScenarioIntroScreen extends StatefulWidget {
  const ScenarioIntroScreen({super.key});

  @override
  State<ScenarioIntroScreen> createState() => _ScenarioIntroScreenState();
}

class _ScenarioIntroScreenState extends State<ScenarioIntroScreen> {
  late Scenario _currentScenario;
  GameMode _selectedMode = GameMode.practice;

  @override
  void initState() {
    super.initState();
    _currentScenario = ScenarioDatabase.getRandomScenario();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Icon(Icons.emergency, color: Colors.redAccent, size: 80),
                const SizedBox(height: 20),
                Text(
                  AppLoc.tr(
                    "KARTA ZLECENIA WYJAZDU ZRM",
                    "EMS DISPATCH RECORD",
                  ),
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
                  AppLoc.tr("PRIORYTET WEZWANIA:", "DISPATCH PRIORITY:"),
                  AppLoc.tr(
                    "KOD 1 (Zagrożenie Życia / Kardiologiczne)",
                    "CODE 1 (Life Threat / Cardiac Arrest)",
                  ),
                  Colors.redAccent,
                ),
                _buildInfoBlock(
                  AppLoc.tr(
                    "DYSPOZYTORNIA MEDYCZNA:",
                    "MEDICAL DISPATCH CENTER:",
                  ),
                  _currentScenario
                      .dispatchInfo, // Przetłumaczymy to w bazie danych
                  Colors.white,
                ),
                _buildInfoBlock(
                  AppLoc.tr(
                    "ROZPOZNANIE MIEJSCA (SCENE SIZE-UP):",
                    "SCENE SIZE-UP:",
                  ),
                  _currentScenario
                      .sceneSizeUp, // Przetłumaczymy to w bazie danych
                  Colors.cyanAccent,
                ),

                const SizedBox(height: 40),
                Text(
                  AppLoc.tr(
                    "WYBIERZ TRYB SYMULACJI:",
                    "SELECT SIMULATION MODE:",
                  ),
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: Colors.grey,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 10),
                SegmentedButton<GameMode>(
                  style: SegmentedButton.styleFrom(
                    backgroundColor: Colors.grey[900],
                    selectedForegroundColor: Colors.white,
                    selectedBackgroundColor: Colors.blue[800],
                  ),
                  segments: [
                    ButtonSegment(
                      value: GameMode.practice,
                      label: Text(
                        AppLoc.tr(
                          "Przećwicz (Instruktor EBM)",
                          "Practice (EBM Instructor)",
                        ),
                      ),
                    ),
                    ButtonSegment(
                      value: GameMode.test,
                      label: Text(
                        AppLoc.tr(
                          "Sprawdź się (Egzamin)",
                          "Test Yourself (Exam)",
                        ),
                      ),
                    ),
                  ],
                  selected: {_selectedMode},
                  onSelectionChanged: (Set<GameMode> newSelection) {
                    setState(() => _selectedMode = newSelection.first);
                  },
                ),
                const SizedBox(height: 20),

                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green[700],
                    padding: const EdgeInsets.symmetric(vertical: 20),
                  ),
                  onPressed: () {
                    Navigator.of(context).pushReplacement(
                      MaterialPageRoute(
                        builder: (context) => MainGameScreen(
                          scenario: _currentScenario,
                          mode: _selectedMode,
                        ),
                      ),
                    );
                  },
                  child: Text(
                    AppLoc.tr(
                      "ROZPOCZNIJ MEDYCZNE CZYNNOŚCI RATUNKOWE",
                      "COMMENCE MEDICAL RESCUE OPERATIONS",
                    ),
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
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
