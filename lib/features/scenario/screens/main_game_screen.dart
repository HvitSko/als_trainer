import 'package:flutter/material.dart';
import '../logic/game_engine.dart';
import '../models/scenario_model.dart';
import '../models/als_state.dart'; // Dodany import dla GameMode
import 'patient_view.dart';
import 'monitor_view.dart';
import 'feedback_screen.dart'; // ZARAZ GO STWORZYMY
import '../widgets/inventory/ampularium.dart';
import '../widgets/inventory/airway_dialog.dart';
import '../widgets/inventory/h4t_dialog.dart';
import 'package:flutter/services.dart'; // Dodaj ten import na górze pliku, żeby SystemNavigator zadziałał!

class MainGameScreen extends StatefulWidget {
  final Scenario scenario;
  final GameMode mode; // NOWE

  const MainGameScreen({super.key, required this.scenario, required this.mode});

  @override
  State<MainGameScreen> createState() => _MainGameScreenState();
}

class _MainGameScreenState extends State<MainGameScreen> {
  late GameEngine engine;
  final PageController _pageController = PageController(initialPage: 0);

  @override
  void initState() {
    super.initState();
    engine = GameEngine(
      widget.scenario,
      widget.mode,
    ); // PRZEKAZUJEMY TRYB DO SILNIKA

    // NASŁUCHUJEMY KOŃCA GRY
    engine.addListener(_checkGameEnd);
  }

  void _checkGameEnd() {
    if (engine.state.currentPhase == ResuscitationPhase.postResuscitation) {
      engine.removeListener(_checkGameEnd); // Żeby nie odpalać ekranu 100 razy
      // Wyrzucamy modalny ekran feedbacku (nie można go zamknąć zwykłym kliknięciem)
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (context) =>
              FeedbackScreen(state: engine.state, scenario: widget.scenario),
        ),
      );
    }
  }

  @override
  void dispose() {
    engine.removeListener(_checkGameEnd);
    engine.dispose();
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.grey[900],
        title: Text(
          widget.mode == GameMode.test
              ? "TRYB: EGZAMIN (TEST)"
              : "TRYB: ĆWICZENIA (PRACTICE)",
          style: const TextStyle(color: Colors.white70, fontSize: 14),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.exit_to_app, color: Colors.redAccent),
            tooltip: "Przerwij i wyjdź",
            onPressed: () {
              // Awaryjne zamknięcie aplikacji we Flutterze
              SystemNavigator.pop();
            },
          ),
        ],
      ),
      body: SafeArea(
        child: AnimatedBuilder(
          animation: engine,
          builder: (context, _) {
            return Stack(
              children: [
                // WARSTWA 1: Ekrany główne
                PageView(
                  controller: _pageController,
                  children: [
                    MonitorView(engine: engine),
                    PatientView(engine: engine),
                  ],
                ),

                // WARSTWA 3: Wskaźnik ekranów
                Positioned(
                  bottom: 110,
                  left: 0,
                  right: 0,
                  child: IgnorePointer(
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.monitor_heart,
                          color: Colors.white.withOpacity(0.5),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          "< PRZESUŃ EKRAN >",
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.5),
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Icon(
                          Icons.person,
                          color: Colors.white.withOpacity(0.5),
                        ),
                      ],
                    ),
                  ),
                ),
                // --- WARSTWA: GLOBALNY TIMER RKO ---
                if (engine.state.isCprActive)
                  Positioned(
                    top: 50, // Pływa na górze ekranu
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
                            border: Border.all(
                              color: Colors.redAccent,
                              width: 2,
                            ),
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
                // --- WARSTWA: TACKA Z LEKAMI (GOTOWE STRZYKAWKI) ---
                if (engine.state.preparedDrugs.isNotEmpty)
                  Positioned(
                    bottom: 85, // Tuż nad dolnymi przyciskami narzędzi
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
                              // Dekodujemy nasz zaawansowany format (Lek|Dawka|Popitka)
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
                                onPressed: () {
                                  engine.administerDrug(index);
                                },
                              );
                            },
                          ),
                        ),
                      ],
                    ),
                  ),

                // WARSTWA 4: Przyciski narzędzi
                Positioned(
                  bottom: 20,
                  left: 0,
                  right: 0,
                  child: Row(
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
                        onPressed: () {
                          engine.toggleAirwayMenu();
                          _pageController.animateToPage(
                            1,
                            duration: const Duration(milliseconds: 300),
                            curve: Curves.easeInOut,
                          );
                        },
                      ),
                      _buildOverlayButton(
                        icon: Icons.backpack,
                        color: Colors.orange[900]!,
                        label: "Diagnostyka",
                        onPressed: () {
                          engine.toggleBag();
                          _pageController.animateToPage(
                            1,
                            duration: const Duration(milliseconds: 300),
                            curve: Curves.easeInOut,
                          );
                        },
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
                    ],
                  ),
                ),
              ],
            );
          },
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
          heroTag:
              label, // Ważne dla Fluttera, żeby unikać konfliktów hero tagów
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
