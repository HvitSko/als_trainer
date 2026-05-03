import 'package:flutter/material.dart';
import '../models/scenario_database.dart';
import '../models/scenario_model.dart';
import 'main_game_screen.dart';
import '../models/als_state.dart';

class ScenarioIntroScreen extends StatefulWidget {
  const ScenarioIntroScreen({super.key});

  @override
  State<ScenarioIntroScreen> createState() => _ScenarioIntroScreenState();
}

class _ScenarioIntroScreenState extends State<ScenarioIntroScreen> {
  late Scenario _currentScenario;
  GameMode _selectedMode = GameMode.practice; // NOWA ZMIENNA

  @override
  void initState() {
    super.initState();
    _currentScenario = ScenarioDatabase.getRandomScenario();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black, // Lub taki jaki masz
      // ... (jeśli masz tu AppBar, to lepiej go wywal w trybie poziomym)
      body: SafeArea(
        child: Center(
          // MAGIA SKIPPY'EGO: Tę linijkę musisz dodać!
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24.0), // Marginesy dla estetyki
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

                // --- NOWY BLOK WYBORU TRYBU ---
                const Text(
                  "WYBIERZ TRYB SYMULACJI:",
                  textAlign: TextAlign.center,
                  style: TextStyle(
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
                  segments: const [
                    ButtonSegment(
                      value: GameMode.practice,
                      label: Text("Przećwicz (Instruktor EBM)"),
                    ),
                    ButtonSegment(
                      value: GameMode.test,
                      label: Text("Sprawdź się (Test/Egzamin)"),
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
                        // PRZEKAZUJEMY TRYB GRY!
                        builder: (context) => MainGameScreen(
                          scenario: _currentScenario,
                          mode: _selectedMode,
                        ),
                      ),
                    );
                  },
                  child: const Text(
                    "ROZPOCZNIJ MEDYCZNE CZYNNOŚCI RATUNKOWE",
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
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
