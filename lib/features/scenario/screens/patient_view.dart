import 'package:flutter/material.dart';
import '../logic/game_engine.dart';
import '../widgets/inventory/intubation_minigame_dialog.dart';
import '../widgets/inventory/iv_minigame_dialog.dart';
import '../models/als_state.dart';
import 'dart:async';
import '../../../app_localization.dart'; // IMPORT TŁUMACZA

class PatientView extends StatefulWidget {
  final GameEngine engine;
  const PatientView({super.key, required this.engine});

  @override
  State<PatientView> createState() => _PatientViewState();
}

class _PatientViewState extends State<PatientView>
    with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  String _examResult = "";
  String _hoveredZone = "";
  Timer? _resultTimer;
  String? _equippedTool;
  bool _showIvMenu = false;
  bool _showIgelMenu = false;

  @override
  void initState() {
    super.initState();
  }

  @override
  void dispose() {
    _resultTimer?.cancel();
    super.dispose();
  }

  void _showResult(String tool, String target) {
    if (tool != "USG: Hokus POCUS" && tool != "Stetoskop") {
      setState(() => _equippedTool = null);
    }

    if (tool == "Rurka ETI" && target == "Głowa") {
      setState(() => _equippedTool = null);
      if (!widget.engine.state.isPreoxygenated) {
        widget.engine.verifyPreoxygenationBeforeETI();
        Future.delayed(const Duration(seconds: 2), () {
          if (mounted)
            showDialog(
              context: context,
              builder: (context) =>
                  IntubationMinigameDialog(engine: widget.engine),
            );
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
      case "Ssak":
        return Icons.water_drop;
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
      case "Palec":
        return Icons.touch_app;
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
      if (baseTarget.contains("Klatka"))
        return AppLoc.tr("USG: Opłucna", "USG: Pleura");
      if (baseTarget == "Bok Prawy")
        return AppLoc.tr("USG: Zachyłek Morisona", "USG: Morison's Pouch");
      if (baseTarget == "Bok Lewy")
        return AppLoc.tr("USG: Zachyłek Kellera", "USG: Keller's Pouch");
      if (baseTarget == "Nadbrzusze")
        return AppLoc.tr("USG: Serce", "USG: Heart");
      if (baseTarget == "Podbrzusze")
        return AppLoc.tr("USG: Miednica", "USG: Pelvis");
    } else if (_equippedTool == "Stetoskop") {
      if (baseTarget == "Nadbrzusze")
        return AppLoc.tr("Osłuchaj: Żołądek", "Auscultate: Stomach");
      if (baseTarget.contains("Bok"))
        return AppLoc.tr("Osłuchaj: Podstawy", "Auscultate: Bases");
      if (baseTarget.contains("Klatka"))
        return AppLoc.tr("Osłuchaj: Szczyty", "Auscultate: Apices");
    } else if (_equippedTool == "Glukometr" ||
        _equippedTool == "Pulsoksymetr") {
      if (baseTarget.contains("Dłoń") || baseTarget.contains("Stopa"))
        return AppLoc.tr("Nakłuj / Klips", "Prick / Probe");
    } else if (_equippedTool == "Worek BVM" ||
        _equippedTool == "Rurka ETI" ||
        _equippedTool!.contains("I-gel") ||
        _equippedTool == "Ssak") {
      if (baseTarget == "Głowa")
        return AppLoc.tr("ZABEZPIECZ DROGI", "SECURE AIRWAY");
    } else if (_equippedTool == "Palec") {
      if (baseTarget.contains("Nadgarstek") ||
          baseTarget.contains("Stopa") ||
          baseTarget == "Szyja")
        return AppLoc.tr("Sprawdź Tętno", "Check Pulse");
      return AppLoc.tr("Omacaj", "Palpate");
    }
    return baseTarget;
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return Container(
      color: const Color(0xFF1A1A1A),
      child: Stack(
        children: [
          Positioned.fill(
            child: InteractiveViewer(
              panEnabled: true,
              minScale: 1.0,
              maxScale: 3.5,
              child: Center(
                child: AspectRatio(
                  aspectRatio: 1536 / 1024,
                  child: LayoutBuilder(
                    builder: (context, constraints) {
                      final w = constraints.maxWidth;
                      final h = constraints.maxHeight;

                      return Stack(
                        children: [
                          Positioned.fill(
                            child: Image.asset(
                              'assets/images/patient_body.png',
                              fit: BoxFit.fill,
                              errorBuilder: (context, error, stackTrace) =>
                                  const Center(
                                    child: Text(
                                      "Brak grafiki!",
                                      style: TextStyle(color: Colors.white),
                                    ),
                                  ),
                            ),
                          ),
                          _buildResponsiveZone(
                            "Głowa",
                            -0.76,
                            -0.11,
                            160,
                            120,
                            w,
                            h,
                          ),
                          _buildResponsiveZone(
                            "Szyja",
                            -0.62,
                            -0.10,
                            80,
                            95,
                            w,
                            h,
                          ),
                          _buildResponsiveZone(
                            "Klatka Lewa",
                            -0.50,
                            -0.22,
                            110,
                            100,
                            w,
                            h,
                          ),
                          _buildResponsiveZone(
                            "Klatka Prawa",
                            -0.50,
                            0.05,
                            110,
                            100,
                            w,
                            h,
                          ),
                          _buildResponsiveZone(
                            "Nadbrzusze",
                            -0.28,
                            -0.10,
                            100,
                            110,
                            w,
                            h,
                          ),
                          _buildResponsiveZone(
                            "Podbrzusze",
                            -0.12,
                            -0.08,
                            90,
                            100,
                            w,
                            h,
                          ),
                          _buildResponsiveZone(
                            "Bok Lewy",
                            -0.30,
                            -0.26,
                            100,
                            60,
                            w,
                            h,
                          ),
                          _buildResponsiveZone(
                            "Bok Prawy",
                            -0.30,
                            0.15,
                            100,
                            70,
                            w,
                            h,
                          ),
                          _buildResponsiveZone(
                            "Zgięcie Lewa",
                            -0.26,
                            -0.36,
                            70,
                            70,
                            w,
                            h,
                          ),
                          _buildResponsiveZone(
                            "Zgięcie Prawa",
                            -0.31,
                            0.33,
                            80,
                            80,
                            w,
                            h,
                          ),
                          _buildResponsiveZone(
                            "Dłoń Lewa",
                            0.10,
                            -0.42,
                            80,
                            80,
                            w,
                            h,
                          ),
                          _buildResponsiveZone(
                            "Dłoń Prawa",
                            0.10,
                            0.47,
                            80,
                            80,
                            w,
                            h,
                          ),
                          _buildResponsiveZone(
                            "Noga Lewa",
                            0.69,
                            -0.17,
                            140,
                            100,
                            w,
                            h,
                          ),
                          _buildResponsiveZone(
                            "Noga Prawa",
                            0.69,
                            0.21,
                            140,
                            100,
                            w,
                            h,
                          ),
                          _buildResponsiveZone(
                            "Nadgarstek Lewy",
                            -0.06,
                            -0.42,
                            70,
                            70,
                            w,
                            h,
                          ),
                          _buildResponsiveZone(
                            "Nadgarstek Prawy",
                            -0.06,
                            0.43,
                            70,
                            70,
                            w,
                            h,
                          ),
                          _buildResponsiveZone(
                            "Stopa Lewa",
                            0.82,
                            -0.24,
                            80,
                            80,
                            w,
                            h,
                          ),
                          _buildResponsiveZone(
                            "Stopa Prawa",
                            0.82,
                            0.29,
                            80,
                            80,
                            w,
                            h,
                          ),

                          if (widget.engine.state.isWarmingProvided)
                            Positioned.fill(
                              child: IgnorePointer(
                                child: Container(
                                  color: Colors.yellowAccent.withOpacity(0.15),
                                ),
                              ),
                            ),
                          if (widget.engine.state.airwayStatus !=
                              AirwayType.none)
                            _buildVisualOverlay(
                              -0.76,
                              -0.11,
                              Icons.masks,
                              Colors.blueAccent,
                              w,
                              h,
                            ),
                          if (widget.engine.state.isIvInserted)
                            _buildVisualOverlay(
                              -0.26,
                              -0.36,
                              Icons.colorize,
                              Colors.pinkAccent,
                              w,
                              h,
                            ),
                          if (widget.engine.state.isSpO2Attached)
                            _buildVisualOverlay(
                              0.10,
                              -0.42,
                              Icons.monitor_heart,
                              Colors.cyanAccent,
                              w,
                              h,
                            ),
                        ],
                      );
                    },
                  ),
                ),
              ),
            ),
          ),

          if (_hoveredZone.isNotEmpty && _equippedTool != null)
            Positioned(
              top: 90,
              left: 0,
              right: 0,
              child: IgnorePointer(
                child: Center(
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 24,
                      vertical: 12,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.green[900]?.withOpacity(0.95),
                      borderRadius: BorderRadius.circular(30),
                      border: Border.all(color: Colors.greenAccent, width: 2),
                      boxShadow: const [
                        BoxShadow(color: Colors.black54, blurRadius: 15),
                      ],
                    ),
                    child: Text(
                      _hoveredZone,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1.2,
                      ),
                    ),
                  ),
                ),
              ),
            ),

          if (_examResult.isNotEmpty)
            Positioned(
              top: 150,
              left: 0,
              right: 0,
              child: Center(
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 16,
                  ),
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
            ),

          Positioned(
            top: 20,
            right: 80,
            child: Column(
              children: [
                _buildFloatingToolButton(
                  "Oglądanie",
                  Icons.visibility,
                  Colors.purpleAccent,
                  overrideLabel: AppLoc.tr("Oglądanie", "Inspection"),
                ),
                const SizedBox(height: 10),
                _buildFloatingToolButton(
                  "Palec",
                  Icons.touch_app,
                  Colors.pinkAccent,
                  overrideLabel: AppLoc.tr("Palec", "Palpate"),
                ),
              ],
            ),
          ),

          if (_equippedTool == null) ...[
            if (widget.engine.state.isBagOpen) _buildBagOverlay(),
            if (widget.engine.state.isAirwayMenuOpen) _buildAirwayOverlay(),
          ] else ...[
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
                      AppLoc.tr("Odłóż", "Drop"),
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
                      Text(
                        AppLoc.tr("Przeciągasz...", "Dragging..."),
                        style: const TextStyle(color: Colors.grey),
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
                      "${AppLoc.tr('W RĘKU:\n', 'IN HAND:\n')}$_equippedTool",
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
      ),
    );
  }

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
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.arrow_back, color: Colors.white),
                        onPressed: () => setState(() => _showIvMenu = false),
                      ),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 8.0),
                        child: Text(
                          AppLoc.tr("WYBIERZ ROZMIAR: ", "SELECT SIZE: "),
                          style: const TextStyle(
                            color: Colors.orange,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      _buildToolEquipButton(
                        "Kaniula 14G (Pomarańczowa)",
                        Icons.colorize,
                        overrideLabel: AppLoc.tr(
                          "Kaniula 14G (Pomarańczowa)",
                          "14G IV (Orange)",
                        ),
                      ),
                      _buildToolEquipButton(
                        "Kaniula 18G (Zielona)",
                        Icons.colorize,
                        overrideLabel: AppLoc.tr(
                          "Kaniula 18G (Zielona)",
                          "18G IV (Green)",
                        ),
                      ),
                      _buildToolEquipButton(
                        "Kaniula 20G (Różowa)",
                        Icons.colorize,
                        overrideLabel: AppLoc.tr(
                          "Kaniula 20G (Różowa)",
                          "20G IV (Pink)",
                        ),
                      ),
                    ],
                  )
                : Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 8.0),
                        child: Text(
                          AppLoc.tr("TORBA: ", "BAG: "),
                          style: const TextStyle(
                            color: Colors.orange,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      _buildToolEquipButton(
                        "Latarka",
                        Icons.highlight,
                        overrideLabel: AppLoc.tr("Latarka", "Penlight"),
                      ),
                      _buildToolEquipButton(
                        "Ssak",
                        Icons.water_drop,
                        overrideLabel: AppLoc.tr("Ssak", "Suction"),
                      ),
                      _buildToolEquipButton(
                        "Stetoskop",
                        Icons.medical_services,
                        overrideLabel: AppLoc.tr("Stetoskop", "Stethoscope"),
                      ),
                      _buildToolEquipButton(
                        "Termometr",
                        Icons.thermostat,
                        overrideLabel: AppLoc.tr("Termometr", "Thermometer"),
                      ),
                      _buildToolEquipButton(
                        "Glukometr",
                        Icons.bloodtype,
                        overrideLabel: AppLoc.tr("Glukometr", "Glucometer"),
                      ),
                      _buildToolEquipButton(
                        "Pulsoksymetr",
                        Icons.monitor_heart,
                        overrideLabel: AppLoc.tr(
                          "Pulsoksymetr",
                          "Pulse Oximeter",
                        ),
                      ),
                      _buildToolEquipButton(
                        "USG: Hokus POCUS",
                        Icons.waves,
                        overrideLabel: AppLoc.tr(
                          "USG: Hokus POCUS",
                          "USG: POCUS",
                        ),
                      ),
                      _buildToolEquipButton(
                        "Folia NRC",
                        Icons.ac_unit,
                        overrideLabel: AppLoc.tr("Folia NRC", "Foil Blanket"),
                      ),
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
                            Text(
                              AppLoc.tr("Kaniula IV", "IV Cannula"),
                              style: const TextStyle(
                                color: Colors.grey,
                                fontSize: 9,
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
    );
  }

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
                    child: Text(
                      AppLoc.tr("Udrożnij drogi oddechowe", "Open Airway"),
                    ),
                  ),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.lightBlue[700],
                    ),
                    onPressed: widget.engine.preoxygenate,
                    child: Text(
                      AppLoc.tr("Preoksygenacja", "Preoxygenation"),
                      style: const TextStyle(color: Colors.white),
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
                    child: Text(
                      AppLoc.tr("Podłącz ETCO2", "Attach ETCO2"),
                      style: const TextStyle(
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
                      onChanged: (val) => setState(
                        () => widget.engine.state.oxygenFlow = val.toInt(),
                      ),
                      onChangeEnd: (val) =>
                          widget.engine.setOxygenFlow(val.toInt()),
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
                          Padding(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8.0,
                            ),
                            child: Text(
                              AppLoc.tr("WYBIERZ ROZMIAR: ", "SELECT SIZE: "),
                              style: const TextStyle(
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
                          Padding(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8.0,
                            ),
                            child: Text(
                              AppLoc.tr("SPRZĘT: ", "EQUIPMENT: "),
                              style: const TextStyle(
                                color: Colors.cyan,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          _buildToolEquipButton(
                            "Worek BVM",
                            Icons.masks,
                            overrideLabel: AppLoc.tr("Worek BVM", "BVM"),
                          ),
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
                                Text(
                                  AppLoc.tr("I-gel (SGA)", "I-gel (SGA)"),
                                  style: const TextStyle(
                                    color: Colors.grey,
                                    fontSize: 9,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          _buildToolEquipButton(
                            "Rurka ETI",
                            Icons.straighten,
                            overrideLabel: AppLoc.tr("Rurka ETI", "ET Tube"),
                          ),
                        ],
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildToolEquipButton(
    String name,
    IconData icon, {
    String? overrideLabel,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4.0),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          IconButton(
            icon: Icon(icon, color: Colors.white, size: 28),
            tooltip: AppLoc.tr(
              "Wyciągnij: $name",
              "Equip: ${overrideLabel ?? name}",
            ),
            onPressed: () {
              setState(() {
                _equippedTool = name;
                widget.engine.closeMenus();
              });
            },
          ),
          Text(
            overrideLabel ?? name,
            style: const TextStyle(color: Colors.grey, fontSize: 9),
          ),
        ],
      ),
    );
  }

  Widget _buildResponsiveZone(
    String baseTarget,
    double alignX,
    double alignY,
    double baseWidth,
    double baseHeight,
    double maxWidth,
    double maxHeight,
  ) {
    double percentX = (alignX + 1) / 2;
    double percentY = (alignY + 1) / 2;
    double scaleFactor = 0.6;
    double w = (baseWidth * scaleFactor) / 1536 * maxWidth;
    double h = (baseHeight * scaleFactor) / 1024 * maxHeight;
    double left = (maxWidth * percentX) - (w / 2);
    double top = (maxHeight * percentY) - (h / 2);

    return Positioned(
      left: left,
      top: top,
      width: w,
      height: h,
      child: _buildDropZone(baseTarget),
    );
  }

  Widget _buildDropZone(String baseTarget) {
    String displayLabel = _getDynamicLabel(baseTarget);

    return DragTarget<String>(
      onWillAcceptWithDetails: (details) {
        setState(() => _hoveredZone = displayLabel);
        return true;
      },
      onLeave: (data) => setState(() => _hoveredZone = ""),
      onAcceptWithDetails: (details) {
        setState(() => _hoveredZone = "");
        _showResult(details.data, baseTarget);
      },
      builder: (context, candidateData, rejectedData) {
        bool isHovered = candidateData.isNotEmpty;
        if (_equippedTool == null) return const SizedBox.expand();
        return Container(
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
        );
      },
    );
  }

  Widget _buildFloatingToolButton(
    String name,
    IconData icon,
    Color color, {
    String? overrideLabel,
  }) {
    bool isActive = _equippedTool == name;
    return FloatingActionButton(
      heroTag: name,
      backgroundColor: isActive ? color : Colors.grey[800],
      onPressed: () => setState(() {
        _equippedTool = isActive ? null : name;
        widget.engine.closeMenus();
      }),
      child: Icon(icon, color: Colors.white),
    );
  }

  Widget _buildVisualOverlay(
    double alignX,
    double alignY,
    IconData icon,
    Color color,
    double maxWidth,
    double maxHeight,
  ) {
    double percentX = (alignX + 1) / 2;
    double percentY = (alignY + 1) / 2;
    return Positioned(
      left: (maxWidth * percentX) - 20,
      top: (maxHeight * percentY) - 20,
      child: IgnorePointer(
        child: Container(
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(
            color: color.withOpacity(0.8),
            shape: BoxShape.circle,
            border: Border.all(color: Colors.white, width: 2),
          ),
          child: Icon(icon, color: Colors.white, size: 24),
        ),
      ),
    );
  }
}
