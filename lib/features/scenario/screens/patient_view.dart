import 'package:flutter/material.dart';
import '../logic/game_engine.dart';
import 'dart:async';

class PatientView extends StatefulWidget {
  final GameEngine engine;
  const PatientView({super.key, required this.engine});

  @override
  State<PatientView> createState() => _PatientViewState();
}

class _PatientViewState extends State<PatientView> {
  String _examResult = "";
  Timer? _resultTimer;

  // Funkcja wyświetlająca wynik badania na środku ekranu na 4 sekundy
  void _showResult(String tool, String target) {
    String result = widget.engine.performTargetedExam(tool, target);
    setState(() {
      _examResult = result;
    });

    _resultTimer?.cancel();
    _resultTimer = Timer(const Duration(seconds: 4), () {
      if (mounted) setState(() => _examResult = "");
    });
  }

  @override
  void dispose() {
    _resultTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // --- WARSTWA GÓRNA: PACJENT I DRAG TARGETY ---
        Expanded(
          child: Stack(
            children: [
              // 1. Tło - Wygenerowany Pacjent
              Center(
                child: Image.asset(
                  'assets/images/patient_body.png',
                  fit: BoxFit.contain, // Skaluje zachowując proporcje
                  errorBuilder: (context, error, stackTrace) => const Center(
                    child: Text(
                      "Brak pliku patient_body.png w assets/images/",
                      style: TextStyle(color: Colors.red),
                    ),
                  ),
                ),
              ),

              // 2. Obszary rzutu (Drag Targets)
              // Głowa / Oczy (Alignment Y: -0.8 to góra ekranu)
              Align(
                alignment: const Alignment(0.0, -0.75),
                child: _buildDropZone("Oczy/Głowa", "Oczy", 100, 100),
              ),
              // Klatka Piersiowa (Alignment Y: -0.3 to środek klatki)
              Align(
                alignment: const Alignment(0.0, -0.2),
                child: _buildDropZone("Klatka Piersiowa", "Klatka", 150, 120),
              ),
              // Brzuch/Miednica (Na przyszłość do USG eFAST)
              Align(
                alignment: const Alignment(0.0, 0.3),
                child: _buildDropZone("Brzuch", "Brzuch", 120, 100),
              ),

              // 3. Nakładka z wynikiem badania (Pop-up)
              if (_examResult.isNotEmpty)
                Center(
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 24,
                      vertical: 16,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.blue[900]?.withOpacity(0.9),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.cyanAccent, width: 2),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.cyanAccent.withOpacity(0.5),
                          blurRadius: 10,
                        ),
                      ],
                    ),
                    child: Text(
                      _examResult,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),

        // --- WARSTWA DOLNA: PRZYBORNIK (DRAGGABLE TOOLS) ---
        Container(
          height: 100,
          color: Colors.grey[900],
          padding: const EdgeInsets.all(8),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                "NARZĘDZIA DIAGNOSTYCZNE (Przeciągnij na pacjenta):",
                style: TextStyle(
                  color: Colors.grey,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 5),
              Expanded(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    _buildDraggableTool("Latarka", Icons.highlight),
                    _buildDraggableTool("Stetoskop", Icons.medical_services),
                    _buildDraggableTool("Termometr", Icons.thermostat),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // --- KOMPONENTY POMOCNICZE UI ---

  // Strefa Zrzutu na Pacjencie
  Widget _buildDropZone(
    String label,
    String targetName,
    double width,
    double height,
  ) {
    return DragTarget<String>(
      onAcceptWithDetails: (details) => _showResult(details.data, targetName),
      builder: (context, candidateData, rejectedData) {
        bool isHovered = candidateData.isNotEmpty; // Czy coś nad tym leci?
        return Container(
          width: width,
          height: height,
          decoration: BoxDecoration(
            color: isHovered
                ? Colors.greenAccent.withOpacity(0.3)
                : Colors.transparent,
            border: Border.all(
              color: isHovered ? Colors.greenAccent : Colors.white12,
              width: isHovered ? 2 : 1,
            ),
            borderRadius: BorderRadius.circular(50), // Robimy owale
          ),
          child: isHovered
              ? Center(
                  child: Text(
                    label,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                )
              : null,
        );
      },
    );
  }

  // Narzędzie do przeciągania
  Widget _buildDraggableTool(String name, IconData icon) {
    return Draggable<String>(
      data: name,
      feedback: Material(
        color: Colors.transparent,
        child: Column(
          children: [
            Icon(icon, color: Colors.blueAccent, size: 50),
            Text(
              name,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                shadows: [Shadow(color: Colors.black, blurRadius: 5)],
              ),
            ),
          ],
        ),
      ),
      childWhenDragging: Opacity(
        opacity: 0.3,
        child: Column(
          children: [
            Icon(icon, color: Colors.grey, size: 40),
            Text(
              name,
              style: const TextStyle(color: Colors.grey, fontSize: 10),
            ),
          ],
        ),
      ),
      child: Column(
        children: [
          Icon(icon, color: Colors.white, size: 40),
          Text(name, style: const TextStyle(color: Colors.white, fontSize: 10)),
        ],
      ),
    );
  }
}
