import 'package:flutter/services.dart';
import 'package:flutter/material.dart';
import 'features/scenario/screens/scenario_intro_screen.dart';

void main() {
  // To musi być dodane, żeby móc używać SystemChrome przed runApp!
  WidgetsFlutterBinding.ensureInitialized();

  // Wymuszamy orientację poziomą (obie strony)
  SystemChrome.setPreferredOrientations([
    DeviceOrientation.landscapeRight,
    DeviceOrientation.landscapeLeft,
  ]);

  // Ukrywamy górny pasek powiadomień i dolne przyciski nawigacji Androida (Immersive Mode)
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
      // Ustawiamy ciemny motyw, bo monitory medyczne świecą w ciemności
      theme: ThemeData.dark().copyWith(scaffoldBackgroundColor: Colors.black),
      home: const ScenarioIntroScreen(),
    );
  }
}
