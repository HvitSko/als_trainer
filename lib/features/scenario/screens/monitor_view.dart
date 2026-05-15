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
    with SingleTickerProviderStateMixin {
  late AnimationController _ticker;
  double _time = 0;
  double _selectedEnergy = 150; // Zgodnie z wytycznymi ERC - start od 150J
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
        _time += 0.02; // Płynna, idealna prędkość 25 mm/s dla monitora
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
                        // --- FALA EKG (ZIELONA) ---
                        Expanded(
                          flex: 3,
                          child: Stack(
                            children: [
                              Positioned.fill(
                                child: CustomPaint(painter: GridPainter()),
                              ),
                              Positioned.fill(
                                child: CustomPaint(
                                  painter: EcgPainter(
                                    time: _time,
                                    rhythm: state.monitorRhythm,
                                    isCprActive: state
                                        .isCprActive, // EBM: Artefakty z RKO!
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
                        // --- FALA ETCO2 (ŻÓŁTA) ---
                        Expanded(
                          flex: 1,
                          child: Stack(
                            children: [
                              Positioned.fill(
                                child: CustomPaint(
                                  painter: Etco2Painter(
                                    time: _time,
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
                      // GŁÓWNY PRZYCISK RKO (Zawsze na wierzchu)
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
                              widget.engine
                                  .connectMonitor(); // Skrót do podłączenia
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

                      // RESZTA PRZYCISKÓW W PRZEWIJALNYM KONTENERZE (Brak problemu overflow!)
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
                                () {
                                  widget.engine.setEnergy(
                                    _selectedEnergy.toInt(),
                                  );
                                },
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
                                () {
                                  widget.engine.deliverShock();
                                },
                              ),
                              const SizedBox(height: 20),
                              _buildLifepakButton(
                                "SYNC",
                                _isSynced ? Colors.orange : Colors.grey[800]!,
                                () {
                                  setState(() => _isSynced = !_isSynced);
                                },
                              ),
                              _buildLifepakButton(
                                "NIBP",
                                Colors.blueGrey[800]!,
                                () {},
                              ), // Miejsce na przyszłość
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
    // EBM Logika Tętna
    final hr = state.patient.hasPulse ? "72" : "0";

    // EBM Logika SpO2
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
            // Przesuwanie palcem w górę/dół po kole zmienia dżule!
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
// 🎨 ZAAWANSOWANY SILNIK GRAFICZNY FAL EKG (EBM MATEMATYKA)
// =========================================================

class EcgPainter extends CustomPainter {
  final double time;
  final PatientRhythm rhythm;
  final bool isCprActive;
  final Color color;

  EcgPainter({
    required this.time,
    required this.rhythm,
    required this.isCprActive,
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

    path.moveTo(0, size.height / 2);
    for (double x = 0; x < size.width; x++) {
      double y = size.height / 2;

      // EBM: ZAKŁÓCENIA OD UCIŚNIĘĆ KLP (Artefakty RKO ukrywają prawdziwy rytm!)
      if (isCprActive) {
        // Symulacja regularnych uciśnięć (ok 110/min) - ogromne wahania linii
        y += math.sin(x * 0.08 + time * 12) * 35 + math.sin(x * 0.3) * 5;
      }
      // RYTMIKA
      else if (rhythm == PatientRhythm.unknown) {
        y += 0; // Płaska linia (niepodłączony)
      } else if (rhythm == PatientRhythm.vf) {
        // EBM MIGOTANIE KOMÓR: Hiper-realistyczny, chaotyczny wzorzec z filmu
        // Sumujemy 3 fale: bujanie linii podstawowej (waxing/waning), główne fale VF oraz drobny szum
        y +=
            (math.sin(x * 0.03 + time * 3.5) * 22) *
                math.cos(
                  x * 0.015 - time,
                ) + // Nisko-częstotliwościowe bujanie amplitudy
            (math.sin(x * 0.08 - time * 4.5) *
                12) + // Średnie, nieregularne wibracje
            (math.sin(x * 0.25 + time * 8) * 4); // Drobny, "szarpany" szum
      } else if (rhythm == PatientRhythm.pvt) {
        // CZĘSTOSKURCZ KOMOROWY: Szerokie, regularne zęby piły / góry
        y += (math.sin(x * 0.12 + time * 4).abs() * -45) + 20;
      } else if (rhythm == PatientRhythm.asystole) {
        // ASYSTOLIA: Delikatne pływanie linii izoelektrycznej, niemal płasko
        y += math.sin(x * 0.02 + time) * 2 + math.sin(x * 0.1) * 0.5;
      } else {
        // PEA / ROSC (RYTM ZATOKOWY): Matematyczny model P-QRS-T
        double phase = (x * 0.02 + time * 2) % 6.0; // Długość cyklu
        if (phase > 0.5 && phase < 0.9) {
          y -= 6 * math.sin((phase - 0.5) * math.pi / 0.4); // Załamek P
        } else if (phase > 1.2 && phase < 1.5) {
          double qrsPhase = phase - 1.2;
          if (qrsPhase < 0.1)
            y += 5; // Q
          else if (qrsPhase < 0.2)
            y -= 45; // R
          else
            y += 15; // S
        } else if (phase > 1.8 && phase < 2.6) {
          y -= 10 * math.sin((phase - 1.8) * math.pi / 0.8); // Załamek T
        }
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
  final bool isVentilated;
  final Color color;
  Etco2Painter({
    required this.time,
    required this.isEtco2Attached,
    required this.isVentilated,
    required this.color,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (!isEtco2Attached) return; // Brak czujnika
    final paint = Paint()
      ..color = color
      ..strokeWidth = 2.0
      ..style = PaintingStyle.stroke;
    final path = Path();
    path.moveTo(0, size.height * 0.8);
    for (double x = 0; x < size.width; x++) {
      double y = size.height * 0.8;
      if (isVentilated) {
        double phase = (x * 0.02 + time) % 6;
        if (phase < 2.5) y -= 25; // Kwadratowa fala wydechu EtCO2
      }
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
