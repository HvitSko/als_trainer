import 'package:flutter/material.dart';
import '../logic/game_engine.dart';
import 'patient_view.dart';
import 'monitor_view.dart';
import '../widgets/inventory/ampularium.dart';
import '../widgets/inventory/airway_dialog.dart';
import '../widgets/inventory/diagnostics_dialog.dart';

class MainGameScreen extends StatefulWidget {
  const MainGameScreen({super.key});

  @override
  State<MainGameScreen> createState() => _MainGameScreenState();
}

class _MainGameScreenState extends State<MainGameScreen> {
  final GameEngine engine = GameEngine();
  final PageController _pageController = PageController(initialPage: 0);

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
                    Icon(Icons.person, color: Colors.white.withOpacity(0.5)),
                    const SizedBox(width: 8),
                    Text(
                      "< Przesuń >",
                      style: TextStyle(color: Colors.white.withOpacity(0.5)),
                    ),
                    const SizedBox(width: 8),
                    Icon(
                      Icons.monitor_heart,
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
                        label: "Leki",
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
                        onPressed: () {
                          showDialog(
                            context: context,
                            builder: (context) => AirwayDialog(engine: engine),
                          );
                        },
                      ),
                      _buildOverlayButton(
                        icon: Icons.search,
                        color: Colors.orange[900]!,
                        label: "4H4T",
                        onPressed: () {
                          showDialog(
                            context: context,
                            builder: (context) =>
                                DiagnosticsDialog(engine: engine),
                          );
                        },
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
