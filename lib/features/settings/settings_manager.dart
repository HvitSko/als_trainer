import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SettingsManager extends ChangeNotifier {
  static late SharedPreferences _prefs;

  // Klucze w pamięci
  static const String _keyLanguage = 'language_is_english';
  static const String _keySound = 'sound_is_on';
  static const String _keyOnboarding = 'onboarding_completed';

  // Stany
  bool _isEnglish = false;
  bool _isSoundOn = true;
  bool _hasCompletedOnboarding = false;

  bool get isEnglish => _isEnglish;
  bool get isSoundOn => _isSoundOn;
  bool get hasCompletedOnboarding => _hasCompletedOnboarding;

  // Inicjalizacja (wywoływana raz przy starcie apki)
  static Future<SettingsManager> init() async {
    _prefs = await SharedPreferences.getInstance();
    final manager = SettingsManager();
    manager._loadSettings();
    return manager;
  }

  void _loadSettings() {
    _isEnglish = _prefs.getBool(_keyLanguage) ?? false;
    _isSoundOn = _prefs.getBool(_keySound) ?? true;
    _hasCompletedOnboarding = _prefs.getBool(_keyOnboarding) ?? false;
  }

  // Zmiana języka
  Future<void> toggleLanguage() async {
    _isEnglish = !_isEnglish;
    await _prefs.setBool(_keyLanguage, _isEnglish);
    notifyListeners(); // Powiadamia UI o zmianie!
  }

  // Zmiana dźwięku
  Future<void> toggleSound() async {
    _isSoundOn = !_isSoundOn;
    await _prefs.setBool(_keySound, _isSoundOn);
    notifyListeners();
  }

  // Oznaczenie, że gracz przeszedł pierwszy wybór języka
  Future<void> completeOnboarding() async {
    _hasCompletedOnboarding = true;
    await _prefs.setBool(_keyOnboarding, true);
    notifyListeners();
  }

  // Wymuszenie konkretnego języka (przydatne przy onboardingu)
  Future<void> setLanguage({required bool english}) async {
    _isEnglish = english;
    await _prefs.setBool(_keyLanguage, _isEnglish);
    notifyListeners();
  }
}
