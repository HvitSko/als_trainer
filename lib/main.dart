import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'features/menu/screens/main_menu_screen.dart';
import 'features/scenario/screens/scenario_intro_screen.dart';
import 'features/settings/settings_manager.dart';
import 'app_localization.dart';

void main() async {
  // 1. Zabezpieczenie wiązań z silnikiem (Flutter) przed asynchronicznym startem
  WidgetsFlutterBinding.ensureInitialized();

  // 2. Blokada ekranu w poziomie
  SystemChrome.setPreferredOrientations([
    DeviceOrientation.landscapeRight,
    DeviceOrientation.landscapeLeft,
  ]);
  SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);

  // 3. Budzimy Menedżera Pamięci (Czytanie z dysku) przed uruchomieniem UI!
  final settingsManager = await SettingsManager.init();

  // 4. Synchronizujemy nasz stary, twardy silnik tłumaczeń (AppLoc) z pamięcią
  AppLoc.isEn = settingsManager.isEnglish;

  // 5. Odpalamy aplikację oplątaną Providerem, żeby każde okno miało dostęp do ustawień
  runApp(
    MultiProvider(
      providers: [ChangeNotifierProvider.value(value: settingsManager)],
      child: const AlsGameApp(),
    ),
  );
}

class AlsGameApp extends StatelessWidget {
  const AlsGameApp({super.key});

  @override
  Widget build(BuildContext context) {
    // Nasłuchujemy na zmiany ustawień z SettingsManager
    final settings = context.watch<SettingsManager>();

    // Zapewniamy synchronizację globalnej flagi AppLoc za każdą zmianą stanu w UI
    AppLoc.isEn = settings.isEnglish;

    return MaterialApp(
      title: 'ALS Trainer',
      debugShowCheckedModeBanner: false,
      theme: ThemeData.dark().copyWith(scaffoldBackgroundColor: Colors.black),

      // MAGIA UX: Jeśli gracz był tu wcześniej (ma ukończony onboarding),
      // pomijamy ekran wyboru języka!
      // UWAGA: Na razie kierujemy go do ScenarioIntroScreen. Kiedy zbudujemy
      // MainMenuScreen, podmienimy to właśnie tutaj.
      home: settings.hasCompletedOnboarding
          ? const MainMenuScreen()
          : const LanguageSelectionScreen(),
    );
  }
}

class LanguageSelectionScreen extends StatelessWidget {
  const LanguageSelectionScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // Czytamy stan bez ciągłego nasłuchiwania (read zamiast watch),
    // bo to tylko ekran wyboru.
    final settings = context.read<SettingsManager>();

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
                _buildLangBtn(context, settings, "POLSKI", false),
                const SizedBox(width: 40),
                _buildLangBtn(context, settings, "ENGLISH", true),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLangBtn(
    BuildContext context,
    SettingsManager settings,
    String text,
    bool isEn,
  ) {
    return ElevatedButton(
      style: ElevatedButton.styleFrom(
        padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 25),
        backgroundColor: Colors.grey[900],
        side: const BorderSide(color: Colors.blueAccent, width: 2),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      ),
      onPressed: () async {
        // 1. Zapisujemy wybór do pamięci trwałej urządzenia (NIGDY WIĘCEJ AMNEZJI)
        await settings.setLanguage(english: isEn);
        await settings.completeOnboarding(); // Flaga: Onboarding Zakończony

        // 2. Wpuszczamy małpę do menu głównego
        if (context.mounted) {
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(builder: (_) => const MainMenuScreen()),
          );
        }
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
