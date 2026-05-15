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

class _MonitorViewState extends State<MonitorView> {
  double _selectedEnergy = 150; // Zgodnie z wytycznymi ERC - start od 150J
  bool _isSynced = false;

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: widget.engine,
      builder: (context, _) {
        final state = widget.engine.state;

        return Scaffold(
          backgroundColor: Colors.black,
          body: SafeArea(
            child: Row(
              children: [
                // =========================================================
                // 1. EKRAN MONITORA (LEWA STRONA - GŁÓWNA)
                // =========================================================
                Expanded(
                  child: Container(
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey[900]!, width: 4),
                      color: const Color(0xFF0A0A0A),
                    ),
                    child: Column(
                      children: [
                        // --- GÓRNY PASEK STANU LIFEPAKA ---
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 4,
                          ),
                          color: Colors.grey[850],
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                state.currentPhase ==
                                        ResuscitationPhase.assessmentABCDE
                                    ? 'BRAK SYGNAŁU'
                                    : 'MONITORING AKTYWNY',
                                style: const TextStyle(
                                  color: Colors.white70,
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              Text(
                                "CZAS: ${(state.totalElapsedGameTime ~/ 60).toString().padLeft(2, '0')}:${(state.totalElapsedGameTime % 60).toString().padLeft(2, '0')}",
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                        ),

                        // --- FALA EKG (ZIELONA - SWEEP PAINTER) ---
                        Expanded(
                          flex: 3,
                          child: Stack(
                            children: [
                              Positioned.fill(
                                child: CustomPaint(painter: GridPainter()),
                              ),
                              Positioned.fill(
                                // OPTYMALIZACJA: RepaintBoundary izoluje renderowanie fali!
                                child: RepaintBoundary(
                                  child: SweepWaveDisplay(
                                    waveType: WaveType.ecg,
                                    rhythm: state.monitorRhythm,
                                    isCprActive: state.isCprActive,
                                    color: Colors.greenAccent,
                                  ),
                                ),
                              ),
                              Positioned(
                                top: 10,
                                left: 10,
                                child: Text(
                                  state.isCprActive
                                      ? "RKO ARTEFAKTY"
                                      : "II x1.0",
                                  style: TextStyle(
                                    color: state.isCprActive
                                        ? Colors.orange
                                        : Colors.greenAccent,
                                    fontSize: 14,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),

                        // --- FALA ETCO2 (ŻÓŁTA - SWEEP PAINTER) ---
                        Expanded(
                          flex: 1,
                          child: Stack(
                            children: [
                              Positioned.fill(
                                child: RepaintBoundary(
                                  child: SweepWaveDisplay(
                                    waveType: WaveType.etco2,
                                    isEtco2Attached:
                                        state.isCapnographyAttached,
                                    isVentilated:
                                        state.airwayStatus != AirwayType.none,
                                    color: Colors.yellowAccent,
                                  ),
                                ),
                              ),
                              const Positioned(
                                top: 5,
                                left: 10,
                                child: Text(
                                  "EtCO2",
                                  style: TextStyle(
                                    color: Colors.yellowAccent,
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),

                        // --- PASEK PARAMETRÓW CYFROWYCH ---
                        _buildNumericPanel(state),
                      ],
                    ),
                  ),
                ),

                // =========================================================
                // 2. PANEL STEROWANIA LIFEPAK (PRAWA STRONA - RESPONSYWNA)
                // =========================================================
                Container(
                  width: 140, // Zwężony, idealny na telefony
                  color: const Color(0xFF222222),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: ElevatedButton.icon(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: state.isCprActive
                                ? Colors.orange[900]
                                : Colors.green[700],
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(4),
                            ),
                          ),
                          icon: Icon(
                            state.isCprActive
                                ? Icons.stop_circle
                                : Icons.favorite,
                          ),
                          label: Text(
                            state.isCprActive
                                ? "STOP RKO\n(Oceń rytm)"
                                : "START\nRKO",
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          onPressed: () {
                            if (state.currentPhase ==
                                ResuscitationPhase.assessmentABCDE) {
                              widget.engine.connectMonitor();
                            }
                            if (state.isCprActive) {
                              widget.engine.stopCprAndAssess();
                            } else {
                              widget.engine.startCpr();
                            }
                          },
                        ),
                      ),
                      const Divider(color: Colors.black, thickness: 2),

                      Expanded(
                        child: SingleChildScrollView(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 8,
                          ),
                          child: Column(
                            children: [
                              _buildRotaryDial(),
                              const SizedBox(height: 15),
                              _buildLifepakButton(
                                "1 ENERGY",
                                Colors.grey[800]!,
                                () => widget.engine.setEnergy(
                                  _selectedEnergy.toInt(),
                                ),
                              ),
                              _buildLifepakButton(
                                "2 CHARGE",
                                state.isDefibCharging
                                    ? Colors.yellow[900]!
                                    : Colors.yellow[700]!,
                                () {
                                  widget.engine.setEnergy(
                                    _selectedEnergy.toInt(),
                                  );
                                  widget.engine.chargeDefibrillator();
                                },
                              ),
                              _buildLifepakButton(
                                "3 SHOCK",
                                state.isDefibCharged
                                    ? Colors.red[600]!
                                    : Colors.red[900]!,
                                () => widget.engine.deliverShock(),
                              ),
                              const SizedBox(height: 20),
                              _buildLifepakButton(
                                "SYNC",
                                _isSynced ? Colors.orange : Colors.grey[800]!,
                                () => setState(() => _isSynced = !_isSynced),
                              ),
                              _buildLifepakButton(
                                "NIBP",
                                Colors.blueGrey[800]!,
                                () {},
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildNumericPanel(AlsScenarioState state) {
    String hr = "0";
    if (state.isCprActive) {
      hr = "115";
    } else {
      if (state.monitorRhythm == PatientRhythm.pvt)
        hr = "214";
      else if (state.monitorRhythm == PatientRhythm.vf)
        hr = "---";
      else if (state.monitorRhythm == PatientRhythm.asystole)
        hr = "0";
      else
        hr = "72";
    }

    String spo2Value = "---";
    if (state.isSpO2Attached) {
      spo2Value = state.patient.hasPulse
          ? "${state.patient.spO2 ?? 98}"
          : "---";
    }

    return Container(
      height: 90,
      color: Colors.black,
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildValue("HR", hr, Colors.greenAccent),
          _buildValue("SpO2", spo2Value, Colors.cyanAccent),
          _buildValue(
            "EtCO2",
            state.isCapnographyAttached ? "${state.patient.etCo2}" : "--",
            Colors.yellowAccent,
          ),
          _buildValue("NIBP", "---/---", Colors.white),
        ],
      ),
    );
  }

  Widget _buildValue(String label, String val, Color color) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(label, style: TextStyle(color: color, fontSize: 10)),
        Text(
          val,
          style: TextStyle(
            color: color,
            fontSize: 28,
            fontWeight: FontWeight.bold,
            fontFamily: 'monospace',
          ),
        ),
      ],
    );
  }

  Widget _buildRotaryDial() {
    return Column(
      children: [
        const Text(
          "ENERGY SELECT",
          style: TextStyle(
            color: Colors.white54,
            fontSize: 9,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        GestureDetector(
          onVerticalDragUpdate: (details) {
            setState(() {
              _selectedEnergy = (_selectedEnergy - details.delta.dy).clamp(
                2,
                360,
              );
            });
          },
          child: Transform.rotate(
            angle: _selectedEnergy * 0.05,
            child: Container(
              width: 70,
              height: 70,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: const RadialGradient(
                  colors: [Color(0xFF444444), Color(0xFF111111)],
                ),
                border: Border.all(color: Colors.black, width: 3),
                boxShadow: const [
                  BoxShadow(color: Colors.black54, blurRadius: 8),
                ],
              ),
              child: Align(
                alignment: Alignment.topCenter,
                child: Container(
                  width: 4,
                  height: 15,
                  color: Colors.yellowAccent,
                  margin: const EdgeInsets.only(top: 5),
                ),
              ),
            ),
          ),
        ),
        const SizedBox(height: 5),
        Text(
          "${_selectedEnergy.toInt()} J",
          style: const TextStyle(
            color: Colors.yellowAccent,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  Widget _buildLifepakButton(String label, Color color, VoidCallback action) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: color,
          foregroundColor: Colors.white,
          minimumSize: const Size(double.infinity, 45),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
          elevation: 6,
        ),
        onPressed: action,
        child: Text(
          label,
          textAlign: TextAlign.center,
          style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold),
        ),
      ),
    );
  }
}

// =========================================================
// 🎨 ARCHITEKTURA SWEEP PAINTER (BUFOR DANYCH + TICKER)
// =========================================================

enum WaveType { ecg, etco2 }

class SweepWaveDisplay extends StatefulWidget {
  final WaveType waveType;
  final PatientRhythm? rhythm;
  final bool? isCprActive;
  final bool? isEtco2Attached;
  final bool? isVentilated;
  final Color color;

  const SweepWaveDisplay({
    super.key,
    required this.waveType,
    this.rhythm,
    this.isCprActive,
    this.isEtco2Attached,
    this.isVentilated,
    required this.color,
  });

  @override
  State<SweepWaveDisplay> createState() => _SweepWaveDisplayState();
}

class _SweepWaveDisplayState extends State<SweepWaveDisplay>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  // EBM: Wielkość bufora określa rozdzielczość matrycy EKG
  static const int maxPoints = 350;
  final List<double> _dataPoints = List.filled(maxPoints, 0.0);

  int _currentIndex = 0;
  double _internalTime = 0.0;
  final math.Random _random = math.Random();

  @override
  void initState() {
    super.initState();
    // Ticker działający na poziomie 60FPS dla płynności
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
    _internalTime += 0.035; // Skalibrowany przelicznik czasu (ok. 25 mm/s)

    if (widget.waveType == WaveType.ecg) {
      if (widget.isCprActive == true) {
        // ARTEFAKTY RKO: Potężne wahania linii od kompresji (ok 110/min) + szum wstrząsowy
        y =
            math.sin(_internalTime * 10.5) * 35 +
            math.sin(_internalTime * 50) * 4;
      } else if (widget.rhythm == PatientRhythm.unknown) {
        y = 0.0;
      } else if (widget.rhythm == PatientRhythm.vf) {
        // VF: Hiper-realistyczny kliniczny chaos. Suma 3 fal sinusoidalnych + losowy szum wędrujący
        y =
            math.sin(_internalTime * 4.5) * 12 +
            math.cos(_internalTime * 5.5) * 16 +
            math.sin(_internalTime * 7.2) * 8 +
            (_random.nextDouble() - 0.5) * 8; // Random noise!
      } else if (widget.rhythm == PatientRhythm.pvt) {
        // pVT: Szybki (rate ~200), uporządkowany ząb piły
        y = (math.sin(_internalTime * 11).abs() * -45) + 20;
      } else if (widget.rhythm == PatientRhythm.asystole) {
        // ASYSTOLIA: To nigdy nie jest płaska linia. Pływająca izoelektryczna (wandering baseline) + szum
        y =
            math.sin(_internalTime * 2) * 2 +
            math.sin(_internalTime * 0.5) * 1.5 +
            (_random.nextDouble() - 0.5) * 3;
      } else {
        // ZATOKA / PEA: P-QRS-T
        double phase = (_internalTime * 2.5) % 6.0;
        if (phase > 0.5 && phase < 0.9) {
          y = -6 * math.sin((phase - 0.5) * math.pi / 0.4); // P
        } else if (phase > 1.2 && phase < 1.5) {
          double qrsPhase = phase - 1.2;
          if (qrsPhase < 0.1)
            y = 5; // Q
          else if (qrsPhase < 0.2)
            y = -45; // R
          else
            y = 15; // S
        } else if (phase > 1.8 && phase < 2.6) {
          y = -10 * math.sin((phase - 1.8) * math.pi / 0.8); // T
        }
      }
    } else if (widget.waveType == WaveType.etco2) {
      if (widget.isEtco2Attached == true && widget.isVentilated == true) {
        double phase = (_internalTime * 1.5) % 6;
        if (phase < 2.5) y = -25; // Kwadratowa fala wydechu
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

// =========================================================
// 🎨 ENGINE RYSOWANIA (ERASER BAR)
// =========================================================

class SweepPainter extends CustomPainter {
  final List<double> dataPoints;
  final int currentIndex;
  final Color color;

  // EBM: Wielkość gumki zmazującej stare EKG przed narysowaniem nowego (~5% ekranu)
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
    final double midY =
        size.height /
        (color == Colors.yellowAccent ? 1.2 : 2); // EtCO2 rysujemy niżej

    bool isFirstPoint = true;

    for (int i = 0; i < dataPoints.length; i++) {
      // LOGIKA WYMAZYWACZA (Eraser Gap):
      // Nie rysujemy linii w małym odstępie "przed" obecnym indeksem, aby oddzielić stare dane od nowych.
      bool inEraser = false;
      if (currentIndex + eraserGap < dataPoints.length) {
        if (i >= currentIndex && i < currentIndex + eraserGap) inEraser = true;
      } else {
        if (i >= currentIndex ||
            i < (currentIndex + eraserGap) % dataPoints.length)
          inEraser = true;
      }

      if (inEraser) {
        isFirstPoint = true; // Łamiemy ścieżkę, przerywamy linię
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

    // Opcjonalny bajer: mała "głowica" świecąca na czubku fali EKG (daje feeling CRT)
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
  bool shouldRepaint(SweepPainter old) {
    // Ponieważ przekazujemy referencję do listy, a nie jej kopię,
    // indeks służy nam jako główny wyzwalacz odrysowania
    return old.currentIndex != currentIndex;
  }
}

class GridPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.green[900]!.withOpacity(0.3)
      ..strokeWidth = 0.5;
    for (double i = 0; i < size.width; i += 15) {
      canvas.drawLine(Offset(i, 0), Offset(i, size.height), paint);
    }
    for (double i = 0; i < size.height; i += 15) {
      canvas.drawLine(Offset(0, i), Offset(size.width, i), paint);
    }
  }

  @override
  bool shouldRepaint(GridPainter old) => false;
}
