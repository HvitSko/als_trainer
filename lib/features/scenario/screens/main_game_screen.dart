// lib/features/scenario/screens/main_game_screen.dart

import 'package:flutter/material.dart';
import '../logic/game_engine.dart';
// import '../widgets/inventory/ampularium.dart'; // Odkomentuj jak przeniesiemy stary kod
// import '../widgets/inventory/airway_dialog.dart';
// import '../widgets/inventory/diagnostics_dialog.dart';

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
            // --- WARSTWA 1: PAGE VIEW (PRZEWIJANE EKRANY) ---
            PageView(
              controller: _pageController,
              children: [
                _buildPatientViewSkeleton(), // Ekran fizyczny
                _buildMonitorViewSkeleton(), // Ekran maszyny
              ],
            ),

            // --- WARSTWA 2: GLOBAL OVERLAY STACK (Narzędzia) ---
            // Umieszczone na dole ekranu, zawsze widoczne
            Positioned(
              bottom: 20,
              left: 0,
              right: 0,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  FloatingActionButton(
                    heroTag: "btn_ampularium",
                    backgroundColor: Colors.blue[900],
                    child: const Icon(
                      Icons.medical_services,
                      color: Colors.white,
                    ),
                    onPressed: () {
                      // showDialog -> AmpulariumDialog
                    },
                  ),
                  FloatingActionButton(
                    heroTag: "btn_airway",
                    backgroundColor: Colors.cyan[800],
                    child: const Icon(Icons.air, color: Colors.white),
                    onPressed: () {
                      // showDialog -> AirwayDialog
                    },
                  ),
                  FloatingActionButton(
                    heroTag: "btn_diagnostics",
                    backgroundColor: Colors.orange[900],
                    child: const Icon(Icons.search, color: Colors.white),
                    onPressed: () {
                      // showDialog -> DiagnosticsDialog
                    },
                  ),
                ],
              ),
            ),

            // Opcjonalny wskaźnik strony (żeby gracz wiedział gdzie jest)
            Positioned(
              top: 10,
              left: 0,
              right: 0,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.person, color: Colors.white54),
                  const SizedBox(width: 8),
                  const Text(
                    "< Przesuń >",
                    style: TextStyle(color: Colors.white54),
                  ),
                  const SizedBox(width: 8),
                  const Icon(Icons.monitor_heart, color: Colors.white54),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // --- SKELETON: WIDOK PACJENTA (DOCELOWO ODDZIELNY PLIK) ---
  Widget _buildPatientViewSkeleton() {
    return Container(
      color: Colors.grey[900],
      padding: const EdgeInsets.all(20),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Text(
            "WIDOK PACJENTA (Physical View)",
            style: TextStyle(
              color: Colors.white,
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 20),
          const Placeholder(
            fallbackHeight: 150,
            color: Colors.blueGrey,
          ), // Tu będzie model pacjenta (grafika)
          const SizedBox(height: 20),
          Card(
            color: Colors.black54,
            child: ListTile(
              leading: const Icon(Icons.remove_red_eye, color: Colors.white),
              title: const Text(
                "Ocena wizualna",
                style: TextStyle(color: Colors.white),
              ),
              subtitle: const Text(
                "Skóra: Blada, chłodna\nKlatka piersiowa: Brak ruchów",
                style: TextStyle(color: Colors.grey),
              ),
            ),
          ),
          const SizedBox(height: 100), // Miejsce na pływające przyciski na dole
        ],
      ),
    );
  }

  // --- SKELETON: WIDOK MONITORA (DOCELOWO ODDZIELNY PLIK) ---
  Widget _buildMonitorViewSkeleton() {
    return Container(
      color: Colors.black87,
      padding: const EdgeInsets.all(20),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Text(
            "WIDOK MONITORA (Instrumental View)",
            style: TextStyle(
              color: Colors.redAccent,
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 20),
          const Placeholder(
            fallbackHeight: 200,
            color: Colors.red,
          ), // Tu będzie krzywa EKG i przyciski defibrylatora
          const SizedBox(height: 20),
          // Tutaj przerzucimy w przyszłości cały panel defibrylacji (ładowanie, wyładowanie)
          const Text(
            "Zapis EKG: ASYSTOLIA",
            style: TextStyle(color: Colors.red, fontSize: 20),
          ),
          const SizedBox(height: 100), // Miejsce na pływające przyciski na dole
        ],
      ),
    );
  }
}
