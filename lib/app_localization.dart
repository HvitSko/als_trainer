class AppLoc {
  // Globalna flaga języka
  static bool isEn = false;

  // Główna funkcja tłumacząca
  static String tr(String pl, String en) {
    return isEn ? en : pl;
  }
}
