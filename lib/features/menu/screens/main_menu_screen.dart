import 'package:flutter/material.dart';
import '../../scenario/screens/scenario_intro_screen.dart';
import '../../scenario/models/scenario_database.dart';
import '../../scenario/models/scenario_model.dart';
import '../../settings/settings_dialog.dart';
import '../../../app_localization.dart';
import 'package:flutter/services.dart';

class MainMenuScreen extends StatelessWidget {
  const MainMenuScreen({super.key});

  @override
  Widget build(BuildContext context) {
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
                  colors: [Colors.black.withOpacity(0.95), Colors.transparent],
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
                  text: AppLoc.tr(
                    "Baza Wiedzy / O Aplikacji",
                    "Knowledge Base / About",
                  ),
                  icon: Icons.school,
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
          title: "NZK (Zatrzymanie Krążenia)",
          subtitle: "VF, pVT, Asystolia, PEA, 4H4T",
          icon: Icons.monitor_heart,
          color: Colors.redAccent,
          onTap: onNzkSelected, // <-- TUTAJ CZYSTY CALLBACK
        ),
        _buildCategoryCard(
          title: "Bradykardie",
          subtitle: "Pacing, Atropina - W BUDOWIE",
          icon: Icons.trending_down,
          color: Colors.orangeAccent,
          onTap: () {},
          isWip: true,
        ),
        _buildCategoryCard(
          title: "Tachyarytmie",
          subtitle: "Kardiowersja, Adenozyna - W BUDOWIE",
          icon: Icons.trending_up,
          color: Colors.purpleAccent,
          onTap: () {},
          isWip: true,
        ),
        _buildCategoryCard(
          title: "Stany Specjalne",
          subtitle: "Anafilaksja, Zawał STEMI - W BUDOWIE",
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
      builder: (ctx) => AlertDialog(
        backgroundColor: Colors.grey[900],
        title: const Text(
          "Disclaimer / Nota Prawna",
          style: TextStyle(color: Colors.purpleAccent),
        ),
        content: Text(
          AppLoc.tr(
            "Aplikacja 'ALS Trainer' ma charakter wyłącznie edukacyjny i symulacyjny. Nie zastępuje formalnego wykształcenia medycznego, ani wytycznych ERC. Oparto na silniku EBM (Skippy).",
            "The 'ALS Trainer' application is for educational and simulation purposes only. It does not replace formal medical education or ERC guidelines. Powered by EBM Engine (Skippy).",
          ),
          style: const TextStyle(color: Colors.white),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text(
              "OK",
              style: TextStyle(color: Colors.purpleAccent),
            ),
          ),
        ],
      ),
    );
  }
}
