import 'package:flutter/material.dart';
import '../logic/game_engine.dart';
import '../widgets/inventory/intubation_minigame_dialog.dart'; // WAŻNE!
import '../widgets/inventory/iv_minigame_dialog.dart';
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
  bool _showIvMenu = false; // NOWE: Czy pokazujemy rozmiary wenflonów?
  bool _showIgelMenu = false;

  int _lastLogCount = 0;
  String _hudLog = "";
  Timer? _hudLogTimer;

  @override
  void initState() {
    super.initState();
    _lastLogCount = widget.engine.state.log.length;
    widget.engine.addListener(_onEngineChange);
  }

  @override
  void dispose() {
    // Odpinamy ucho, żeby nie wywołać wycieku pamięci!
    widget.engine.removeListener(_onEngineChange);
    _resultTimer?.cancel();
    _hudLogTimer?.cancel();
    super.dispose();
  }

  // Ta funkcja odpala się za każdym razem, gdy engine robi notifyListeners()
  // Ta funkcja odpala się za każdym razem, gdy engine robi notifyListeners()
  void _onEngineChange() {
    if (!mounted) return;

    // ZMIANA EBM: Sprawdzamy stan filtru logów (state.log), a nie pełnego audytu (state.auditLog)
    if (widget.engine.state.log.length > _lastLogCount) {
      String newLog = widget.engine.state.log.first;
      String cleanLog = newLog.contains("]")
          ? newLog.substring(newLog.indexOf(']') + 2)
          : newLog;

      setState(() {
        _hudLog = cleanLog;
        _lastLogCount = widget.engine.state.log.length;
      });

      _hudLogTimer?.cancel();
      _hudLogTimer = Timer(const Duration(seconds: 4), () {
        if (mounted) setState(() => _hudLog = "");
      });
    }
  }

  void _showResult(String tool, String target) {
    // SPECJALNY PRZYPADEK: RURKA ETI WYWALA MINIGRĘ I SPRAWDZA TLEN!
    if (tool == "Rurka ETI" && target == "Głowa") {
      setState(() => _equippedTool = null);

      if (!widget.engine.state.isPreoxygenated) {
        widget.engine.verifyPreoxygenationBeforeETI();
        Future.delayed(const Duration(seconds: 2), () {
          if (mounted) {
            showDialog(
              context: context,
              builder: (context) =>
                  IntubationMinigameDialog(engine: widget.engine),
            );
          }
        });
      } else {
        showDialog(
          context: context,
          builder: (context) => IntubationMinigameDialog(engine: widget.engine),
        );
      }
      return;
    }
    if (tool.startsWith("Kaniula") && target.contains("Zgięcie")) {
      setState(() => _equippedTool = null);
      showDialog(
        context: context,
        builder: (_) => IvMinigameDialog(engine: widget.engine),
      );
      return;
    }

    String result = widget.engine.performTargetedExam(tool, target);
    setState(() => _examResult = result);
    _resultTimer?.cancel();
    _resultTimer = Timer(const Duration(seconds: 4), () {
      if (mounted) setState(() => _examResult = "");
    });
  }

  IconData _getIconForTool(String tool) {
    if (tool.contains("I-gel")) return Icons.masks;
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
      case "Worek BVM":
        return Icons.air;
      case "Rurka ETI":
        return Icons.straighten;
      default:
        return Icons.build;
    }
  }

  String _getDynamicLabel(String baseTarget) {
    if (_equippedTool == null) return baseTarget;
    if (_equippedTool == "USG: Hokus POCUS") {
      if (baseTarget.contains("Klatka")) return "USG: Opłucna";
      if (baseTarget == "Bok Prawy") return "USG: Morison";
      if (baseTarget == "Bok Lewy") return "USG: Śledziona";
      if (baseTarget == "Nadbrzusze") return "USG: Serce";
      if (baseTarget == "Podbrzusze") return "USG: Miednica";
    } else if (_equippedTool == "Stetoskop") {
      if (baseTarget == "Nadbrzusze") return "Osłuchaj: Żołądek";
      if (baseTarget.contains("Bok")) return "Osłuchaj: Podstawy";
      if (baseTarget.contains("Klatka")) return "Osłuchaj: Szczyty";
    } else if (_equippedTool == "Glukometr" ||
        _equippedTool == "Pulsoksymetr") {
      if (baseTarget.contains("Dłoń") || baseTarget.contains("Noga"))
        return "Nakłuj / Klips";
    } else if (_equippedTool == "Worek BVM" ||
        _equippedTool == "Rurka ETI" ||
        _equippedTool!.contains("I-gel")) {
      if (baseTarget == "Głowa") return "ZABEZPIECZ DROGI";
    }
    return baseTarget;
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Positioned.fill(
          child: Image.asset(
            'assets/images/patient_body.png',
            fit: BoxFit.cover,
            errorBuilder: (context, error, stackTrace) =>
                const Center(child: Text("Brak grafiki!")),
          ),
        ),

        // --- ZNACZNIKI DIAGNOSTYCZNE ---
        Align(
          alignment: const Alignment(-0.85, -0.05),
          child: _buildDropZone("Głowa", 100, 100),
        ),
        Align(
          alignment: const Alignment(-0.65, -0.05),
          child: _buildDropZone("Szyja", 80, 80),
        ),
        Align(
          alignment: const Alignment(-0.45, -0.25),
          child: _buildDropZone("Klatka Lewa", 100, 90),
        ),
        Align(
          alignment: const Alignment(-0.45, 0.20),
          child: _buildDropZone("Klatka Prawa", 100, 90),
        ),
        Align(
          alignment: const Alignment(-0.25, -0.05),
          child: _buildDropZone("Nadbrzusze", 110, 90),
        ),
        Align(
          alignment: const Alignment(0.05, -0.05),
          child: _buildDropZone("Podbrzusze", 110, 90),
        ),
        Align(
          alignment: const Alignment(-0.20, -0.40),
          child: _buildDropZone("Bok Lewy", 90, 80),
        ),
        Align(
          alignment: const Alignment(-0.20, 0.35),
          child: _buildDropZone("Bok Prawy", 90, 80),
        ),
        Align(
          alignment: const Alignment(-0.35, -0.65),
          child: _buildDropZone("Zgięcie Lewa", 80, 80),
        ),
        Align(
          alignment: const Alignment(-0.35, 0.55),
          child: _buildDropZone("Zgięcie Prawa", 80, 80),
        ),
        Align(
          alignment: const Alignment(-0.10, -0.75),
          child: _buildDropZone("Dłoń Lewa", 80, 80),
        ),
        Align(
          alignment: const Alignment(-0.10, 0.65),
          child: _buildDropZone("Dłoń Prawa", 80, 80),
        ),
        Align(
          alignment: const Alignment(0.55, -0.25),
          child: _buildDropZone("Noga Lewa", 140, 100),
        ),
        Align(
          alignment: const Alignment(0.55, 0.15),
          child: _buildDropZone("Noga Prawa", 140, 100),
        ),
        // --- 5. GÓRNY HUD: POWIADOMIENIA Z DZIENNIKA (EBM) ---
        Builder(
          builder: (context) {
            bool isRoutineExamLog =
                _hudLog.startsWith("BADANIE:") ||
                _hudLog.startsWith("USG:") ||
                _hudLog.startsWith("AKCJA: Założono") ||
                _hudLog.startsWith("DIAGNOZA");

            bool showHud =
                _hudLog.isNotEmpty &&
                !(isRoutineExamLog && _examResult.isNotEmpty);

            if (!showHud) return const SizedBox.shrink();

            return Positioned(
              top: 20,
              left: MediaQuery.of(context).size.width * 0.15,
              right: MediaQuery.of(context).size.width * 0.15,
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
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ),
            );
          },
        ),
        // --- WYNIKI POP-UP ---
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

        // --- INTERFEJS NARZĘDZI (UKRYTY LUB WIDOCZNY) ---
        if (_equippedTool == null) ...[
          if (widget.engine.state.isBagOpen) _buildBagOverlay(),
          if (widget.engine.state.isAirwayMenuOpen) _buildAirwayOverlay(),
        ] else ...[
          // KOSZ / ODKŁADANIE
          Positioned(
            bottom: 130,
            left: 30,
            child: DragTarget<String>(
              onAcceptWithDetails: (details) =>
                  setState(() => _equippedTool = null),
              builder: (context, candidate, rejected) => Column(
                children: [
                  Icon(
                    Icons.backpack,
                    size: candidate.isNotEmpty ? 70 : 50,
                    color: candidate.isNotEmpty
                        ? Colors.orangeAccent
                        : Colors.grey,
                  ),
                  Text(
                    "Odłóż",
                    style: TextStyle(
                      color: candidate.isNotEmpty
                          ? Colors.orangeAccent
                          : Colors.grey,
                    ),
                  ),
                ],
              ),
            ),
          ),
          // NARZĘDZIE W RĘKU
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

  // NAKŁADKA: TORBA DIAGNOSTYCZNA
  Widget _buildBagOverlay() {
    return Positioned(
      bottom: 120,
      left: 10,
      right: 10,
      child: Center(
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
          decoration: BoxDecoration(
            color: Colors.black87,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: Colors.orange),
          ),
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: _showIvMenu
                ? Row(
                    // PODMENU WENFLONÓW
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.arrow_back, color: Colors.white),
                        onPressed: () => setState(() => _showIvMenu = false),
                      ),
                      const Padding(
                        padding: EdgeInsets.symmetric(horizontal: 8.0),
                        child: Text(
                          "WYBIERZ ROZMIAR: ",
                          style: TextStyle(
                            color: Colors.orange,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      _buildToolEquipButton(
                        "Kaniula 14G (Pomarańczowa)",
                        Icons.colorize,
                      ),
                      _buildToolEquipButton(
                        "Kaniula 18G (Zielona)",
                        Icons.colorize,
                      ),
                      _buildToolEquipButton(
                        "Kaniula 20G (Różowa)",
                        Icons.colorize,
                      ),
                    ],
                  )
                : Row(
                    // GŁÓWNA TORBA
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Padding(
                        padding: EdgeInsets.symmetric(horizontal: 8.0),
                        child: Text(
                          "TORBA: ",
                          style: TextStyle(
                            color: Colors.orange,
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
                      _buildToolEquipButton("USG: Hokus POCUS", Icons.waves),
                      _buildToolEquipButton("Folia NRC", Icons.ac_unit),
                      // TEN PRZYCISK OTWIERA PODMENU ZAMIAST WYPOSAŻAĆ
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 4.0),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              icon: const Icon(
                                Icons.vaccines,
                                color: Colors.white,
                                size: 28,
                              ),
                              onPressed: () =>
                                  setState(() => _showIvMenu = true),
                            ),
                            const Text(
                              "Kaniula IV",
                              style: TextStyle(color: Colors.grey, fontSize: 9),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
          ),
        ),
      ),
    );
  }

  // NAKŁADKA: ODDECH I DROGI ODDECHOWE
  Widget _buildAirwayOverlay() {
    return Positioned(
      bottom: 120,
      left: 10,
      right: 10,
      child: Center(
        child: Container(
          constraints: BoxConstraints(
            maxWidth: MediaQuery.of(context).size.width * 0.75,
          ),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.black87,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: Colors.cyan),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue[900],
                    ),
                    onPressed: widget.engine.performManualAirwayManeuver,
                    child: const Text("Rękoczyn Udrożnienia"),
                  ),
                  // NOWY PRZYCISK: PREOKSYGENACJA ZMARTWYCHWSTAŁA
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.lightBlue[700],
                    ),
                    onPressed: widget.engine.preoxygenate,
                    child: const Text(
                      "Preoksygenacja",
                      style: TextStyle(color: Colors.white),
                    ),
                  ),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.yellow[900],
                    ),
                    onPressed: () {
                      widget.engine.state.isCapnographyAttached = true;
                      widget.engine.closeMenus();
                    },
                    child: const Text(
                      "Podłącz ETCO2",
                      style: TextStyle(
                        color: Colors.black,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 5),
              Row(
                children: [
                  const Icon(Icons.air, color: Colors.cyan),
                  Expanded(
                    child: Slider(
                      value: widget.engine.state.oxygenFlow.toDouble(),
                      min: 0,
                      max: 20,
                      divisions: 20,
                      label: "${widget.engine.state.oxygenFlow} l/min",
                      onChanged: (val) {
                        // CICHA AKTUALIZACJA: Zmienia pozycję suwaka na ekranie, ale NIE wysyła info do logów EBM!
                        setState(
                          () => widget.engine.state.oxygenFlow = val.toInt(),
                        );
                      },
                      onChangeEnd: (val) {
                        // GŁOŚNA AKTUALIZACJA: Gdy puścisz palec, silnik dostaje info i wywala (bądź nie) błąd EBM.
                        widget.engine.setOxygenFlow(val.toInt());
                      },
                    ),
                  ),
                  Text(
                    "${widget.engine.state.oxygenFlow} l/min",
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: _showIgelMenu
                    ? Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            icon: const Icon(
                              Icons.arrow_back,
                              color: Colors.white,
                            ),
                            onPressed: () =>
                                setState(() => _showIgelMenu = false),
                          ),
                          const Padding(
                            padding: EdgeInsets.symmetric(horizontal: 8.0),
                            child: Text(
                              "WYBIERZ ROZMIAR: ",
                              style: TextStyle(
                                color: Colors.cyan,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          _buildToolEquipButton("I-gel #3", Icons.looks_3),
                          _buildToolEquipButton("I-gel #4", Icons.looks_4),
                          _buildToolEquipButton("I-gel #5", Icons.looks_5),
                        ],
                      )
                    : Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Padding(
                            padding: EdgeInsets.symmetric(horizontal: 8.0),
                            child: Text(
                              "SPRZĘT: ",
                              style: TextStyle(
                                color: Colors.cyan,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          _buildToolEquipButton("Worek BVM", Icons.masks),
                          Padding(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 4.0,
                            ),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                IconButton(
                                  icon: const Icon(
                                    Icons.looks_one,
                                    color: Colors.white,
                                    size: 28,
                                  ),
                                  onPressed: () =>
                                      setState(() => _showIgelMenu = true),
                                ),
                                const Text(
                                  "I-gel (SGA)",
                                  style: TextStyle(
                                    color: Colors.grey,
                                    fontSize: 9,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          _buildToolEquipButton("Rurka ETI", Icons.straighten),
                        ],
                      ),
              ),
            ],
          ),
        ),
      ),
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
            onPressed: () {
              setState(() {
                _equippedTool = name;
                widget.engine.closeMenus();
              }); // ZAMYKA MENU PO WYCIĄGNIĘCIU!
            },
          ),
          Text(name, style: const TextStyle(color: Colors.grey, fontSize: 9)),
        ],
      ),
    );
  }

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
