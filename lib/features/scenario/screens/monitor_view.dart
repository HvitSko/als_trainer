import 'package:flutter/material.dart';
import 'dart:math' as math;
import '../logic/game_engine.dart';
import '../models/als_state.dart';

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
      _nibpValue = "Pomiar...";
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
              title: const Text(
                "WYBÓR ENERGII",
                textAlign: TextAlign.center,
                style: TextStyle(
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
                          _accumulatedRotation += rotationChange * 0.08;
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
                    const Text(
                      "Wykonaj okrężny ruch palcem wokół pokrętła",
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Colors.white54, fontSize: 10),
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
                  child: const Text(
                    "ZATWIERDŹ",
                    style: TextStyle(color: Colors.white),
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
          title: const Text(
            "CECHA ZAPISU (GAIN)",
            textAlign: TextAlign.center,
            style: TextStyle(
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
                    "Cech x$gain ${gain == 1.0 ? '(Norma)' : ''}",
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
                          "12-ODPR\nEKG",
                          Colors.green[900]!,
                          () {},
                        ),
                        _buildSideButton(
                          Icons.wifi,
                          "TRANSMITUJ",
                          Colors.grey[800]!,
                          () {},
                        ),
                        _buildSideButton(
                          Icons.save,
                          "ZAPIS\nZDARZEŃ",
                          Colors.grey[800]!,
                          () {},
                        ),
                        _buildSideButton(
                          Icons.print,
                          "DRUKUJ",
                          Colors.grey[800]!,
                          () {},
                        ),
                        _buildSideButton(
                          Icons.settings,
                          "OPCJE",
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
                        ? const Center(
                            child: Text(
                              "MONITOR WYŁĄCZONY",
                              style: TextStyle(
                                color: Colors.white12,
                                fontSize: 30,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          )
                        : Column(
                            children: [
                              // DYSKRETNY PASEK CZASU
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
                                    const Text(
                                      "TRYB DIAGNOSTYCZNY",
                                      style: TextStyle(
                                        color: Colors.white38,
                                        fontSize: 10,
                                      ),
                                    ),
                                    Text(
                                      "CZAS AKCJI: ${(state.totalElapsedGameTime ~/ 60).toString().padLeft(2, '0')}:${(state.totalElapsedGameTime % 60).toString().padLeft(2, '0')}",
                                      style: const TextStyle(
                                        color: Colors.white54,
                                        fontSize: 12,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              // GŁÓWNY WIDOK MONITORA
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
                                                        ? "RKO ARTEFAKTY"
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
                          "WŁĄCZ",
                          isMonitorOn ? Colors.green[800]! : Colors.grey[800]!,
                          () => widget.engine.toggleMonitor(),
                        ),
                        const Divider(color: Colors.black, thickness: 2),
                        _buildSideButton(
                          state.isCprActive
                              ? Icons.stop_circle
                              : Icons.favorite,
                          state.isCprActive ? "STOP\nRKO" : "START\nRKO",
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
                          "1 ENERGIA\n${_selectedEnergy.toInt()}J",
                          Colors.grey[800]!,
                          _showEnergySelector,
                        ),
                        _buildSideButton(
                          Icons.battery_charging_full,
                          "2 ŁADUJ",
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
                        const Text(
                          "3 DEFIBRYLACJA",
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 9,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const Divider(color: Colors.black, thickness: 2),
                        _buildSideButton(
                          Icons.waves,
                          "CECHA\nx${state.ecgGain}",
                          state.isAsystoleConfirmed
                              ? Colors.blue[800]!
                              : Colors.blueGrey[800]!,
                          _showGainSelector,
                        ),
                        _buildSideButton(
                          Icons.sync,
                          "SYNC",
                          Colors.grey[800]!,
                          () {},
                        ),
                        _buildSideButton(
                          Icons.compress,
                          "NIBP\nSTART",
                          Colors.blueGrey[700]!,
                          _measureNibp,
                        ),
                        _buildSideButton(
                          Icons.bolt_outlined,
                          "STYMULATOR",
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
  late AnimationController _controller;
  static const int maxPoints = 300;
  final List<double> _dataPoints = List.filled(maxPoints, 0.0);
  int _currentIndex = 0;
  double _internalTime = 0.0;
  final math.Random _random = math.Random();

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 1),
    )..repeat();
    _controller.addListener(_generateNextPoint);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _generateNextPoint() {
    if (!mounted) return;
    double y = 0;
    _internalTime += 0.035;

    if (widget.waveType == WaveType.ecg) {
      if (widget.isCprActive == true) {
        y =
            math.sin(_internalTime * 5.7) * 35 +
            math.sin(_internalTime * 50) * 4;
      } else if (widget.rhythm == PatientRhythm.unknown) {
        y = 0.0;
      } else if (widget.rhythm == PatientRhythm.vf) {
        y =
            (math.sin(_internalTime * 4.5) * 12 +
                math.cos(_internalTime * 5.5) * 16 +
                math.sin(_internalTime * 7.2) * 8 +
                (_random.nextDouble() - 0.5) * 8) *
            widget.ecgGain;
      } else if (widget.rhythm == PatientRhythm.pvt) {
        y = ((math.sin(_internalTime * 11).abs() * -45) + 20) * widget.ecgGain;
      } else if (widget.rhythm == PatientRhythm.asystole) {
        y =
            (math.sin(_internalTime * 2) * 1.5 +
                (_random.nextDouble() - 0.5) * 2) *
            widget.ecgGain;
      } else {
        double phase = (_internalTime * 2.5) % 6.0;
        double baseLine = 0;
        if (phase > 0.5 && phase < 0.9)
          baseLine = -6 * math.sin((phase - 0.5) * math.pi / 0.4);
        else if (phase > 1.2 && phase < 1.5) {
          double qrsPhase = phase - 1.2;
          if (qrsPhase < 0.1)
            baseLine = 5;
          else if (qrsPhase < 0.2)
            baseLine = -45;
          else
            baseLine = 15;
        } else if (phase > 1.8 && phase < 2.6)
          baseLine = -10 * math.sin((phase - 1.8) * math.pi / 0.8);
        y = baseLine * widget.ecgGain;
      }
    } else if (widget.waveType == WaveType.spo2) {
      if (widget.isAttached == true) {
        if (widget.hasPulse == true) {
          double phase = (_internalTime * 2.5) % 6.0;
          if (phase < 2.0)
            y = -20 * math.sin(phase * math.pi / 2.0);
          else if (phase > 2.5 && phase < 4.0)
            y = -8 * math.sin((phase - 2.5) * math.pi / 1.5);
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

    setState(() {
      _dataPoints[_currentIndex] = y;
      _currentIndex = (_currentIndex + 1) % maxPoints;
    });
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
