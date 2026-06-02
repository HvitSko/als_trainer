import 'package:flutter/material.dart';
import '../models/scenario_database.dart';
import '../models/scenario_model.dart';
import 'main_game_screen.dart';
import '../models/als_state.dart';
import '../../../app_localization.dart';
import 'dart:ui';

class ScenarioIntroScreen extends StatefulWidget {
  // Dodajemy opcjonalny parametr z konkretnym scenariuszem!
  final Scenario? preselectedScenario;

  const ScenarioIntroScreen({super.key, this.preselectedScenario});

  @override
  State<ScenarioIntroScreen> createState() => _ScenarioIntroScreenState();
}

class _ScenarioIntroScreenState extends State<ScenarioIntroScreen> {
  late Scenario _currentScenario;
  GameMode _selectedMode = GameMode.practice;

  @override
  void initState() {
    super.initState();
    _currentScenario =
        widget.preselectedScenario ?? ScenarioDatabase.getRandomScenario();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black, // Tło dla blura
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: 16.0,
              vertical: 20.0,
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(25),
              child: BackdropFilter(
                filter: ImageFilter.blur(
                  sigmaX: 15,
                  sigmaY: 15,
                ), // Efekt szronionego szkła
                child: Container(
                  constraints: BoxConstraints(
                    maxWidth: 800, // Zabezpieczenie na iPady i Web
                    maxHeight:
                        MediaQuery.of(context).size.height *
                        0.9, // Zabezpieczenie przed overflow
                  ),
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: Colors.blueAccent.withValues(
                      alpha: 0.05,
                    ), // Delikatna poświata wewnątrz szkła
                    borderRadius: BorderRadius.circular(25),
                    border: Border.all(
                      color: Colors.blueAccent.withValues(
                        alpha: 0.3,
                      ), // Neonowa, półprzezroczysta ramka
                      width: 2,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.5),
                        blurRadius: 15,
                        spreadRadius: 2,
                      ),
                    ],
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // --- NAGŁÓWEK (Przypięty na górze) ---
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(
                            Icons.emergency,
                            color: Colors.redAccent,
                            size: 40,
                          ),
                          const SizedBox(width: 15),
                          Expanded(
                            child: Text(
                              AppLoc.tr(
                                "KARTA ZLECENIA WYJAZDU",
                                "EMS DISPATCH RECORD",
                              ),
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                color: Colors.red[400],
                                fontSize: 22,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 1.5,
                                shadows: [
                                  Shadow(
                                    color: Colors.redAccent.withValues(
                                      alpha: 0.5,
                                    ),
                                    blurRadius: 10,
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 15),
                      const Divider(color: Colors.blueAccent, thickness: 1.5),
                      const SizedBox(height: 15),

                      // --- TREŚĆ SCROLLOWANA (Wywiad i opcje) ---
                      Expanded(
                        child: SingleChildScrollView(
                          physics: const BouncingScrollPhysics(),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              // WYWOŁANIE TWOICH BLOKÓW INFORMACYJNYCH
                              _buildInfoBlock(
                                AppLoc.tr(
                                  "PRIORYTET WEZWANIA:",
                                  "DISPATCH PRIORITY:",
                                ),
                                AppLoc.tr(
                                  "KOD 1 (Zagrożenie Życia / Kardiologiczne)",
                                  "CODE 1 (Life Threat / Cardiac Arrest)",
                                ),
                                Colors.redAccent,
                              ),
                              const SizedBox(height: 15),
                              _buildInfoBlock(
                                AppLoc.tr(
                                  "DYSPOZYTORNIA MEDYCZNA:",
                                  "MEDICAL DISPATCH CENTER:",
                                ),
                                _currentScenario.dispatchInfo,
                                Colors.white,
                              ),
                              const SizedBox(height: 15),
                              _buildInfoBlock(
                                AppLoc.tr(
                                  "ROZPOZNANIE MIEJSCA (SCENE SIZE-UP):",
                                  "SCENE SIZE-UP:",
                                ),
                                _currentScenario.sceneSizeUp,
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
                                  color: Colors.white70,
                                  fontWeight: FontWeight.bold,
                                  letterSpacing: 1.2,
                                ),
                              ),
                              const SizedBox(height: 15),

                              // MODERNIZACJA SEGMENTED BUTTON (Glassmorphism style)
                              SegmentedButton<GameMode>(
                                style: SegmentedButton.styleFrom(
                                  backgroundColor: Colors.black.withValues(
                                    alpha: 0.3,
                                  ),
                                  selectedForegroundColor: Colors.white,
                                  selectedBackgroundColor: Colors.blueAccent
                                      .withValues(alpha: 0.5),
                                  side: BorderSide(
                                    color: Colors.blueAccent.withValues(
                                      alpha: 0.5,
                                    ),
                                  ),
                                ),
                                segments: [
                                  ButtonSegment(
                                    value: GameMode.practice,
                                    label: Padding(
                                      padding: const EdgeInsets.symmetric(
                                        vertical: 8.0,
                                      ),
                                      child: Text(
                                        AppLoc.tr(
                                          "Przećwicz\n(Instruktor EBM)",
                                          "Practice\n(EBM Instructor)",
                                        ),
                                        textAlign: TextAlign.center,
                                        style: const TextStyle(fontSize: 13),
                                      ),
                                    ),
                                  ),
                                  ButtonSegment(
                                    value: GameMode.test,
                                    label: Padding(
                                      padding: const EdgeInsets.symmetric(
                                        vertical: 8.0,
                                      ),
                                      child: Text(
                                        AppLoc.tr(
                                          "Sprawdź się\n(Egzamin)",
                                          "Test Yourself\n(Exam)",
                                        ),
                                        textAlign: TextAlign.center,
                                        style: const TextStyle(fontSize: 13),
                                      ),
                                    ),
                                  ),
                                ],
                                selected: {_selectedMode},
                                onSelectionChanged:
                                    (Set<GameMode> newSelection) {
                                      setState(
                                        () =>
                                            _selectedMode = newSelection.first,
                                      );
                                    },
                              ),
                              const SizedBox(height: 20),
                            ],
                          ),
                        ),
                      ),

                      // --- PRZYCISK START (Przypięty na dole ramy) ---
                      const SizedBox(height: 15),
                      ElevatedButton(
                        style:
                            ElevatedButton.styleFrom(
                              backgroundColor: Colors
                                  .transparent, // Neonowy styl transparentny
                              shadowColor: Colors.transparent,
                              padding: const EdgeInsets.symmetric(vertical: 20),
                              side: BorderSide(
                                color: Colors.greenAccent.withValues(
                                  alpha: 0.8,
                                ),
                                width: 2,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(15),
                              ),
                            ).copyWith(
                              overlayColor: WidgetStateProperty.all(
                                Colors.greenAccent.withValues(alpha: 0.2),
                              ),
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
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(
                              Icons.play_arrow,
                              color: Colors.greenAccent,
                              size: 28,
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                AppLoc.tr(
                                  "ROZPOCZNIJ CZYNNOŚCI RATUNKOWE",
                                  "COMMENCE RESCUE OPERATIONS",
                                ),
                                textAlign: TextAlign.center,
                                style: const TextStyle(
                                  fontSize: 16,
                                  color: Colors
                                      .greenAccent, // Jarząca zieleń zamiast nudnego tła
                                  fontWeight: FontWeight.bold,
                                  letterSpacing: 1.2,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
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
