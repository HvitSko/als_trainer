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
  String? _equippedTool;

  void _showResult(String tool, String target) {
    String result = widget.engine.performTargetedExam(tool, target);
    setState(() => _examResult = result);
    _resultTimer?.cancel();
    _resultTimer = Timer(const Duration(seconds: 4), () {
      if (mounted) setState(() => _examResult = "");
    });
  }

  IconData _getIconForTool(String tool) {
    switch (tool) {
      case "Latarka":
        return Icons.highlight;
      case "Stetoskop":
        return Icons.medical_services;
      case "Termometr":
        return Icons.thermostat;
      case "Glukometr":
        return Icons.bloodtype;
      case "Pulsoksymetr":
        return Icons.monitor_heart;
      case "Oglądanie":
        return Icons.visibility;
      case "USG: Hokus POCUS":
        return Icons.waves;
      case "Folia NRC":
        return Icons.ac_unit;
      default:
        return Icons.build;
    }
  }

  // NOWA FUNKCJA: Inteligentne podpowiadanie procedur
  String _getDynamicLabel(String baseTarget) {
    if (_equippedTool == null) return baseTarget;

    if (_equippedTool == "USG: Hokus POCUS") {
      if (baseTarget.contains("Klatka")) return "USG: Opłucna (Sliding)";
      if (baseTarget == "Bok Prawy") return "USG: Morison / IVC";
      if (baseTarget == "Bok Lewy") return "USG: Zachyłek śledzionowy";
      if (baseTarget == "Nadbrzusze") return "USG: Serce (Podmostkowe)";
      if (baseTarget == "Podbrzusze") return "USG: Pęcherz/Miednica";
    } else if (_equippedTool == "Stetoskop") {
      if (baseTarget == "Nadbrzusze") return "Osłuchaj: Żołądek";
      if (baseTarget.contains("Bok")) return "Osłuchaj: Podstawy Płuc";
      if (baseTarget.contains("Klatka")) return "Osłuchaj: Szczyty/Środek";
    } else if (_equippedTool == "Glukometr" ||
        _equippedTool == "Pulsoksymetr") {
      if (baseTarget.contains("Dłoń") || baseTarget.contains("Noga"))
        return "Nakłuj / Załóż Klips";
    }

    return baseTarget; // Domyślna nazwa strefy
  }

  @override
  void dispose() {
    _resultTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Positioned.fill(
          child: Image.asset(
            'assets/images/patient_body.png',
            fit: BoxFit.cover,
            errorBuilder: (context, error, stackTrace) => const Center(
              child: Text("Brak grafiki!", style: TextStyle(color: Colors.red)),
            ),
          ),
        ),

        // --- 2. ZNACZNIKI DIAGNOSTYCZNE (ANATOMIA SZCZEGÓŁOWA) ---
        // X: Głowa (-0.85) -> Klatka (-0.45) -> Brzuch (-0.15) -> Nogi (0.50)
        // Y: Góra ekranu (-0.5, prawa strona pacjenta) -> Dół ekranu (0.5, lewa strona pacjenta)
        Align(
          alignment: const Alignment(-0.85, -0.05),
          child: _buildDropZone("Głowa", 100, 100),
        ),
        Align(
          alignment: const Alignment(-0.65, -0.05),
          child: _buildDropZone("Szyja", 80, 80),
        ),

        // Klatka rozbita
        Align(
          alignment: const Alignment(-0.45, -0.25),
          child: _buildDropZone("Klatka Prawa", 100, 90),
        ), // Prawa str. pacjenta (góra ekranu)
        Align(
          alignment: const Alignment(-0.45, 0.20),
          child: _buildDropZone("Klatka Lewa", 100, 90),
        ), // Lewa str. pacjenta (dół ekranu)
        // Brzuch rozbity
        Align(
          alignment: const Alignment(-0.25, -0.05),
          child: _buildDropZone("Nadbrzusze", 110, 90),
        ),
        Align(
          alignment: const Alignment(0.05, -0.05),
          child: _buildDropZone("Podbrzusze", 110, 90),
        ),

        // Boki (Morrison i Keller) - obok brzucha/klatki
        Align(
          alignment: const Alignment(-0.20, -0.40),
          child: _buildDropZone("Bok Prawy", 90, 80),
        ),
        Align(
          alignment: const Alignment(-0.20, 0.35),
          child: _buildDropZone("Bok Lewy", 90, 80),
        ),

        // Ręce (Zgięcia łokciowe i Dłonie)
        Align(
          alignment: const Alignment(-0.35, -0.65),
          child: _buildDropZone("Zgięcie Prawa", 80, 80),
        ),
        Align(
          alignment: const Alignment(-0.35, 0.55),
          child: _buildDropZone("Zgięcie Lewa", 80, 80),
        ),
        Align(
          alignment: const Alignment(-0.10, -0.75),
          child: _buildDropZone("Dłoń Prawa", 80, 80),
        ),
        Align(
          alignment: const Alignment(-0.10, 0.65),
          child: _buildDropZone("Dłoń Lewa", 80, 80),
        ),

        // Nogi rozbite
        Align(
          alignment: const Alignment(0.55, -0.25),
          child: _buildDropZone("Noga Prawa", 140, 100),
        ),
        Align(
          alignment: const Alignment(0.55, 0.15),
          child: _buildDropZone("Noga Lewa", 140, 100),
        ),

        // --- 3. WYNIKI (POP-UP) ---
        if (_examResult.isNotEmpty)
          Align(
            alignment: const Alignment(0.0, -0.8),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
              decoration: BoxDecoration(
                color: Colors.blue[900]?.withOpacity(0.9),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.cyanAccent, width: 2),
              ),
              child: Text(
                _examResult,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),

        // --- 4. INTERFEJS NARZĘDZI ---
        if (_equippedTool == null) ...[
          Positioned(
            bottom: 120,
            left: 10,
            right: 10,
            child: Center(
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 10,
                ),
                decoration: BoxDecoration(
                  color: Colors.black87,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: Colors.grey),
                ),
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Padding(
                        padding: EdgeInsets.symmetric(horizontal: 8.0),
                        child: Text(
                          "TORBA: ",
                          style: TextStyle(
                            color: Colors.grey,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      _buildToolEquipButton("Oglądanie", Icons.visibility),
                      _buildToolEquipButton("Latarka", Icons.highlight),
                      _buildToolEquipButton(
                        "Stetoskop",
                        Icons.medical_services,
                      ),
                      _buildToolEquipButton("Termometr", Icons.thermostat),
                      _buildToolEquipButton("Glukometr", Icons.bloodtype),
                      _buildToolEquipButton(
                        "Pulsoksymetr",
                        Icons.monitor_heart,
                      ),
                      _buildToolEquipButton(
                        "USG: Hokus POCUS",
                        Icons.waves,
                      ), // ZMIANA NAZWY
                      _buildToolEquipButton("Folia NRC", Icons.ac_unit),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ] else ...[
          Positioned(
            bottom: 130,
            left: 30,
            child: DragTarget<String>(
              onAcceptWithDetails: (details) =>
                  setState(() => _equippedTool = null),
              builder: (context, candidate, rejected) {
                bool isHovered = candidate.isNotEmpty;
                return Column(
                  children: [
                    Icon(
                      Icons.backpack,
                      size: isHovered ? 70 : 50,
                      color: isHovered ? Colors.orangeAccent : Colors.grey,
                    ),
                    Text(
                      "Odłóż do torby",
                      style: TextStyle(
                        color: isHovered ? Colors.orangeAccent : Colors.grey,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
          Positioned(
            bottom: 130,
            right: 30,
            child: Draggable<String>(
              data: _equippedTool,
              feedback: Material(
                color: Colors.transparent,
                child: Icon(
                  _getIconForTool(_equippedTool!),
                  size: 80,
                  color: Colors.blueAccent,
                ),
              ),
              childWhenDragging: Opacity(
                opacity: 0.2,
                child: Column(
                  children: [
                    Icon(
                      _getIconForTool(_equippedTool!),
                      size: 60,
                      color: Colors.greenAccent,
                    ),
                    const Text(
                      "Przeciągasz...",
                      style: TextStyle(color: Colors.grey),
                    ),
                  ],
                ),
              ),
              child: Column(
                children: [
                  Icon(
                    _getIconForTool(_equippedTool!),
                    size: 60,
                    color: Colors.greenAccent,
                  ),
                  Text(
                    "W RĘKU:\n$_equippedTool",
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildToolEquipButton(String name, IconData icon) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4.0),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          IconButton(
            icon: Icon(icon, color: Colors.white, size: 28),
            tooltip: "Wyciągnij: $name",
            onPressed: () => setState(() => _equippedTool = name),
          ),
          Text(name, style: const TextStyle(color: Colors.grey, fontSize: 9)),
        ],
      ),
    );
  }

  // Zmiana: Przyjmujemy tylko baseTarget, nazwa labelek generuje się dynamicznie!
  Widget _buildDropZone(String baseTarget, double width, double height) {
    return DragTarget<String>(
      onAcceptWithDetails: (details) => _showResult(details.data, baseTarget),
      builder: (context, candidateData, rejectedData) {
        bool isHovered = candidateData.isNotEmpty;
        if (_equippedTool == null)
          return SizedBox(width: width, height: height);

        String displayLabel = _getDynamicLabel(baseTarget);

        return Container(
          width: width,
          height: height,
          decoration: BoxDecoration(
            color: isHovered
                ? Colors.greenAccent.withOpacity(0.3)
                : Colors.white.withOpacity(0.05),
            border: Border.all(
              color: isHovered ? Colors.greenAccent : Colors.white24,
              width: isHovered ? 3 : 1,
            ),
            borderRadius: BorderRadius.circular(100),
          ),
          child: isHovered
              ? Center(
                  child: Text(
                    displayLabel,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      backgroundColor: Colors.black45,
                    ),
                  ),
                )
              : null,
        );
      },
    );
  }
}
