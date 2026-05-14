import 'package:flutter/material.dart';
import 'dart:math' as math;
import '../logic/game_engine.dart';

class MonitorView extends StatefulWidget {
  final GameEngine engine;
  const MonitorView({super.key, required this.engine});

  @override
  State<MonitorView> createState() => _MonitorViewState();
}

class _MonitorViewState extends State<MonitorView>
    with SingleTickerProviderStateMixin {
  late AnimationController _ticker;
  double _time = 0;
  double _selectedEnergy = 200; // Domyślna energia Lifepaka
  bool _isSynced = false;

  @override
  void initState() {
    super.initState();
    _ticker = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 1),
    )..repeat();
    _ticker.addListener(() {
      setState(() {
        _time += 0.15; // Prędkość przesuwu fali
      });
    });
  }

  @override
  void dispose() {
    _ticker.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Row(
        children: [
          // =========================================================
          // 1. EKRAN MONITORA (LEWA STRONA)
          // =========================================================
          Expanded(
            flex: 3,
            child: Container(
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey[900]!, width: 4),
              ),
              child: Column(
                children: [
                  // --- FALA EKG (ZIELONA) ---
                  Expanded(
                    child: Stack(
                      children: [
                        Positioned.fill(
                          child: CustomPaint(painter: GridPainter()),
                        ),
                        Positioned.fill(
                          child: CustomPaint(
                            painter: EcgPainter(
                              time: _time,
                              // SKIPPY FIX: Zamieniamy typ systemowy na czysty tekst dla rysownika!
                              rhythm: widget.engine.state.monitorRhythm.name
                                  .toUpperCase(),
                              color: Colors.greenAccent,
                            ),
                          ),
                        ),
                        const Positioned(
                          top: 10,
                          left: 10,
                          child: Text(
                            "II x1.0",
                            style: TextStyle(
                              color: Colors.greenAccent,
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  // --- FALA ETCO2 (ŻÓŁTA) ---
                  Expanded(
                    child: Stack(
                      children: [
                        Positioned.fill(
                          child: CustomPaint(
                            painter: Etco2Painter(
                              time: _time,
                              isEtco2Attached:
                                  widget.engine.state.isCapnographyAttached,
                              color: Colors.yellowAccent,
                            ),
                          ),
                        ),
                        const Positioned(
                          top: 10,
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
                  _buildNumericPanel(),
                ],
              ),
            ),
          ),

          // =========================================================
          // 2. PANEL STEROWANIA LIFEPAK (PRAWA STRONA)
          // =========================================================
          Container(
            width: 250,
            decoration: BoxDecoration(
              color: const Color(0xFF2A2A2A),
              border: Border.all(color: Colors.black, width: 2),
            ),
            child: Column(
              children: [
                const SizedBox(height: 20),
                _buildLifepakButton(
                  widget.engine.state.isCprActive ? "STOP RKO" : "START RKO",
                  widget.engine.state.isCprActive
                      ? Colors.orange[900]!
                      : Colors.green[800]!,
                  () {
                    // Magia Skippy'ego: Używamy odpowiednich funkcji w zależności od stanu!
                    if (widget.engine.state.isCprActive) {
                      widget.engine.stopCprAndAssess();
                    } else {
                      widget.engine.startCpr();
                    }
                  },
                ),
                _buildRotaryDial(), // Pokrętło energii
                const SizedBox(height: 20),
                _buildLifepakButton(
                  "1 SELECT ENERGY",
                  Colors.grey[800]!,
                  () {},
                ),
                _buildLifepakButton("2 CHARGE", Colors.yellow[700]!, () {
                  // Przekazujemy wybraną na pokrętle energię do silnika i ładujemy!
                  widget.engine.setEnergy(_selectedEnergy.toInt());
                  widget.engine.chargeDefibrillator();
                }),
                _buildLifepakButton("3 SHOCK", Colors.red[900]!, () {
                  // Prawidłowa nazwa funkcji z Twojego game_engine.dart
                  widget.engine.deliverShock();
                }),
                const Spacer(),
                _buildLifepakButton(
                  "SYNC",
                  _isSynced ? Colors.orange : Colors.grey[700]!,
                  () {
                    setState(() => _isSynced = !_isSynced);
                  },
                ),
                _buildLifepakButton("NIBP", Colors.blueGrey[700]!, () {
                  // TODO: Zgodnie z planem, ciśnieniomierz dodamy w kolejnych łatkach
                  // Na razie przycisk "klika na pusto", by nie wysadzić aplikacji w kosmos
                }),
                const SizedBox(height: 20),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNumericPanel() {
    // MAGIA SKIPPY'EGO: HR (Tętno) zależy od tego, czy pacjent odzyskał tętno fizyczne (ROSC), a nie od nazwy rytmu na ekranie!
    final hr = widget.engine.state.patient.hasPulse ? "72" : "0";

    // LOGIKA EBM: SpO2 pokazuje wartość tylko gdy klips jest przypięty I gdy jest tętno!
    String spo2Value = "---";
    if (widget.engine.state.isSpO2Attached) {
      spo2Value = widget.engine.state.patient.hasPulse
          ? "${widget.engine.state.patient.spO2 ?? 98}"
          : "---";
    }

    return Container(
      height: 120,
      color: Colors.black,
      padding: const EdgeInsets.all(8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildValue("HR", hr, Colors.greenAccent),
          _buildValue("SpO2", spo2Value, Colors.cyanAccent), // dynamiczne SpO2
          _buildValue(
            "EtCO2",
            widget.engine.state.isCapnographyAttached ? "35" : "--",
            Colors.yellowAccent,
          ),
          _buildValue("NIBP", "---/---", Colors.white),
        ],
      ),
    );
  }

  Widget _buildValue(String label, String val, Color color) {
    return Column(
      children: [
        Text(label, style: TextStyle(color: color, fontSize: 12)),
        Text(
          val,
          style: TextStyle(
            color: color,
            fontSize: 32,
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
          style: TextStyle(color: Colors.white, fontSize: 10),
        ),
        const SizedBox(height: 10),
        GestureDetector(
          onVerticalDragUpdate: (details) {
            setState(() {
              _selectedEnergy = (_selectedEnergy + details.delta.dy).clamp(
                2,
                360,
              );
            });
          },
          child: Transform.rotate(
            angle: _selectedEnergy * 0.05,
            child: Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.grey[900],
                border: Border.all(color: Colors.grey[700]!, width: 4),
                boxShadow: const [
                  BoxShadow(color: Colors.black, blurRadius: 10),
                ],
              ),
              child: Stack(
                children: [
                  Center(
                    child: Container(
                      width: 4,
                      height: 40,
                      color: Colors.redAccent,
                      margin: const EdgeInsets.only(bottom: 40),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        const SizedBox(height: 10),
        Text(
          "${_selectedEnergy.toInt()} J",
          style: const TextStyle(
            color: Colors.yellowAccent,
            fontSize: 24,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  Widget _buildLifepakButton(String label, Color color, VoidCallback action) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 20),
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: color,
          foregroundColor: Colors.white,
          minimumSize: const Size(double.infinity, 50),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
          elevation: 8,
        ),
        onPressed: action,
        child: Text(
          label,
          textAlign: TextAlign.center,
          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
        ),
      ),
    );
  }
}

// =========================================================
// 🎨 SILNIK GRAFICZNY FAL (PAINTERS)
// =========================================================

class EcgPainter extends CustomPainter {
  final double time;
  final String rhythm;
  final Color color;
  EcgPainter({required this.time, required this.rhythm, required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 2.5
      ..style = PaintingStyle.stroke;
    final path = Path();

    path.moveTo(0, size.height / 2);
    for (double x = 0; x < size.width; x++) {
      double y = size.height / 2;

      // LOGIKA RYTMÓW NZK (EBM)
      if (rhythm == "VF") {
        y +=
            math.sin(x * 0.1 + time * 2) *
            15 *
            math.sin(x * 0.05); // Chaotyczna fala VF
      } else if (rhythm == "VT") {
        y +=
            (math.sin(x * 0.15 + time * 3).abs() * -40) +
            20; // Szerokie zespoły VT
      } else if (rhythm == "Asystolia") {
        y += math.sin(x * 0.5) * 1.5; // Prawie płaska linia
      } else {
        // Rytm zatokowy / PEA (Podstawowy QRS)
        double phase = (x * 0.05 + time) % 5;
        if (phase < 0.2)
          y -= 40 * math.sin(phase * math.pi / 0.2); // Zespół QRS
      }

      path.lineTo(x, y);
    }
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(EcgPainter old) => true;
}

class Etco2Painter extends CustomPainter {
  final double time;
  final bool isEtco2Attached;
  final Color color;
  Etco2Painter({
    required this.time,
    required this.isEtco2Attached,
    required this.color,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (!isEtco2Attached) return;
    final paint = Paint()
      ..color = color
      ..strokeWidth = 2.0
      ..style = PaintingStyle.stroke;
    final path = Path();
    path.moveTo(0, size.height * 0.8);
    for (double x = 0; x < size.width; x++) {
      double phase = (x * 0.03 + time) % 6;
      double y = size.height * 0.8;
      if (phase < 2) y -= 30; // Prostokątna fala EtCO2
      path.lineTo(x, y);
    }
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(Etco2Painter old) => true;
}

class GridPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.grey[900]!
      ..strokeWidth = 0.5;
    for (double i = 0; i < size.width; i += 20)
      canvas.drawLine(Offset(i, 0), Offset(i, size.height), paint);
    for (double i = 0; i < size.height; i += 20)
      canvas.drawLine(Offset(0, i), Offset(size.width, i), paint);
  }

  @override
  bool shouldRepaint(GridPainter old) => false;
}
