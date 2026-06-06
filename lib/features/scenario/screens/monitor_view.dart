import 'package:flutter/material.dart';
import 'dart:math' as math;
import '../logic/game_engine.dart';
import '../models/als_state.dart';
import '../../../app_localization.dart'; // IMPORT TŁUMACZA
import 'package:flutter/scheduler.dart';

class MonitorView extends StatefulWidget {
  final GameEngine engine;
  const MonitorView({super.key, required this.engine});

  @override
  State<MonitorView> createState() => _MonitorViewState();
}

class _MonitorViewState extends State<MonitorView>
    with SingleTickerProviderStateMixin, AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  late AnimationController _ticker;
  double _time = 0;
  double _selectedEnergy = 150;
  double _accumulatedRotation = 0;
  bool _isSynced = false;
  bool _isMeasuringNibp = false;
  String _nibpValue = "---/---";

  @override
  void initState() {
    super.initState();
    _ticker = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 1),
    )..repeat();
    _ticker.addListener(() => setState(() => _time += 0.035));
  }

  @override
  void dispose() {
    _ticker.dispose();
    super.dispose();
  }

  void _measureNibp() async {
    if (_isMeasuringNibp || !widget.engine.state.isMonitorOn) return;
    setState(() {
      _isMeasuringNibp = true;
      _nibpValue = AppLoc.tr("Pomiar...", "Measuring...");
    });
    await Future.delayed(const Duration(seconds: 5));
    if (!mounted) return;
    setState(() {
      _isMeasuringNibp = false;
      if (widget.engine.state.patient.hasPulse) {
        _nibpValue = "120/80";
      } else {
        _nibpValue = "---/---";
      }
    });
  }

  void _showEnergySelector() {
    if (!widget.engine.state.isMonitorOn) return;
    _accumulatedRotation = 0;

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              backgroundColor: const Color(0xFF222222),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
                side: const BorderSide(color: Colors.grey),
              ),
              title: Text(
                AppLoc.tr("WYBÓR ENERGII", "ENERGY SELECTION"),
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    GestureDetector(
                      onPanUpdate: (details) {
                        double radius = 40.0;
                        double x = details.localPosition.dx - radius;
                        double y = details.localPosition.dy - radius;
                        double dx = details.delta.dx;
                        double dy = details.delta.dy;
                        double rotationChange = x * dy - y * dx;

                        setDialogState(() {
                          _accumulatedRotation += rotationChange * 0.02;
                          if (_accumulatedRotation.abs() >= 1.0) {
                            int steps = _accumulatedRotation.truncate();
                            _selectedEnergy = (_selectedEnergy + steps * 10)
                                .clamp(10, 360);
                            _accumulatedRotation -= steps;
                          }
                        });
                        setState(() {});
                      },
                      child: Transform.rotate(
                        angle: _selectedEnergy * 0.02,
                        child: Container(
                          width: 80,
                          height: 80,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            gradient: const RadialGradient(
                              colors: [Color(0xFF555555), Color(0xFF111111)],
                            ),
                            border: Border.all(color: Colors.black, width: 4),
                          ),
                          child: Align(
                            alignment: Alignment.topCenter,
                            child: Container(
                              width: 5,
                              height: 16,
                              color: Colors.yellowAccent,
                              margin: const EdgeInsets.only(top: 4),
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 15),
                    Text(
                      "${_selectedEnergy.toInt()} J",
                      style: const TextStyle(
                        color: Colors.yellowAccent,
                        fontSize: 32,
                        fontWeight: FontWeight.bold,
                        fontFamily: 'monospace',
                      ),
                    ),
                    Text(
                      AppLoc.tr(
                        "Wykonaj okrężny ruch palcem wokół pokrętła",
                        "Make a circular motion around the dial",
                      ),
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        color: Colors.white54,
                        fontSize: 10,
                      ),
                    ),
                  ],
                ),
              ),
              actions: [
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green[800],
                  ),
                  onPressed: () {
                    widget.engine.setEnergy(_selectedEnergy.toInt());
                    Navigator.of(context).pop();
                  },
                  child: Text(
                    AppLoc.tr("ZATWIERDŹ", "CONFIRM"),
                    style: const TextStyle(color: Colors.white),
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _showGainSelector() {
    if (!widget.engine.state.isMonitorOn) return;
    final List<double> availableGains = [0.25, 0.5, 1.0, 2.0, 4.0];

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: const Color(0xFF222222),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
            side: const BorderSide(color: Colors.blueAccent),
          ),
          title: Text(
            AppLoc.tr("CECHA ZAPISU (GAIN)", "ECG GAIN"),
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          content: SizedBox(
            width: 200,
            height: 220,
            child: ListView.builder(
              shrinkWrap: true,
              itemCount: availableGains.length,
              itemBuilder: (context, index) {
                double gain = availableGains[index];
                bool isCurrent = widget.engine.state.ecgGain == gain;
                return ListTile(
                  title: Text(
                    "${AppLoc.tr('Cech x', 'Gain x')}$gain ${gain == 1.0 ? AppLoc.tr('(Norma)', '(Normal)') : ''}",
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: isCurrent ? Colors.blueAccent : Colors.white,
                      fontWeight: isCurrent
                          ? FontWeight.bold
                          : FontWeight.normal,
                    ),
                  ),
                  trailing: isCurrent
                      ? const Icon(Icons.check_circle, color: Colors.blueAccent)
                      : null,
                  onTap: () {
                    widget.engine.setEcgGain(gain);
                    Navigator.of(context).pop();
                  },
                );
              },
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);

    return AnimatedBuilder(
      animation: widget.engine,
      builder: (context, _) {
        final state = widget.engine.state;
        bool isMonitorOn = state.isMonitorOn;

        return Scaffold(
          backgroundColor: const Color(0xFF151515),
          body: SafeArea(
            child: Row(
              children: [
                // LEWA KOLUMNA
                Container(
                  width: 80,
                  color: const Color(0xFF1E1E1E),
                  child: SingleChildScrollView(
                    child: Column(
                      children: [
                        const SizedBox(height: 10),
                        _buildSideButton(
                          Icons.monitor_heart,
                          AppLoc.tr("12-ODPR\nEKG", "12-LEAD\nECG"),
                          Colors.green[900]!,
                          () {},
                        ),
                        _buildSideButton(
                          Icons.wifi,
                          AppLoc.tr("TRANSMITUJ", "TRANSMIT"),
                          Colors.grey[800]!,
                          () {},
                        ),
                        _buildSideButton(
                          Icons.save,
                          AppLoc.tr("ZAPIS\nZDARZEŃ", "EVENT\nLOG"),
                          Colors.grey[800]!,
                          () {},
                        ),
                        _buildSideButton(
                          Icons.print,
                          AppLoc.tr("DRUKUJ", "PRINT"),
                          Colors.grey[800]!,
                          () {},
                        ),
                        _buildSideButton(
                          Icons.settings,
                          AppLoc.tr("OPCJE", "OPTIONS"),
                          Colors.grey[800]!,
                          () {},
                        ),
                      ],
                    ),
                  ),
                ),

                // GŁÓWNY EKRAN MONITORA
                Expanded(
                  child: Container(
                    margin: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: isMonitorOn
                          ? const Color(0xFF050505)
                          : Colors.black,
                      border: Border.all(color: Colors.grey[850]!, width: 6),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: !isMonitorOn
                        ? Center(
                            child: Text(
                              AppLoc.tr("MONITOR WYŁĄCZONY", "MONITOR OFF"),
                              style: const TextStyle(
                                color: Colors.white12,
                                fontSize: 30,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          )
                        : Column(
                            children: [
                              Container(
                                height: 20,
                                color: Colors.black,
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 10,
                                ),
                                child: Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(
                                      AppLoc.tr(
                                        "TRYB DIAGNOSTYCZNY",
                                        "DIAGNOSTIC MODE",
                                      ),
                                      style: const TextStyle(
                                        color: Colors.white38,
                                        fontSize: 10,
                                      ),
                                    ),
                                    Text(
                                      "${AppLoc.tr('CZAS AKCJI:', 'ELAPSED TIME:')} ${(state.totalElapsedGameTime ~/ 60).toString().padLeft(2, '0')}:${(state.totalElapsedGameTime % 60).toString().padLeft(2, '0')}",
                                      style: const TextStyle(
                                        color: Colors.white54,
                                        fontSize: 12,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              Expanded(
                                child: Row(
                                  children: [
                                    Container(
                                      width: 100,
                                      decoration: const BoxDecoration(
                                        border: Border(
                                          right: BorderSide(
                                            color: Colors.white24,
                                            width: 1,
                                          ),
                                        ),
                                      ),
                                      child: Column(
                                        mainAxisAlignment:
                                            MainAxisAlignment.spaceEvenly,
                                        children: [
                                          _buildNumericValue(
                                            "HR",
                                            _getHrValue(state),
                                            Colors.greenAccent,
                                          ),
                                          _buildNumericValue(
                                            "SpO2",
                                            _getSpo2Value(state),
                                            Colors.cyanAccent,
                                          ),
                                          _buildNumericValue(
                                            "EtCO2",
                                            state.isCapnographyAttached
                                                ? "${state.patient.etCo2}"
                                                : "---",
                                            Colors.yellowAccent,
                                          ),
                                          _buildNumericValue(
                                            "NIBP",
                                            _nibpValue,
                                            Colors.white,
                                            isSmall: true,
                                          ),
                                          _buildNumericValue(
                                            "TEMP",
                                            state.isTempMeasured
                                                ? state.patient.temperature
                                                      .toStringAsFixed(1)
                                                : "---",
                                            Colors.grey,
                                            isSmall: true,
                                          ),
                                        ],
                                      ),
                                    ),
                                    Expanded(
                                      child: Column(
                                        children: [
                                          Expanded(
                                            flex: 3,
                                            child: Stack(
                                              children: [
                                                Positioned.fill(
                                                  child: CustomPaint(
                                                    painter: GridPainter(),
                                                  ),
                                                ),
                                                Positioned.fill(
                                                  child: RepaintBoundary(
                                                    child: SweepWaveDisplay(
                                                      waveType: WaveType.ecg,
                                                      rhythm:
                                                          state.monitorRhythm,
                                                      isCprActive:
                                                          state.isCprActive,
                                                      ecgGain: state.ecgGain,
                                                      color: Colors.greenAccent,
                                                    ),
                                                  ),
                                                ),
                                                Positioned(
                                                  top: 5,
                                                  left: 10,
                                                  child: Text(
                                                    state.isCprActive
                                                        ? AppLoc.tr(
                                                            "RKO ARTEFAKTY",
                                                            "CPR ARTIFACTS",
                                                          )
                                                        : "II x${state.ecgGain.toStringAsFixed(2)}",
                                                    style: TextStyle(
                                                      color: state.isCprActive
                                                          ? Colors.orange
                                                          : Colors.greenAccent,
                                                      fontSize: 12,
                                                      fontWeight:
                                                          FontWeight.bold,
                                                    ),
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                          Expanded(
                                            flex: 2,
                                            child: Stack(
                                              children: [
                                                Positioned.fill(
                                                  child: RepaintBoundary(
                                                    child: SweepWaveDisplay(
                                                      waveType: WaveType.spo2,
                                                      hasPulse: state
                                                          .patient
                                                          .hasPulse,
                                                      isAttached:
                                                          state.isSpO2Attached,
                                                      ecgGain: 1.0,
                                                      color: Colors.cyanAccent,
                                                    ),
                                                  ),
                                                ),
                                                const Positioned(
                                                  top: 5,
                                                  left: 10,
                                                  child: Text(
                                                    "SpO2",
                                                    style: TextStyle(
                                                      color: Colors.cyanAccent,
                                                      fontSize: 12,
                                                    ),
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                          Expanded(
                                            flex: 2,
                                            child: Stack(
                                              children: [
                                                Positioned.fill(
                                                  child: RepaintBoundary(
                                                    child: SweepWaveDisplay(
                                                      waveType: WaveType.etco2,
                                                      isAttached: state
                                                          .isCapnographyAttached,
                                                      isVentilated:
                                                          state.airwayStatus !=
                                                          AirwayType.none,
                                                      isCprActive:
                                                          state.isCprActive,
                                                      hasPulse: state
                                                          .patient
                                                          .hasPulse,
                                                      ecgGain: 1.0,
                                                      color:
                                                          Colors.yellowAccent,
                                                    ),
                                                  ),
                                                ),
                                                const Positioned(
                                                  top: 5,
                                                  left: 10,
                                                  child: Text(
                                                    "EtCO2",
                                                    style: TextStyle(
                                                      color:
                                                          Colors.yellowAccent,
                                                      fontSize: 12,
                                                    ),
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                  ),
                ),

                // PRAWA KOLUMNA
                Container(
                  width: 110,
                  color: const Color(0xFF1E1E1E),
                  child: SingleChildScrollView(
                    child: Column(
                      children: [
                        const SizedBox(height: 10),
                        _buildSideButton(
                          Icons.power_settings_new,
                          AppLoc.tr("WŁĄCZ", "POWER"),
                          isMonitorOn ? Colors.green[800]! : Colors.grey[800]!,
                          () => widget.engine.toggleMonitor(),
                        ),
                        const Divider(color: Colors.black, thickness: 2),
                        _buildSideButton(
                          state.isCprActive
                              ? Icons.stop_circle
                              : Icons.favorite,
                          state.isCprActive
                              ? AppLoc.tr("STOP\nRKO", "STOP\nCPR")
                              : AppLoc.tr("START\nRKO", "START\nCPR"),
                          state.isCprActive
                              ? Colors.orange[900]!
                              : Colors.green[700]!,
                          () {
                            if (state.isCprActive)
                              widget.engine.stopCprAndAssess();
                            else
                              widget.engine.startCpr();
                          },
                        ),
                        _buildSideButton(
                          Icons.dialpad,
                          "${AppLoc.tr('1 ENERGIA\n', '1 ENERGY\n')}${_selectedEnergy.toInt()}J",
                          Colors.grey[800]!,
                          _showEnergySelector,
                        ),
                        _buildSideButton(
                          Icons.battery_charging_full,
                          AppLoc.tr("2 ŁADUJ", "2 CHARGE"),
                          state.isDefibCharging
                              ? Colors.yellow[900]!
                              : Colors.yellow[700]!,
                          () {
                            if (isMonitorOn)
                              widget.engine.chargeDefibrillator();
                          },
                          textColor: Colors.black,
                        ),
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 8.0),
                          child: InkWell(
                            onTap: () {
                              if (isMonitorOn && state.isDefibCharged)
                                widget.engine.deliverShock();
                            },
                            child: Container(
                              width: 70,
                              height: 70,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: state.isDefibCharged
                                    ? Colors.redAccent
                                    : Colors.red[900],
                                border: Border.all(
                                  color: Colors.black,
                                  width: 3,
                                ),
                                boxShadow: state.isDefibCharged
                                    ? [
                                        const BoxShadow(
                                          color: Colors.red,
                                          blurRadius: 15,
                                        ),
                                      ]
                                    : [],
                              ),
                              child: const Icon(
                                Icons.bolt,
                                color: Colors.white,
                                size: 40,
                              ),
                            ),
                          ),
                        ),
                        Text(
                          AppLoc.tr("3 DEFIBRYLACJA", "3 SHOCK"),
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 9,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const Divider(color: Colors.black, thickness: 2),
                        _buildSideButton(
                          Icons.waves,
                          "${AppLoc.tr('CECHA\n', 'GAIN\n')}x${state.ecgGain}",
                          state.isAsystoleConfirmed
                              ? Colors.blue[800]!
                              : Colors.blueGrey[800]!,
                          _showGainSelector,
                        ),
                        _buildSideButton(
                          Icons.sync,
                          AppLoc.tr("SYNC", "SYNC"),
                          Colors.grey[800]!,
                          () {},
                        ),
                        _buildSideButton(
                          Icons.compress,
                          AppLoc.tr("NIBP\nSTART", "NIBP\nSTART"),
                          Colors.blueGrey[700]!,
                          _measureNibp,
                        ),
                        _buildSideButton(
                          Icons.bolt_outlined,
                          AppLoc.tr("STYMULATOR", "PACER"),
                          Colors.grey[800]!,
                          () {},
                        ),
                        const SizedBox(height: 10),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  String _getHrValue(AlsScenarioState state) {
    if (state.isCprActive) return "115";
    if (state.monitorRhythm == PatientRhythm.pvt) return "214";
    if (state.monitorRhythm == PatientRhythm.vf) return "---";
    if (state.monitorRhythm == PatientRhythm.asystole) return "0";
    return "72";
  }

  String _getSpo2Value(AlsScenarioState state) {
    if (!state.isSpO2Attached) return "---";
    return state.patient.hasPulse ? "${state.patient.spO2 ?? 98}" : "---";
  }

  Widget _buildNumericValue(
    String label,
    String val,
    Color color, {
    bool isSmall = false,
  }) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          label,
          style: TextStyle(
            color: color,
            fontSize: 10,
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          val,
          style: TextStyle(
            color: color,
            fontSize: isSmall ? 20 : 32,
            fontWeight: FontWeight.bold,
            fontFamily: 'monospace',
          ),
        ),
      ],
    );
  }

  Widget _buildSideButton(
    IconData icon,
    String label,
    Color bgColor,
    VoidCallback onTap, {
    Color textColor = Colors.white,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: bgColor,
          foregroundColor: textColor,
          padding: const EdgeInsets.symmetric(vertical: 8),
          minimumSize: const Size(double.infinity, 50),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(4),
            side: const BorderSide(color: Colors.black54),
          ),
          elevation: 4,
        ),
        onPressed: onTap,
        child: Column(
          children: [
            Icon(icon, size: 20),
            const SizedBox(height: 2),
            Text(
              label,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 9, fontWeight: FontWeight.bold),
            ),
          ],
        ),
      ),
    );
  }
}

enum WaveType { ecg, spo2, etco2 }

class SweepWaveDisplay extends StatefulWidget {
  final WaveType waveType;
  final PatientRhythm? rhythm;
  final bool? isCprActive;
  final bool? isAttached;
  final bool? hasPulse;
  final bool? isVentilated;
  final double ecgGain;
  final Color color;

  const SweepWaveDisplay({
    super.key,
    required this.waveType,
    this.rhythm,
    this.isCprActive,
    this.isAttached,
    this.hasPulse,
    this.isVentilated,
    required this.ecgGain,
    required this.color,
  });

  @override
  State<SweepWaveDisplay> createState() => _SweepWaveDisplayState();
}

class _SweepWaveDisplayState extends State<SweepWaveDisplay>
    with SingleTickerProviderStateMixin {
  // Zastępujemy AnimationController surowym Tickerem
  late Ticker _ticker;

  static const int maxPoints = 300;
  final List<double> _dataPoints = List.filled(maxPoints, 0.0);
  int _currentIndex = 0;

  final WaveformEngine _ecgEngine = WaveformEngine();

  double _internalTime = 0.0;
  final math.Random _random = math.Random();

  // --- ZMIENNE DO STABILIZACJI KLATKAŻU (GAME LOOP ACCUMULATOR) ---
  Duration _lastElapsed = Duration.zero;
  double _timeAccumulator = 0.0;
  // 0.02 sekundy oznacza 50 punktów generowanych na sekundę.
  // Przy 300 punktach (maxPoints) przeskok przez cały ekran zajmie równiutkie 6 sekund!
  static const double _timePerPoint = 0.02;

  @override
  void initState() {
    super.initState();
    // Odpalamy surowy Ticker do precyzyjnego pomiaru czasu pomiędzy klatkami
    _ticker = createTicker(_onTick)..start();
  }

  @override
  void dispose() {
    _ticker.dispose();
    super.dispose();
  }

  // Ta metoda odpala się przy każdej klatce wyrenderowanej przez system
  void _onTick(Duration elapsed) {
    if (!mounted) return;

    // 1. Obliczamy, ile realnego czasu (w sekundach) minęło od poprzedniej klatki
    double deltaSeconds = (elapsed - _lastElapsed).inMicroseconds / 1000000.0;
    _lastElapsed = elapsed;

    // Zabezpieczenie przed "spiralą śmierci" (np. gdy aplikacja była zminimalizowana przez 5 minut)
    if (deltaSeconds > 0.1) deltaSeconds = 0.1;

    // 2. Dodajemy upływający czas do naszego zbiornika (akumulatora)
    _timeAccumulator += deltaSeconds;

    bool pointsGenerated = false;

    // 3. Generujemy punkty tak długo, aż opróżnimy zbiornik.
    // Niezależnie czy masz 60Hz, 120Hz czy 30Hz - sygnał zawsze wygeneruje 50 pkt/sek!
    while (_timeAccumulator >= _timePerPoint) {
      _generateNextPoint(_timePerPoint); // Przekazujemy stałe dt = 0.02s
      _timeAccumulator -= _timePerPoint;
      pointsGenerated = true;
    }

    // 4. Odświeżamy widok TYLKO jeśli sygnał posunął się do przodu
    if (pointsGenerated) {
      setState(() {});
    }
  }

  // Główna logika rysująca sygnał (teraz przyjmuje z góry ustalony dt)
  void _generateNextPoint(double dt) {
    double y = 0;
    _internalTime += dt;

    if (widget.waveType == WaveType.ecg) {
      // Docelowo: double targetHr = patient.heartRate;
      double targetHr = 70.0;

      SignalOutput output = _ecgEngine.getNextValue(
        dt,
        widget.rhythm ?? PatientRhythm.asystole,
        widget.isCprActive ?? false,
        targetHr,
      );

      y = output.value * widget.ecgGain;

      if (output.isRPeak) {
        // Tu w przyszłości dodasz np.: AudioPlayer().play('beep.mp3');
      }
    } else if (widget.waveType == WaveType.spo2) {
      if (widget.isAttached == true) {
        if (widget.hasPulse == true) {
          double phase = (_internalTime * 2.5) % 6.0;
          if (phase < 2.0) {
            y = -20 * math.sin(phase * math.pi / 2.0);
          } else if (phase > 2.5 && phase < 4.0) {
            y = -8 * math.sin((phase - 2.5) * math.pi / 1.5);
          }
        } else {
          y = (_random.nextDouble() - 0.5) * 2;
        }
      }
    } else if (widget.waveType == WaveType.etco2) {
      if (widget.isAttached == true) {
        if (widget.hasPulse == true && widget.isVentilated == true) {
          double phase = (_internalTime * 1.5) % 6;
          if (phase < 2.5) y = -25;
        } else if (widget.isCprActive == true) {
          double phase = (_internalTime * 3.0) % 6;
          if (phase < 2.5) y = -15;
        } else {
          y = 0.0;
        }
      }
    }

    // Dodanie punktu do tablicy cyklicznej
    _dataPoints[_currentIndex] = y;
    _currentIndex = (_currentIndex + 1) % maxPoints;
  }

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: SweepPainter(
        dataPoints: _dataPoints,
        currentIndex: _currentIndex,
        color: widget.color,
      ),
    );
  }
}

class SweepPainter extends CustomPainter {
  final List<double> dataPoints;
  final int currentIndex;
  final Color color;
  static const int eraserGap = 15;

  SweepPainter({
    required this.dataPoints,
    required this.currentIndex,
    required this.color,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 2.0
      ..style = PaintingStyle.stroke
      ..strokeJoin = StrokeJoin.round;
    final path = Path();
    final double widthPerPoint = size.width / dataPoints.length;
    final double midY = size.height / 1.5;
    bool isFirstPoint = true;

    for (int i = 0; i < dataPoints.length; i++) {
      bool inEraser = false;
      if (currentIndex + eraserGap < dataPoints.length) {
        if (i >= currentIndex && i < currentIndex + eraserGap) inEraser = true;
      } else {
        if (i >= currentIndex ||
            i < (currentIndex + eraserGap) % dataPoints.length)
          inEraser = true;
      }
      if (inEraser) {
        isFirstPoint = true;
        continue;
      }

      double x = i * widthPerPoint;
      double y = midY + dataPoints[i];

      if (isFirstPoint) {
        path.moveTo(x, y);
        isFirstPoint = false;
      } else {
        path.lineTo(x, y);
      }
    }
    canvas.drawPath(path, paint);

    final headPaint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;
    canvas.drawCircle(
      Offset(currentIndex * widthPerPoint, midY + dataPoints[currentIndex]),
      2.5,
      headPaint,
    );
  }

  @override
  bool shouldRepaint(SweepPainter old) => old.currentIndex != currentIndex;
}

class GridPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.green[900]!.withOpacity(0.3)
      ..strokeWidth = 0.5;
    for (double i = 0; i < size.width; i += 15)
      canvas.drawLine(Offset(i, 0), Offset(i, size.height), paint);
    for (double i = 0; i < size.height; i += 15)
      canvas.drawLine(Offset(0, i), Offset(size.width, i), paint);
  }

  @override
  bool shouldRepaint(GridPainter old) => false;
}
// ============================================================================
// NOWA ARCHITEKTURA DSP (DIGITAL SIGNAL PROCESSING) DLA KRYZYWEJ EKG
// ============================================================================

class SignalOutput {
  final double value;
  final bool isRPeak;
  SignalOutput(this.value, this.isRPeak);
}

abstract class RhythmGenerator {
  SignalOutput getNextValue(double dt, double hr);
}

class AsystoleGenerator implements RhythmGenerator {
  double _time = 0;
  final math.Random _random = math.Random();

  @override
  SignalOutput getNextValue(double dt, double hr) {
    _time += dt;
    // Pływająca linia bazowa (oddychanie, drobne ruchy) + mikroszum
    double y = math.sin(_time * 2) * 1.5 + (_random.nextDouble() - 0.5) * 2.0;
    return SignalOutput(y, false);
  }
}

class VfGenerator implements RhythmGenerator {
  double _time = 0;

  @override
  SignalOutput getNextValue(double dt, double hr) {
    _time += dt;

    // ZWIĘKSZONA CZĘSTOTLIWOŚĆ (Prawdziwe Coarse VF)
    // Fale są teraz znacznie gęstsze i szybsze, imitując elektryczny chaos
    // o częstotliwości uderzeń rzędu 250-350/min.
    double wave1 = math.sin(_time * 15.3) * 16.0;
    double wave2 = math.sin(_time * 24.7 + 1.2) * 10.0;
    double wave3 = math.sin(_time * 11.8 + 0.5) * 18.0;
    double wave4 = math.cos(_time * 33.4) * 6.0;

    double y = wave1 + wave2 + wave3 + wave4;

    return SignalOutput(y, false); // VF nie ma wykrywalnego R-Peak
  }
}

class PvtGenerator implements RhythmGenerator {
  double _time = 0;

  @override
  SignalOutput getNextValue(double dt, double hr) {
    _time += dt;

    // MONOMORPHIC VENTRICULAR TACHYCARDIA (Szerokie kompleksy)
    // Częstość dla VT to zwykle ~180-200/min. Ustawiamy bazowo na ok. 3.2 Hz.
    double freq = 3.2;
    double phase = (_time * freq * math.pi * 2);

    // Zamiast brzydkiego "odbijania" (abs), używamy klasycznej sinusoidy
    // z domieszką asymetrycznej harmonicznej, co poszerza wierzchołek
    // i nadaje fali typowy kształt szerokiego zespołu QRS (V-shape).
    double y = math.sin(phase) * 35.0 + math.sin(phase * 2.0 - 1.5) * 12.0;

    // Wykrywanie R-Peak (dźwięk pulsometru na szczycie fali VT)
    bool isRPeak = false;
    double currentPhaseCycle = (_time * freq) % 1.0;
    // Okienko wyzwolenia dźwięku
    if (currentPhaseCycle > 0.22 && currentPhaseCycle < 0.28) {
      isRPeak = true;
    }

    return SignalOutput(y, isRPeak);
  }
}

class OrganizedRhythmGenerator implements RhythmGenerator {
  double _phaseTime = 0.0;

  @override
  SignalOutput getNextValue(double dt, double hr) {
    // Obliczamy całkowity czas jednego cyklu serca w sekundach
    double cycleDuration = 60.0 / hr;
    _phaseTime += dt;

    // Zapętlenie cyklu
    if (_phaseTime >= cycleDuration) {
      _phaseTime -= cycleDuration;
    }

    double y = 0.0;
    bool isRPeak = false;

    // TWARDE DEFINICJE CZASOWE (Szerokość załamków NIE zależy od HR!)
    // P Wave: 0.1s szerokości, QRS: 0.1s, T Wave: 0.2s

    if (_phaseTime > 0.1 && _phaseTime < 0.2) {
      // Załamek P
      double pPhase = (_phaseTime - 0.1) / 0.1; // Normalizacja 0.0 -> 1.0
      y = -6 * math.sin(pPhase * math.pi);
    } else if (_phaseTime >= 0.3 && _phaseTime < 0.4) {
      // Zespół QRS (Szerokość 100ms)
      double qrsPhase = (_phaseTime - 0.3) / 0.1;
      if (qrsPhase < 0.2) {
        y = 5; // Q
      } else if (qrsPhase < 0.5) {
        y = -45; // R
        if (qrsPhase > 0.3 && qrsPhase < 0.4) isRPeak = true; // TRIGGER AUDIO!
      } else {
        y = 15; // S
      }
    } else if (_phaseTime > 0.5 && _phaseTime < 0.7) {
      // Załamek T
      double tPhase = (_phaseTime - 0.5) / 0.2;
      y = -10 * math.sin(tPhase * math.pi);
    }
    // Reszta cyklu (_phaseTime > 0.7 aż do cycleDuration) to linia izoelektryczna (odstęp TP)

    return SignalOutput(y, isRPeak);
  }
}

class WaveformEngine {
  RhythmGenerator _currentGenerator = AsystoleGenerator();
  PatientRhythm _lastRhythm = PatientRhythm.unknown;
  double _transitionBlend = 1.0;
  double _lastY = 0.0;

  SignalOutput getNextValue(
    double dt,
    PatientRhythm rhythm,
    bool isCpr,
    double targetHr,
  ) {
    // 1. OBSŁUGA ZMIANY RYTMU (Płynne przejście - Interpolacja)
    if (rhythm != _lastRhythm) {
      _transitionBlend = 0.0; // Zaczynamy płynne przejście
      _lastRhythm = rhythm;

      switch (rhythm) {
        case PatientRhythm.vf:
          _currentGenerator = VfGenerator();
          break;
        case PatientRhythm.pvt:
          _currentGenerator = PvtGenerator();
          break;
        case PatientRhythm.pea:
        case PatientRhythm.unknown: // Fallback na zorganizowany
          _currentGenerator = OrganizedRhythmGenerator();
          break;
        case PatientRhythm.asystole:
        default:
          _currentGenerator = AsystoleGenerator();
          break;
      }
    }

    // Pobieramy wartość z aktywnego generatora
    SignalOutput out = _currentGenerator.getNextValue(dt, targetHr);
    double y = out.value;

    // Aplikujemy interpolację dla płynnego połączenia przy zmianie rytmu (Crossfade 0.5s)
    if (_transitionBlend < 1.0) {
      _transitionBlend += dt * 2.0; // Przejście trwa ok. 0.5 sekundy
      if (_transitionBlend > 1.0) _transitionBlend = 1.0;
      // Interpolacja między ostatnio zapamiętanym punktem, a nowym rytmem
      y = (_lastY * (1.0 - _transitionBlend)) + (y * _transitionBlend);
    }

    // 2. DOMIESZKA ARTEFAKTÓW (RKO)
    if (isCpr) {
      // Uciśnięcia klatki piersiowej (Częstość ok. 110/min -> ~1.8 Hz)
      // Dodajemy artefakty DO aktualnego rytmu, a nie zamiast niego!
      double cprArtifact =
          math.sin(DateTime.now().millisecondsSinceEpoch / 1000.0 * 11.3) * 35;
      y += cprArtifact;
      out = SignalOutput(
        y,
        false,
      ); // W trakcie RKO pulsometr nie wyłapie prawdziwego R-Peak
    }

    _lastY = y;
    return out;
  }
}
