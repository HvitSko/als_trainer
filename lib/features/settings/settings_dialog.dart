import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'settings_manager.dart';
import '../../../app_localization.dart';

class SettingsDialog extends StatelessWidget {
  const SettingsDialog({super.key});

  @override
  Widget build(BuildContext context) {
    // Nasłuchujemy ustawień, żeby przełączniki (Switche) reagowały na żywo
    final settings = context.watch<SettingsManager>();

    return AlertDialog(
      backgroundColor: Colors.black87,
      shape: RoundedRectangleBorder(
        side: const BorderSide(color: Colors.cyanAccent, width: 2),
        borderRadius: BorderRadius.circular(15),
      ),
      title: Row(
        children: [
          const Icon(Icons.settings, color: Colors.cyanAccent),
          const SizedBox(width: 10),
          Text(
            AppLoc.tr("USTAWIENIA", "SETTINGS"),
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ListTile(
            leading: Text(
              settings.isEnglish ? "🇬🇧" : "🇵🇱",
              style: const TextStyle(fontSize: 28),
            ),
            title: Text(
              AppLoc.tr("Język (Language)", "Language (Język)"),
              style: const TextStyle(color: Colors.white),
            ),
            trailing: Switch(
              activeColor: Colors.blueAccent,
              value: settings.isEnglish,
              onChanged: (val) => settings.toggleLanguage(),
            ),
          ),
          ListTile(
            leading: Icon(
              settings.isSoundOn ? Icons.volume_up : Icons.volume_off,
              color: Colors.pinkAccent,
            ),
            title: Text(
              AppLoc.tr("Dźwięki i Haptyka", "Sounds & Haptics"),
              style: const TextStyle(color: Colors.white),
            ),
            trailing: Switch(
              activeColor: Colors.pinkAccent,
              value: settings.isSoundOn,
              onChanged: (val) => settings.toggleSound(),
            ),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text(
            AppLoc.tr("ZAMKNIJ", "CLOSE"),
            style: const TextStyle(color: Colors.grey),
          ),
        ),
      ],
    );
  }
}
