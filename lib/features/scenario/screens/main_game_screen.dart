import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:async'; // POPRAWNY IMPORT NA SAMEJ GÓRZE!

import '../logic/game_engine.dart';
import '../models/scenario_model.dart';
import '../models/als_state.dart';
import 'patient_view.dart';
import 'monitor_view.dart';
import 'feedback_screen.dart';
import '../widgets/inventory/ampularium.dart';
import '../widgets/inventory/h4t_dialog.dart';
import 'scenario_intro_screen.dart';

class MainGameScreen extends StatefulWidget {
  final Scenario scenario;
  final GameMode mode;

  const MainGameScreen({super.key, required this.scenario, required this.mode});

  @override
  State<MainGameScreen> createState() => _MainGameScreenState();
}

class _MainGameScreenState extends State<MainGameScreen> {
  late GameEngine engine;
  final PageController _pageController = PageController(initialPage: 1);
  int _currentPage = 1;

  int _lastLogCount = 0;
  String _hudLog = "";
  Timer? _hudLogTimer;

  @override
  void initState() {
    super.initState();
    engine = GameEngine(widget.scenario, widget.mode);
    _lastLogCount = engine.state.log.length;

    // JEDEN GŁÓWNY LISTENER dla logów i końca gry
    engine.addListener(_onEngineUpdate);
  }

