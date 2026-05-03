import 'package:flutter/material.dart';
import '../../logic/game_engine.dart';

class IvMinigameDialog extends StatelessWidget {
  final GameEngine engine;
  const IvMinigameDialog({super.key, required this.engine});

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: Colors.black87,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.greenAccent, width: 2),
          boxShadow: [
            BoxShadow(
              color: Colors.greenAccent.withOpacity(0.3),
              blurRadius: 15,
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.vaccines, color: Colors.greenAccent, size: 60),
            const SizedBox(height: 15),
            const Text(
              "MINIGRA: KANIULACJA ŻYŁY",
              style: TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 15),
            const Text(
              "Tu w przyszłości będzie zaawansowana minigra z wyborem kąta wkłucia i szukaniem żyły.",
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey),
            ),
            const SizedBox(height: 25),
            ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green[800],
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 15,
                ),
              ),
              icon: const Icon(Icons.check, color: Colors.white),
              label: const Text(
                "ZAKŁADAM WENFLON",
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
              onPressed: () {
                engine.state.isIvInserted = true;
                Navigator.of(context).pop();
                // Tu niestety musimy oszukać system, by wywołał powiadomienie
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text("SUKCES: Uzyskano dostęp naczyniowy (IV)!"),
                    backgroundColor: Colors.green,
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
