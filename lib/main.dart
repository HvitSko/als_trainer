import 'package:flutter/material.dart';
import 'features/scenario/screens/main_game_screen.dart';

void main() {
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
      home: const MainGameScreen(),
    );
  }
}