  void _onEngineUpdate() {
    if (!mounted) return;

    // 1. Sprawdzanie końca gry
    if (engine.state.currentPhase == ResuscitationPhase.postResuscitation) {
      engine.removeListener(_onEngineUpdate); // Zapobiega zapętleniu
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (context) =>
              FeedbackScreen(state: engine.state, scenario: widget.scenario),
        ),
      );
      return;
    }

    // 2. Obsługa HUD logów
    if (engine.state.log.length > _lastLogCount) {
      String newLog = engine.state.log.first;
      String cleanLog = newLog.contains("]")
          ? newLog.substring(newLog.indexOf(']') + 2)
          : newLog;

      setState(() {
        _hudLog = cleanLog;
        _lastLogCount = engine.state.log.length;
      });

      _hudLogTimer?.cancel();
      _hudLogTimer = Timer(const Duration(seconds: 4), () {
        if (mounted) setState(() => _hudLog = "");
      });
    } else {
      // Odświeżenie UI dla timerów i innych zdarzeń
      setState(() {});
    }
  }

  @override
  void dispose() {
    engine.removeListener(_onEngineUpdate);
    _hudLogTimer?.cancel();
    engine.dispose();
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Stack(
          children: [
            // WARSTWA 1: Ekrany główne
            PageView(
              controller: _pageController,
              physics: const NeverScrollableScrollPhysics(),
              onPageChanged: (index) {
                setState(() => _currentPage = index);
              },
              children: [
                MonitorView(engine: engine),
                PatientView(engine: engine),
              ],
            ),

            // --- WARSTWA: GLOBALNY TIMER RKO ---
            if (engine.state.isCprActive)
              Positioned(
                top: 50,
                left: 0,
                right: 0,
                child: IgnorePointer(
                  child: Center(
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 10,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.red[900]?.withOpacity(0.85),
                        borderRadius: BorderRadius.circular(30),
                        border: Border.all(color: Colors.redAccent, width: 2),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(
                            Icons.favorite,
                            color: Colors.white,
                            size: 20,
                          ),
                          const SizedBox(width: 10),
                          Text(
                            "RKO: ${engine.state.cprSecondsRemaining} s",
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),

            // --- WARSTWA: TACKA Z LEKAMI ---
            if (engine.state.preparedDrugs.isNotEmpty)
              Positioned(
                bottom: 85,
                left: 0,
                right: 0,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text(
                      "TACKA - GOTOWE LEKI (Kliknij, aby podać):",
                      style: TextStyle(
                        color: Colors.yellowAccent,
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 5),
                    Wrap(
                      spacing: 10,
                      alignment: WrapAlignment.center,
                      children: List.generate(
                        engine.state.preparedDrugs.length,
                        (index) {
                          String fullDrugInfo =
                              engine.state.preparedDrugs[index];
                          String drugName = fullDrugInfo.split('|')[0];
                          String dose = fullDrugInfo.split('|').length > 1
                              ? fullDrugInfo.split('|')[1]
                              : "";

                          return ElevatedButton.icon(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.red[800],
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 8,
                              ),
                              side: const BorderSide(
                                color: Colors.redAccent,
                                width: 1,
                              ),
                            ),
                            icon: const Icon(Icons.vaccines, size: 18),
                            label: Text(
                              "$drugName ($dose)",
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            onPressed: () => engine.administerDrug(index),
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ),

            // WARSTWA 4: Inteligentna Nawigacja i Narzędzia
            Positioned(
              bottom: 20,
              left: 10,
              right: 10,
              child: _currentPage == 1
                  ? Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        _buildOverlayButton(
                          icon: Icons.medical_services,
                          color: Colors.blue[900]!,
                          label: "Ampularium",
                          onPressed:
                              (engine.state.isPreparingDrug ||
                                  engine.state.preparedDrugs.length >= 2)
                              ? null
                              : () => showDialog(
                                  context: context,
                                  builder: (context) => AmpulariumDialog(
                                    onDrugPrepared: (drug, dose) =>
                                        engine.prepareDrug(drug, dose),
                                  ),
                                ),
                        ),
                        _buildOverlayButton(
                          icon: Icons.air,
                          color: Colors.cyan[800]!,
                          label: "Oddech",
                          onPressed: () => engine.toggleAirwayMenu(),
                        ),
                        _buildOverlayButton(
                          icon: Icons.backpack,
                          color: Colors.orange[900]!,
                          label: "Torba/Diag.",
                          onPressed: () => engine.toggleBag(),
                        ),
                        _buildOverlayButton(
                          icon: Icons.psychology,
                          color: Colors.purple[800]!,
                          label: "4H4T",
                          onPressed: () => showDialog(
                            context: context,
                            builder: (context) => H4TDialog(engine: engine),
                          ),
                        ),
                        const SizedBox(width: 10),
                        _buildOverlayButton(
                          icon: Icons.monitor_heart,
                          color: Colors.green[700]!,
                          label: "MONITOR",
                          onPressed: () => _pageController.animateToPage(
                            0,
                            duration: const Duration(milliseconds: 300),
                            curve: Curves.easeInOut,
                          ),
                        ),
                      ],
                    )
                  : Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        Padding(
                          padding: const EdgeInsets.only(right: 130.0),
                          child: _buildOverlayButton(
                            icon: Icons.person,
                            color: Colors.green[700]!,
                            label: "WIDOK\nPACJENTA",
                            onPressed: () => _pageController.animateToPage(
                              1,
                              duration: const Duration(milliseconds: 300),
                              curve: Curves.easeInOut,
                            ),
                          ),
                        ),
                      ],
                    ),
            ),

            // --- WARSTWA: GLOBALNY HUD (POWIADOMIENIA EBM) ---
            Builder(
              builder: (context) {
                bool isRoutineExamLog =
                    _hudLog.startsWith("BADANIE:") ||
                    _hudLog.startsWith("USG:") ||
                    _hudLog.startsWith("AKCJA: Założono") ||
                    _hudLog.startsWith("DIAGNOZA");
                bool showHud =
                    _hudLog.isNotEmpty &&
                    !(_currentPage == 1 && isRoutineExamLog);
                if (!showHud) return const SizedBox.shrink();

                return Positioned(
                  top: 20,
                  left: MediaQuery.of(context).size.width * 0.20,
                  right: MediaQuery.of(context).size.width * 0.20,
                  child: SafeArea(
                    child: AnimatedOpacity(
                      opacity: _hudLog.isNotEmpty ? 1.0 : 0.0,
                      duration: const Duration(milliseconds: 300),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 12,
                        ),
                        decoration: BoxDecoration(
                          color: _hudLog.contains("BŁĄD")
                              ? Colors.red[900]?.withOpacity(0.95)
                              : (_hudLog.contains("SUKCES")
                                    ? Colors.green[900]?.withOpacity(0.95)
                                    : Colors.black87),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: _hudLog.contains("BŁĄD")
                                ? Colors.redAccent
                                : Colors.grey,
                            width: 2,
                          ),
                          boxShadow: const [
                            BoxShadow(color: Colors.black54, blurRadius: 10),
                          ],
                        ),
                        child: Text(
                          _hudLog,
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),

            // NAKŁADKA WYJŚCIA Z GRY
            Positioned(
              top: 10,
              right: 10,
              child: SafeArea(
                child: Material(
                  color: Colors.transparent,
                  child: IconButton(
                    icon: const Icon(
                      Icons.exit_to_app,
                      color: Colors.redAccent,
                      size: 36,
                    ),
                    onPressed: () {
                      showDialog(
                        context: context,
                        builder: (BuildContext context) {
                          return AlertDialog(
                            backgroundColor: Colors.grey[900],
                            title: const Row(
                              children: [
                                Icon(
                                  Icons.warning_amber_rounded,
                                  color: Colors.redAccent,
                                ),
                                SizedBox(width: 10),
                                Text(
                                  "Przerwać akcję?",
                                  style: TextStyle(color: Colors.redAccent),
                                ),
                              ],
                            ),
                            content: const Text(
                              "Czy na pewno chcesz porzucić pacjenta i wrócić do dyspozytorni? Akcja zostanie przerwana.",
                              style: TextStyle(color: Colors.white70),
                            ),
                            actions: [
                              TextButton(
                                onPressed: () => Navigator.of(context).pop(),
                                child: const Text(
                                  "Zostań",
                                  style: TextStyle(color: Colors.grey),
                                ),
                              ),
                              ElevatedButton(
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.red[800],
                                ),
                                onPressed: () {
                                  Navigator.of(context).pushAndRemoveUntil(
                                    MaterialPageRoute(
                                      builder: (context) =>
                                          const ScenarioIntroScreen(),
                                    ),
                                    (route) => false,
                                  );
                                },
                                child: const Text(
                                  "Zakończ Akcję",
                                  style: TextStyle(color: Colors.white),
                                ),
                              ),
                            ],
                          );
                        },
                      );
                    },
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildOverlayButton({
    required IconData icon,
    required Color color,
    required String label,
    required VoidCallback? onPressed,
  }) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        FloatingActionButton(
          heroTag: label,
          backgroundColor: onPressed == null ? Colors.grey[800] : color,
          onPressed: onPressed,
          child: Icon(
            icon,
            color: onPressed == null ? Colors.grey[500] : Colors.white,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: const TextStyle(
            color: Colors.white70,
            fontSize: 12,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }
}
