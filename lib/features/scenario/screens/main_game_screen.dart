import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:async';

import '../logic/game_engine.dart';
import '../models/scenario_model.dart';
import '../models/als_state.dart';
import 'patient_view.dart';
import 'monitor_view.dart';
import 'feedback_screen.dart';
import '../widgets/inventory/ampularium.dart';
import '../widgets/inventory/h4t_dialog.dart';
import 'scenario_intro_screen.dart';
import '../../../app_localization.dart'; // IMPORT TŁUMACZA

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
    engine.addListener(_onEngineUpdate);
  }

  void _onEngineUpdate() {
    if (!mounted) return;
    if (engine.state.currentPhase == ResuscitationPhase.postResuscitation) {
      engine.removeListener(_onEngineUpdate);
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (context) =>
              FeedbackScreen(state: engine.state, scenario: widget.scenario),
        ),
      );
      return;
    }

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
                            "${AppLoc.tr('RKO', 'CPR')}: ${engine.state.cprSecondsRemaining} s",
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

            if (engine.state.preparedDrugs.isNotEmpty)
              Positioned(
                bottom: 85,
                left: 0,
                right: 0,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      AppLoc.tr(
                        "TACKA - GOTOWE LEKI (Kliknij, aby podać):",
                        "TRAY - PREPARED DRUGS (Click to administer):",
                      ),
                      style: const TextStyle(
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
                          label: AppLoc.tr("Ampularium", "Meds"),
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
                          label: AppLoc.tr("Oddech", "Airway"),
                          onPressed: () => engine.toggleAirwayMenu(),
                        ),
                        _buildOverlayButton(
                          icon: Icons.backpack,
                          color: Colors.orange[900]!,
                          label: AppLoc.tr("Torba/Diag.", "Bag/Diag."),
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
                            label: AppLoc.tr(
                              "WIDOK\nPACJENTA",
                              "PATIENT\nVIEW",
                            ),
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

            Builder(
              builder: (context) {
                bool isRoutineExamLog =
                    _hudLog.startsWith("BADANIE:") ||
                    _hudLog.startsWith("EXAMINATION:") ||
                    _hudLog.startsWith("USG:") ||
                    _hudLog.startsWith("AKCJA: Założono");
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
                          color: _hudLog.contains(AppLoc.tr("BŁĄD", "ERROR"))
                              ? Colors.red[900]?.withOpacity(0.95)
                              : (_hudLog.contains(
                                      AppLoc.tr("SUKCES", "SUCCESS"),
                                    )
                                    ? Colors.green[900]?.withOpacity(0.95)
                                    : Colors.black87),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: _hudLog.contains(AppLoc.tr("BŁĄD", "ERROR"))
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
                            title: Row(
                              children: [
                                const Icon(
                                  Icons.warning_amber_rounded,
                                  color: Colors.redAccent,
                                ),
                                const SizedBox(width: 10),
                                Text(
                                  AppLoc.tr(
                                    "Przerwać akcję?",
                                    "Abort mission?",
                                  ),
                                  style: const TextStyle(
                                    color: Colors.redAccent,
                                  ),
                                ),
                              ],
                            ),
                            content: Text(
                              AppLoc.tr(
                                "Czy na pewno chcesz porzucić pacjenta i wrócić do dyspozytorni? Akcja zostanie przerwana.",
                                "Are you sure you want to abandon the patient and return to dispatch? The mission will be aborted.",
                              ),
                              style: const TextStyle(color: Colors.white70),
                            ),
                            actions: [
                              TextButton(
                                onPressed: () => Navigator.of(context).pop(),
                                child: Text(
                                  AppLoc.tr("Zostań", "Stay"),
                                  style: const TextStyle(color: Colors.grey),
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
                                child: Text(
                                  AppLoc.tr("Zakończ Akcję", "End Mission"),
                                  style: const TextStyle(color: Colors.white),
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
