import 'package:flutter/material.dart';
import '../../scenario/screens/scenario_intro_screen.dart';
import '../../scenario/models/scenario_database.dart';
import '../../scenario/models/scenario_model.dart';
import '../../settings/settings_dialog.dart';
import '../../settings/settings_manager.dart';
import '../../../app_localization.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

class MainMenuScreen extends StatelessWidget {
  const MainMenuScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final settings = context.watch<SettingsManager>();
    AppLoc.isEn = settings.isEnglish;
    return Scaffold(
      body: Stack(
        children: [
          // 1. Tło: Grafika Karetki (Skorygowane wyrównanie na TopRight - ratuje ucięte logo!)
          Positioned.fill(
            child: Image.asset(
              'assets/images/Ekran_menu.png',
              fit: BoxFit.cover,
              alignment: Alignment.topRight,
            ),
          ),

          // 2. Mroczny Gradient po lewej stronie
          Positioned(
            left: 0,
            top: 0,
            bottom: 0,
            width: MediaQuery.of(context).size.width * 0.45,
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Colors.black.withValues(alpha: 0.95),
                    Colors.transparent,
                  ],
                  begin: Alignment.centerLeft,
                  end: Alignment.centerRight,
                ),
              ),
            ),
          ),

          // 3. Główne Przyciski (Usunięto tekst "ALS Trainer", guziki idą wyżej)
          Positioned(
            left: 40,
            top: 0,
            bottom: 0,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildNeonButton(
                  text: AppLoc.tr("ROZPOCZNIJ DYŻUR", "START SHIFT"),
                  icon: Icons.local_shipping,
                  color: Colors.redAccent,
                  onTap: () {
                    // Startuje Szybki Dyżur (losowy scenariusz)
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => const ScenarioIntroScreen(),
                      ),
                    );
                  },
                ),

                _buildNeonButton(
                  text: AppLoc.tr("WYBÓR SCENARIUSZA", "SELECT SCENARIO"),
                  icon: Icons.list_alt,
                  color: Colors.cyanAccent,
                  onTap: () => _showScenarioSelectionDialog(context),
                ),

                _buildNeonButton(
                  text: AppLoc.tr("O APLIKACJI", "ABOUT THE APP"),
                  icon: Icons.info_outline,
                  color: Colors.purpleAccent,
                  onTap: () => _showDisclaimerDialog(context),
                ),
              ],
            ),
          ),

          // 4. Dolny pasek narzędziowy: Ustawienia (niżej) + Wyjście z gry
          Positioned(
            left: 25,
            bottom: 15, // Trybik zjechał niżej, bliżej krawędzi ekranu
            child: Row(
              children: [
                IconButton(
                  icon: const Icon(
                    Icons.settings,
                    color: Colors.white54,
                    size: 36,
                  ),
                  onPressed: () {
                    showDialog(
                      context: context,
                      builder: (context) => const SettingsDialog(),
                    );
                  },
                ),
                const SizedBox(width: 15),
                IconButton(
                  icon: const Icon(
                    Icons.power_settings_new,
                    color: Colors.redAccent,
                    size: 36,
                  ),
                  tooltip: AppLoc.tr("Wyjdź z gry", "Exit game"),
                  onPressed: () {
                    // Twardy powrót do rzeczywistości - zamknięcie aplikacji do pulpitu
                    SystemNavigator.pop();
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNeonButton({
    required String text,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(15),
        child: Container(
          width: 320,
          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
          decoration: BoxDecoration(
            color: Colors.black54,
            border: Border.all(color: color, width: 2),
            borderRadius: BorderRadius.circular(15),
            boxShadow: [
              BoxShadow(
                color: color.withOpacity(0.4),
                blurRadius: 15,
                spreadRadius: 2,
              ),
            ],
          ),
          child: Row(
            children: [
              Icon(icon, color: color, size: 30),
              const SizedBox(width: 15),
              Expanded(
                child: Text(
                  text,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1.2,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // --- NOWOCZESNY SYSTEM WYBORU SCENARIUSZY ---
  void _showScenarioSelectionDialog(BuildContext context) {
    bool showNzkList =
        false; // Steruje tym, czy pokazujemy Kategorie czy Scenariusze NZK

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setStateDialog) {
          return Dialog(
            backgroundColor: Colors.transparent,
            child: Container(
              width: MediaQuery.of(context).size.width * 0.6,
              height: MediaQuery.of(context).size.height * 0.8,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.9),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: Colors.cyanAccent, width: 2),
                boxShadow: [
                  BoxShadow(
                    color: Colors.cyanAccent.withOpacity(0.3),
                    blurRadius: 15,
                  ),
                ],
              ),
              child: Column(
                children: [
                  // NAGŁÓWEK OKNA
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      if (showNzkList)
                        IconButton(
                          icon: const Icon(
                            Icons.arrow_back,
                            color: Colors.cyanAccent,
                          ),
                          onPressed: () =>
                              setStateDialog(() => showNzkList = false),
                        )
                      else
                        const Icon(Icons.list_alt, color: Colors.cyanAccent),

                      Text(
                        showNzkList
                            ? AppLoc.tr(
                                "SCENARIUSZE: NZK",
                                "SCENARIOS: CARDIAC ARREST",
                              )
                            : AppLoc.tr(
                                "KATEGORIE KLINICZNE",
                                "CLINICAL CATEGORIES",
                              ),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),

                      IconButton(
                        icon: const Icon(Icons.close, color: Colors.redAccent),
                        onPressed: () => Navigator.pop(ctx),
                      ),
                    ],
                  ),
                  const Divider(color: Colors.cyanAccent),

                  // ZAWARTOŚĆ
                  Expanded(
                    child: showNzkList
                        ? _buildNzkScenariosList(context, ctx)
                        : _buildCategoriesList(() {
                            setStateDialog(() {
                              showNzkList = true;
                            });
                          }),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  // LISTA KATEGORII
  Widget _buildCategoriesList(VoidCallback onNzkSelected) {
    return ListView(
      children: [
        _buildCategoryCard(
          title: AppLoc.tr("NZK (Zatrzymanie Krążenia)", "Cardiac Arrest"),
          subtitle: AppLoc.tr(
            "VF, pVT, Asystolia, PEA, 4H4T",
            "VF, pVT, Asystole, PEA, 4H4T",
          ),
          icon: Icons.monitor_heart,
          color: Colors.redAccent,
          onTap: onNzkSelected, // <-- TUTAJ CZYSTY CALLBACK
        ),
        _buildCategoryCard(
          title: AppLoc.tr("Bradykardie", "Bradycardias"),
          subtitle: AppLoc.tr(
            "Elektrostymulacja, Atropina - W BUDOWIE",
            "Electrostimulation, Atropine - WIP",
          ),
          icon: Icons.trending_down,
          color: Colors.orangeAccent,
          onTap: () {},
          isWip: true,
        ),
        _buildCategoryCard(
          title: AppLoc.tr("Tachyarytmie", "Tachyarrhythmias"),
          subtitle: AppLoc.tr(
            "Kardiowersja, Adenozyna - W BUDOWIE",
            "Cardioversion, Adenosine - WIP",
          ),
          icon: Icons.trending_up,
          color: Colors.purpleAccent,
          onTap: () {},
          isWip: true,
        ),
        _buildCategoryCard(
          title: AppLoc.tr("Stany Specjalne", "Special Circumstances"),
          subtitle: AppLoc.tr(
            "Anafilaksja, Zawał STEMI - W BUDOWIE",
            "Anaphylaxis, STEMI - WIP",
          ),
          icon: Icons.star_border,
          color: Colors.greenAccent,
          onTap: () {},
          isWip: true,
        ),
      ],
    );
  }

  // LISTA KONKRETNYCH SCENARIUSZY NZK
  Widget _buildNzkScenariosList(
    BuildContext mainContext,
    BuildContext dialogContext,
  ) {
    final scenarios = ScenarioDatabase.getAllScenarios();

    return ListView.builder(
      itemCount: scenarios.length,
      itemBuilder: (context, index) {
        final scenario = scenarios[index];
        return Card(
          color: Colors.grey[900],
          margin: const EdgeInsets.only(bottom: 10),
          shape: RoundedRectangleBorder(
            side: const BorderSide(color: Colors.cyan, width: 1),
            borderRadius: BorderRadius.circular(10),
          ),
          child: ListTile(
            leading: const Icon(Icons.healing, color: Colors.cyanAccent),
            title: Text(
              scenario.title,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
            subtitle: Text(
              scenario.dispatchInfo,
              style: const TextStyle(color: Colors.grey, fontSize: 12),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            trailing: const Icon(Icons.play_arrow, color: Colors.greenAccent),
            onTap: () {
              Navigator.pop(dialogContext); // Zamknij dialog
              // Przenieś gracza do intro z wybranym scenariuszem!
              Navigator.of(mainContext).push(
                MaterialPageRoute(
                  builder: (_) =>
                      ScenarioIntroScreen(preselectedScenario: scenario),
                ),
              );
            },
          ),
        );
      },
    );
  }

  Widget _buildCategoryCard({
    required String title,
    required String subtitle,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
    bool isWip = false,
  }) {
    return Card(
      color: Colors.grey[900],
      margin: const EdgeInsets.only(bottom: 15),
      child: ListTile(
        leading: Icon(icon, color: color, size: 36),
        title: Text(
          title,
          style: TextStyle(
            color: isWip ? Colors.grey : Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 18,
          ),
        ),
        subtitle: Text(subtitle, style: const TextStyle(color: Colors.white54)),
        trailing: isWip
            ? const Icon(Icons.lock, color: Colors.white24)
            : const Icon(Icons.arrow_forward_ios, color: Colors.white),
        onTap: isWip ? null : onTap,
      ),
    );
  }

  void _showDisclaimerDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => Dialog(
        backgroundColor: Colors.transparent,
        child: Container(
          constraints: BoxConstraints(
            maxWidth:
                MediaQuery.of(context).size.width *
                0.75, // Zabezpieczenie szerokości dla Web/Tablet
            maxHeight:
                MediaQuery.of(context).size.height *
                0.85, // Zabezpieczenie przed overflow
          ),
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.black.withValues(
              alpha: 0.9,
            ), // Mroczne, lekko prześwitujące tło
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: Colors.purpleAccent, width: 2),
            boxShadow: [
              BoxShadow(
                color: Colors.purpleAccent.withValues(alpha: 0.3),
                blurRadius: 15,
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // NAGŁÓWEK
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Icon(
                    Icons.info_outline,
                    color: Colors.purpleAccent,
                    size: 28,
                  ),
                  Expanded(
                    child: Text(
                      AppLoc.tr("O APLIKACJI", "ABOUT THE APP"),
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, color: Colors.purpleAccent),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                    onPressed: () => Navigator.pop(ctx),
                  ),
                ],
              ),
              const Divider(color: Colors.purpleAccent),
              const SizedBox(height: 10),

              // TREŚĆ (SCROLLOWALNA)
              Expanded(
                child: SingleChildScrollView(
                  child: Text(
                    AppLoc.tr(
                      "Ta aplikacja powstała i ewoluuje z pomysłu, który narodził się podczas nauki. Powstała aby umożliwić interaktywne przypomnienie i przećwiczenie schematów ALS w każdym miejscu i o każdej porze.\n\nWszystkie scenariusze i algorytmy opierają się na wytycznych ERC oraz aktualnej wiedzy medycznej. Pamiętaj jednak, że ze względu na specyfikę gry mobilnej wprowadzone zostały pewne uproszczenia mechaniczne. Aplikacja ma charakter wyłącznie symulacyjno-edukacyjny oraz rozrywkowy. W żadnym wypadku nie zastępuje ona profesjonalnych kursów, certyfikowanych szkoleń ani oficjalnej literatury medycznej.\n\nTa aplikacja jest (i będzie) darmowa, pozbawiona reklam i mikropłatności. Jeśli uznasz ją za wartościową, podaj ją dalej.\n\nGra stale się rozwija, a w planach mam dodawanie kolejnych modułów (m.in. bradykardie i tachyarytmie). Jeśli zauważysz błąd logiczny, medyczny lub masz pomysł na nową mechanikę, możesz je przesłać na [tu wstawię adres email].",
                      "This application was created and evolves from an idea born during studies. It was created to enable interactive review and practice of ALS algorithms anywhere, anytime.\n\nAll scenarios and algorithms are based on ERC guidelines and current medical knowledge. Remember, however, that due to the nature of a mobile game, some mechanical simplifications have been introduced. The application is for simulation, educational, and entertainment purposes only. Under no circumstances does it replace professional courses, certified training, or official medical literature.\n\nThis application is (and will be) free, without ads or microtransactions. If you find it valuable, pass it on.\n\nThe game is constantly developing, and I plan to add more modules (e.g., bradycardias and tachyarrhythmias). If you notice a logical or medical error, or have an idea for a new mechanic, you can send them to [email will appear here].",
                    ),
                    style: const TextStyle(
                      color: Colors.white70,
                      fontSize: 14,
                      height:
                          1.4, // Zwiększenie odstępu między liniami dla czytelności
                    ),
                    textAlign: TextAlign.justify,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
