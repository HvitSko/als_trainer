import 'package:flutter/material.dart';
import '../logic/game_engine.dart';
import '../models/scenario_model.dart'; // NOWY IMPORT
import 'patient_view.dart';
import 'monitor_view.dart';
import '../widgets/inventory/ampularium.dart';
import '../widgets/inventory/airway_dialog.dart';
import '../widgets/inventory/diagnostics_dialog.dart';
import '../widgets/inventory/h4t_dialog.dart';

class MainGameScreen extends StatefulWidget {
  final Scenario scenario; // NOWE: Ekran gry żąda scenariusza!

  const MainGameScreen({super.key, required this.scenario});

  @override
  State<MainGameScreen> createState() => _MainGameScreenState();
}

class _MainGameScreenState extends State<MainGameScreen> {
  late GameEngine engine; // ZMIANA na late
  final PageController _pageController = PageController(initialPage: 0);

  @override
  void initState() {
    super.initState();
    // Inicjalizujemy silnik NASZYM scenariuszem
    engine = GameEngine(widget.scenario);
  }

  // ... (reszta kodu dispose() i build() bez zmian)

  @override
  void dispose() {
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
            // --- WARSTWA 1: PAGE VIEW ---
            PageView(
              controller: _pageController,
              children: [
                PatientView(engine: engine),
                MonitorView(engine: engine),
              ],
            ),

            // --- WARSTWA 2: WSKAŹNIK EKRANU ---
            Positioned(
              top: 10,
              left: 0,
              right: 0,
              child: IgnorePointer(
                // Ignoruje kliknięcia, żeby nie blokować UI pod spodem
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // ignore: deprecated_member_use
                    Icon(Icons.person, color: Colors.white.withOpacity(0.5)),
                    const SizedBox(width: 8),
                    Text(
                      "< Przesuń >",
                      // ignore: deprecated_member_use
                      style: TextStyle(color: Colors.white.withOpacity(0.5)),
                    ),
                    const SizedBox(width: 8),
                    Icon(
                      Icons.monitor_heart,
                      // ignore: deprecated_member_use
                      color: Colors.white.withOpacity(0.5),
                    ),
                  ],
                ),
              ),
            ),

            // --- WARSTWA 3: GLOBAL OVERLAY STACK (Narzędzia) ---
            Positioned(
              bottom: 20,
              left: 0,
              right: 0,
              child: AnimatedBuilder(
                animation: engine,
                builder: (context, _) {
                  return Row(
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
                            : () {
                                showDialog(
                                  context: context,
                                  builder: (context) => AmpulariumDialog(
                                    onDrugPrepared: (drug, dose) =>
                                        engine.prepareDrug(drug, dose),
                                  ),
                                );
                              },
                      ),
                      _buildOverlayButton(
                        icon: Icons.air,
                        color: Colors.cyan[800]!,
                        label: "Oddech",
                        onPressed: () => showDialog(
                          context: context,
                          builder: (context) => AirwayDialog(engine: engine),
                        ),
                      ),
                      _buildOverlayButton(
                        icon: Icons.backpack,
                        color: Colors.orange[900]!,
                        label: "Torba",
                        onPressed: () => showDialog(
                          context: context,
                          builder: (context) =>
                              DiagnosticsDialog(engine: engine),
                        ), // W torbie są narzędzia
                      ),
                      _buildOverlayButton(
                        icon: Icons.psychology,
                        color: Colors.purple[800]!,
                        label: "4H4T",
                        onPressed: () => showDialog(
                          context: context,
                          builder: (context) => H4TDialog(engine: engine),
                        ), // NOWY WIDŻET
                      ),
                    ],
                  );
                },
              ),
            ),

            // --- WARSTWA 4: PŁYWAJĄCA TACKA NA LEKI ---
            Positioned(
              bottom: 90,
              right: 20,
              child: AnimatedBuilder(
                animation: engine,
                builder: (context, _) {
                  if (engine.state.preparedDrugs.isEmpty)
                    // ignore: curly_braces_in_flow_control_structures
                    return const SizedBox.shrink();
                  return Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.black87,
                      border: Border.all(color: Colors.blueAccent),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: engine.state.preparedDrugs.asMap().entries.map((
                        entry,
                      ) {
                        int index = entry.key;
                        String drugNameRaw = entry.value;
                        bool isReady = !drugNameRaw.startsWith(
                          'Przygotowywanie',
                        );
                        return Padding(
                          padding: const EdgeInsets.symmetric(vertical: 4.0),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                drugNameRaw.replaceAll('|', ' '),
                                style: TextStyle(
                                  color: isReady
                                      ? Colors.greenAccent
                                      : Colors.yellow,
                                  fontSize: 12,
                                ),
                              ),
                              const SizedBox(width: 10),
                              if (isReady)
                                ElevatedButton(
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.red,
                                    minimumSize: const Size(60, 30),
                                    padding: EdgeInsets.zero,
                                  ),
                                  onPressed: () => engine.administerDrug(index),
                                  child: const Text(
                                    'PODAĆ',
                                    style: TextStyle(fontSize: 10),
                                  ),
                                ),
                            ],
                          ),
                        );
                      }).toList(),
                    ),
                  );
                },
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
