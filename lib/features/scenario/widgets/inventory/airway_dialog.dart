import 'package:flutter/material.dart';
import '../../logic/game_engine.dart';
import '../../models/als_state.dart';

class AirwayDialog extends StatefulWidget {
  final GameEngine engine;

  const AirwayDialog({super.key, required this.engine});

  @override
  State<AirwayDialog> createState() => _AirwayDialogState();
}

class _AirwayDialogState extends State<AirwayDialog>
    with SingleTickerProviderStateMixin {
  double _currentO2 = 0;
  int _selectedIGel = 4;

  late AnimationController _blinkController;

  @override
  void initState() {
    super.initState();
    _currentO2 = widget.engine.state.oxygenFlow.toDouble();

    // Ustawiamy animację: 500 ms w jedną stronę, potem powrót (pulse)
    _blinkController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _blinkController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: widget.engine,
      builder: (context, _) {
        final state = widget.engine.state;

        return AlertDialog(
          backgroundColor: Colors.grey[900],
          title: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Torba Oddechowa',
                style: TextStyle(color: Colors.blueAccent),
              ),
              Text(
                'Waga: ${state.patientWeight.toStringAsFixed(0)} kg',
                style: const TextStyle(color: Colors.white, fontSize: 16),
              ),
            ],
          ),
          content: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  '1. Tlen (l/min)',
                  style: TextStyle(color: Colors.grey),
                ),
                Row(
                  children: [
                    Expanded(
                      child: Slider(
                        value: _currentO2,
                        min: 0,
                        max: 20,
                        divisions: 20,
                        activeColor: Colors.blue,
                        label: _currentO2.round().toString(),
                        onChanged: (val) {
                          setState(() {
                            _currentO2 = val;
                          });
                        },
                        onChangeEnd: (val) {
                          widget.engine.setOxygenFlow(val.round());
                        },
                      ),
                    ),
                    Text(
                      '${_currentO2.round()} l/min',
                      style: const TextStyle(color: Colors.white),
                    ),
                  ],
                ),
                const Divider(color: Colors.grey),

                const Text(
                  '2. Podstawowe & BVM',
                  style: TextStyle(color: Colors.grey),
                ),
                const SizedBox(height: 10),
                Wrap(
                  spacing: 10,
                  runSpacing: 10,
                  children: [
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: state.airwayStatus != AirwayType.none
                            ? Colors.green
                            : Colors.grey[800],
                      ),
                      onPressed: () => widget.engine.openAirway(),
                      child: const Text('Rękoczyn udrożnienia'),
                    ),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: state.airwayStatus == AirwayType.bvm
                            ? Colors.green
                            : Colors.grey[800],
                      ),
                      onPressed: () => widget.engine.setupBVM(),
                      child: const Text('Podłącz BVM (Auto)'),
                    ),
                    ElevatedButton.icon(
                      icon: const Icon(Icons.air),
                      label: const Text('Preoksygenacja przed ETI'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: state.isPreoxygenated
                            ? Colors.green
                            : Colors.blue[700],
                      ),
                      onPressed:
                          state.airwayStatus == AirwayType.bvm &&
                              !state.isPreoxygenated
                          ? () => widget.engine.preoxygenate()
                          : null,
                    ),
                  ],
                ),
                const Divider(color: Colors.grey),

                const Text(
                  '3. Zaawansowane (SGA / ETI)',
                  style: TextStyle(color: Colors.grey),
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    DropdownButton<int>(
                      value: _selectedIGel,
                      dropdownColor: Colors.grey[800],
                      style: const TextStyle(color: Colors.white),
                      items: const [
                        DropdownMenuItem(
                          value: 3,
                          child: Text('I-gel #3 (30 - 60 kg)'),
                        ),
                        DropdownMenuItem(
                          value: 4,
                          child: Text('I-gel #4 (50 - 90 kg)'),
                        ),
                        DropdownMenuItem(
                          value: 5,
                          child: Text('I-gel #5 (> 90 kg)'),
                        ),
                      ],
                      onChanged: (val) {
                        setState(() {
                          _selectedIGel = val!;
                        });
                      },
                    ),
                    const SizedBox(width: 10),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: state.airwayStatus == AirwayType.igel
                            ? Colors.green
                            : Colors.purple[700],
                      ),
                      onPressed: () => widget.engine.insertIGel(_selectedIGel),
                      child: const Text('Załóż I-gel'),
                    ),
                  ],
                ),
                const SizedBox(height: 10),

                // ZMIANA: Twardy audyt "Rurki Schrödingera" (dynamiczny kolor)
                AnimatedBuilder(
                  animation: _blinkController,
                  builder: (context, child) {
                    Color? etiColor;

                    if (state.intubationAttemptInProgress) {
                      etiColor = Colors.orange[800]; // W trakcie
                    } else if (state.airwayStatus == AirwayType.endotracheal) {
                      if (!state.isIntubationVerified) {
                        // Niezweryfikowana! Mruga na żółto
                        etiColor = Color.lerp(
                          Colors.yellow[800],
                          Colors.yellow[400],
                          _blinkController.value,
                        );
                      } else {
                        // Zweryfikowana!
                        if (state.intubationStatus ==
                            IntubationStatus.correct) {
                          etiColor = Colors.green; // Rurka prawidłowa
                        } else {
                          // Błędna! Mruga na czerwono
                          etiColor = Color.lerp(
                            Colors.red[900],
                            Colors.redAccent,
                            _blinkController.value,
                          );
                        }
                      }
                    } else {
                      etiColor =
                          Colors.indigo[600]; // Domyślny kolor przed akcją
                    }

                    return ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: etiColor,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 20,
                          vertical: 12,
                        ),
                      ),
                      onPressed: state.intubationAttemptInProgress
                          ? null
                          : () => widget.engine.attemptIntubation(),
                      child: Text(
                        state.intubationAttemptInProgress
                            ? 'INTUBOWANIE...'
                            : (state.isIntubationVerified
                                  ? 'INTUBACJA ETI (Sprawdzona)'
                                  : 'INTUBACJA ETI'),
                        style: TextStyle(
                          color:
                              (etiColor == Colors.green ||
                                  etiColor == Colors.indigo[600])
                              ? Colors.white
                              : Colors.black,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    );
                  },
                ),

                const Divider(color: Colors.grey),

                const Text(
                  '4. Diagnostyka EBM',
                  style: TextStyle(color: Colors.grey),
                ),
                const SizedBox(height: 10),
                Wrap(
                  spacing: 10,
                  children: [
                    ElevatedButton.icon(
                      icon: const Icon(Icons.hearing),
                      label: const Text('Osłuchaj klatkę'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.teal,
                      ),
                      onPressed: () => widget.engine.auscultate(),
                    ),
                    ElevatedButton.icon(
                      icon: const Icon(Icons.monitor_heart),
                      label: const Text('Podłącz Kapnografię'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: state.isCapnographyAttached
                            ? Colors.green
                            : Colors.orange[800],
                      ),
                      onPressed: state.isCapnographyAttached
                          ? null
                          : () => widget.engine.attachCapnography(),
                    ),
                  ],
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text(
                'ZAMKNIJ',
                style: TextStyle(color: Colors.white),
              ),
            ),
          ],
        );
      },
    );
  }
}
