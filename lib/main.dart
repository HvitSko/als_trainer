import 'package:flutter/services.dart';
import 'package:flutter/material.dart';
import 'features/scenario/screens/scenario_intro_screen.dart';
import 'app_localization.dart'; // NASZ NOWY SILNIK TŁUMACZA

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setPreferredOrientations([
    DeviceOrientation.landscapeRight,
    DeviceOrientation.landscapeLeft,
  ]);
  SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
  runApp(const AlsGameApp());
}

class AlsGameApp extends StatelessWidget {
  const AlsGameApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'ALS Trainer',
      debugShowCheckedModeBanner: false,
      theme: ThemeData.dark().copyWith(scaffoldBackgroundColor: Colors.black),
      home: const LanguageSelectionScreen(), // STARTUJEMY OD WYBORU JĘZYKA
    );
  }
}

class LanguageSelectionScreen extends StatelessWidget {
  const LanguageSelectionScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.language, size: 80, color: Colors.blueAccent),
            const SizedBox(height: 30),
            const Text(
              "CHOOSE LANGUAGE / WYBIERZ JĘZYK",
              style: TextStyle(
                color: Colors.white,
                fontSize: 24,
                fontWeight: FontWeight.bold,
                letterSpacing: 2,
              ),
            ),
            const SizedBox(height: 50),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _buildLangBtn(context, "POLSKI", false),
                const SizedBox(width: 40),
                _buildLangBtn(context, "ENGLISH", true),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLangBtn(BuildContext context, String text, bool isEn) {
    return ElevatedButton(
      style: ElevatedButton.styleFrom(
        padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 25),
        backgroundColor: Colors.grey[900],
        side: const BorderSide(color: Colors.blueAccent, width: 2),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      ),
      onPressed: () {
        AppLoc.isEn = isEn; // USTAWIANIE GLOBALNEJ FLAGI
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (_) => const ScenarioIntroScreen()),
        );
      },
      child: Text(
        text,
        style: const TextStyle(
          fontSize: 22,
          color: Colors.white,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}
