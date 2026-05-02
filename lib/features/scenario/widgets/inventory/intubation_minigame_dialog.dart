import 'package:flutter/material.dart';
import '../../logic/game_engine.dart';

class IntubationMinigameDialog extends StatefulWidget {
  final GameEngine engine;
  const IntubationMinigameDialog({super.key, required this.engine});

  @override
  State<IntubationMinigameDialog> createState() =>
      _IntubationMinigameDialogState();
}

class _IntubationMinigameDialogState extends State<IntubationMinigameDialog> {
  int _stage = 1;
  bool _hitTrachea = false;
  bool _correctDepth = false;

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: Colors.black87,
      shape: RoundedRectangleBorder(
        side: const BorderSide(color: Colors.redAccent, width: 2),
        borderRadius: BorderRadius.circular(12),
      ),
      title: const Text(
        'MINIGRA: Intubacja (W.I.P)',
        style: TextStyle(color: Colors.redAccent, fontWeight: FontWeight.bold),
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text("Etap $_stage / 2", style: const TextStyle(color: Colors.grey)),
          const SizedBox(height: 20),
          if (_stage == 1) ...[
            const Text(
              "Wprowadzasz laryngoskop. Gdzie celujesz?",
              style: TextStyle(color: Colors.white),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue[900],
              ),
              onPressed: () => setState(() {
                _hitTrachea = true;
                _stage = 2;
              }),
              child: const Text("Struny Głosowe (Tchawica)"),
            ),
            const SizedBox(height: 10),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: Colors.red[900]),
              onPressed: () => setState(() {
                _hitTrachea = false;
                _stage = 2;
              }),
              child: const Text("Ciemny Otwór (Przełyk)"),
            ),
          ],
          if (_stage == 2) ...[
            const Text(
              "Rurka przechodzi. Na jaką głębokość wsuwasz?",
              style: TextStyle(color: Colors.white),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green[900],
              ),
              onPressed: () {
                _correctDepth = true;
                _finish();
              },
              child: const Text("Do znacznika (Ok. 22cm na zębach)"),
            ),
            const SizedBox(height: 10),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.orange[900],
              ),
              onPressed: () {
                _correctDepth = false;
                _finish();
              },
              child: const Text("Do oporu (Za głęboko)"),
            ),
          ],
        ],
      ),
    );
  }

  void _finish() {
    Navigator.of(context).pop();
    widget.engine.finishIntubationMinigame(_hitTrachea, _correctDepth);
  }
}
