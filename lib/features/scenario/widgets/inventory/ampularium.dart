import 'package:flutter/material.dart';

class DrugInfo {
  final String name;
  final String concentration;
  final double amountPerMl;
  final String unit;
  final double maxVolume;
  final double step;

  DrugInfo(
    this.name,
    this.concentration,
    this.amountPerMl,
    this.unit,
    this.maxVolume,
    this.step,
  );
}

class AmpulariumDialog extends StatefulWidget {
  final Function(String drug, String dose) onDrugPrepared;

  const AmpulariumDialog({super.key, required this.onDrugPrepared});

  @override
  State<AmpulariumDialog> createState() => _AmpulariumDialogState();
}

class _AmpulariumDialogState extends State<AmpulariumDialog> {
  DrugInfo? _selectedDrug;
  double _selectedVolume = 0;
  String _selectedFlush = "Brak";

  final List<DrugInfo> _drugs = [
    DrugInfo("0.9% NaCl (Amp. 5ml)", "5 ml", 1.0, "ml", 5.0, 1.0),
    DrugInfo("0.9% NaCl (Amp. 10ml)", "10 ml", 1.0, "ml", 10.0, 1.0),
    DrugInfo("0.9% NaCl (Kroplówka)", "500 ml", 1.0, "ml", 500.0, 250.0),
    DrugInfo("5% Glukoza (Kroplówka)", "250 ml", 1.0, "ml", 250.0, 250.0),
    DrugInfo(
      "20% Glukoza",
      "10 ml",
      1.0,
      "ml",
      50.0,
      10.0,
    ), // Np. podajemy 5x10ml
    DrugInfo("Adenozyna", "6 mg / 2 ml", 3.0, "mg", 2.0, 1.0),
    DrugInfo("Adrenalina", "1 mg / 1 ml", 1.0, "mg", 5.0, 1.0),
    DrugInfo("Amiodaron", "150 mg / 3 ml", 50.0, "mg", 6.0, 3.0),
    DrugInfo("Atropina", "1 mg / 1 ml", 1.0, "mg", 3.0, 0.5),
    DrugInfo("Budezonid", "1 mg / 2 ml (Nebulizacja)", 0.5, "mg", 4.0, 2.0),
    DrugInfo(
      "Captopril",
      "25 mg (Tabletka)",
      25.0,
      "mg",
      2.0,
      0.5,
    ), // Suwak dla połowy
    DrugInfo("Clonazepam", "1 mg / 1 ml", 1.0, "mg", 2.0, 0.5),
    DrugInfo("Deksametazon", "8 mg / 2 ml", 4.0, "mg", 2.0, 1.0),
    DrugInfo("Diazepam", "10 mg / 2 ml", 5.0, "mg", 2.0, 1.0),
    DrugInfo("Drotaweryna", "40 mg / 2 ml", 20.0, "mg", 2.0, 1.0),
    DrugInfo("Fentanyl", "100 mcg / 2 ml", 50.0, "mcg", 2.0, 0.5),
    DrugInfo("Flumazenil", "0.5 mg / 5 ml", 0.1, "mg", 5.0, 1.0),
    DrugInfo("Furosemid", "20 mg / 2 ml", 10.0, "mg", 4.0, 2.0),
    DrugInfo("Glukagon", "1 mg / 1 ml", 1.0, "mg", 1.0, 1.0),
    DrugInfo("Heparyna", "25000 j.m. / 5 ml", 5000.0, "j.m.", 1.0, 0.2),
    DrugInfo("Hydrokortyzon", "100 mg (Fiolka proszek)", 100.0, "mg", 5.0, 1.0),
    DrugInfo("Hydroksyzyna", "100 mg / 2 ml", 50.0, "mg", 2.0, 1.0),
    DrugInfo("Ibuprofen", "400 mg (Tabletka)", 400.0, "mg", 2.0, 1.0),
    DrugInfo("Ketoprofen", "100 mg / 2 ml", 50.0, "mg", 2.0, 1.0),
    DrugInfo("Klemastyna", "2 mg / 2 ml", 1.0, "mg", 2.0, 1.0),
    DrugInfo("Klopidogrel", "300 mg (Tabletki)", 75.0, "mg", 4.0, 1.0),
    DrugInfo("Lidokaina", "2% / 2 ml", 20.0, "mg", 10.0, 1.0),
    DrugInfo("Mannitol", "20% / 250 ml", 1.0, "ml", 250.0, 250.0),
    DrugInfo("Metamizol", "2.5 g / 5 ml", 0.5, "g", 5.0, 2.0),
    DrugInfo("Metoklopramid", "10 mg / 2 ml", 5.0, "mg", 2.0, 2.0),
    DrugInfo("Metoprolol", "5 mg / 5 ml", 1.0, "mg", 5.0, 1.0),
    DrugInfo("Midazolam", "5 mg / 5 ml", 1.0, "mg", 5.0, 1.0),
    DrugInfo("Monoazotan izosorbidu", "20 mg (Tabletka)", 20.0, "mg", 1.0, 1.0),
    DrugInfo("Morfina", "10 mg / 1 ml", 10.0, "mg", 2.0, 0.1),
    DrugInfo("Nalokson", "400 mcg / 1 ml", 400.0, "mcg", 2.0, 0.5),
    DrugInfo("Nitrogliceryna", "Aerozol (Dawka 0.4mg)", 0.4, "mg", 3.0, 1.0),
    DrugInfo("Papaweryna", "40 mg / 2 ml", 20.0, "mg", 2.0, 1.0),
    DrugInfo(
      "Paracetamol",
      "1 g / 100 ml (Kroplówka)",
      10.0,
      "mg",
      100.0,
      100.0,
    ),
    DrugInfo(
      "Płyn Wieloelektrolitowy (PWE)",
      "Kroplówka 500 ml",
      1.0,
      "ml",
      500.0,
      250.0,
    ),
    DrugInfo("Roztwory Koloidowe", "Kroplówka 500 ml", 1.0, "ml", 500.0, 250.0),
    DrugInfo("Roztwór Ringera", "Kroplówka 500 ml", 1.0, "ml", 500.0, 250.0),
    DrugInfo("Salbutamol", "5 mg / 2.5 ml (Nebulizacja)", 2.0, "mg", 5.0, 2.5),
    DrugInfo("Siarczan magnezu", "20% / 10 ml", 0.2, "g", 10.0, 5.0),
    DrugInfo("Ticagrelor", "90 mg (Tabletka)", 90.0, "mg", 2.0, 1.0),
    DrugInfo("Tietylperazyna", "6.5 mg / 1 ml", 6.5, "mg", 1.0, 1.0),
    DrugInfo("Urapidyl", "50 mg / 10 ml", 5.0, "mg", 10.0, 2.0),
    DrugInfo("Wodorowęglan sodu", "8.4% / 50 ml", 1.0, "mEq", 50.0, 10.0),
  ];

  final List<String> _flushes = ["Brak", "0.9% NaCl", "5% Glukoza"];

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: Colors.grey[900],
      title: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          const Text(
            'Ampularium ZRM',
            style: TextStyle(color: Colors.blueAccent),
          ),
          IconButton(
            icon: const Icon(Icons.close, color: Colors.redAccent, size: 32),
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
            onPressed: () => Navigator.of(context).pop(),
          ),
        ],
      ),
      content: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              "1. Wybierz ampułkę/płyn:",
              style: TextStyle(color: Colors.grey),
            ),
            DropdownButton<DrugInfo>(
              isExpanded: true,
              dropdownColor: Colors.grey[850],
              value: _selectedDrug,
              hint: const Text(
                "Wybierz lek...",
                style: TextStyle(color: Colors.white54),
              ),
              items: _drugs.map((drug) {
                return DropdownMenuItem(
                  value: drug,
                  child: Text(
                    "${drug.name} (${drug.concentration})",
                    style: const TextStyle(color: Colors.white),
                  ),
                );
              }).toList(),
              onChanged: (val) {
                setState(() {
                  _selectedDrug = val;
                  _selectedVolume =
                      val!.step; // Domyślnie ustawiamy na pierwszy krok
                });
              },
            ),
            const SizedBox(height: 20),

            if (_selectedDrug != null) ...[
              const Text(
                "2. Pobierz objętość (Suwak):",
                style: TextStyle(color: Colors.grey),
              ),
              Slider(
                value: _selectedVolume,
                min: _selectedDrug!.step,
                max: _selectedDrug!.maxVolume,
                divisions:
                    ((_selectedDrug!.maxVolume - _selectedDrug!.step) /
                                _selectedDrug!.step)
                            .round() >
                        0
                    ? ((_selectedDrug!.maxVolume - _selectedDrug!.step) /
                              _selectedDrug!.step)
                          .round()
                    : 1,
                activeColor: Colors.blueAccent,
                label: "${_selectedVolume.toStringAsFixed(1)} ml",
                onChanged: (val) => setState(() => _selectedVolume = val),
              ),
              Center(
                child: Text(
                  "Zaciągnięto: ${_selectedVolume.toStringAsFixed(1)} ml\nDawka czynna: ${(_selectedVolume * _selectedDrug!.amountPerMl).toStringAsFixed(0)} ${_selectedDrug!.unit}",
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: Colors.yellow,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(height: 20),

              const Text(
                "3. Popitka / Rozpuszczalnik:",
                style: TextStyle(color: Colors.grey),
              ),
              DropdownButton<String>(
                isExpanded: true,
                dropdownColor: Colors.grey[850],
                value: _selectedFlush,
                items: _flushes
                    .map(
                      (flush) => DropdownMenuItem(
                        value: flush,
                        child: Text(
                          flush,
                          style: const TextStyle(color: Colors.white),
                        ),
                      ),
                    )
                    .toList(),
                onChanged: (val) => setState(() => _selectedFlush = val!),
              ),
              const SizedBox(height: 20),

              Center(
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red[800],
                    padding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 15,
                    ),
                  ),
                  icon: const Icon(Icons.vaccines, color: Colors.white),
                  label: const Text(
                    "PRZYGOTUJ STRZYKAWKĘ",
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  onPressed: () {
                    // Pakujemy dane w jeden string, np. "Adrenalina|1 mg|0.9% NaCl (Bolus 20ml)"
                    String doseStr =
                        "${(_selectedVolume * _selectedDrug!.amountPerMl).toStringAsFixed(0)} ${_selectedDrug!.unit}";
                    widget.onDrugPrepared(
                      _selectedDrug!.name,
                      "$doseStr|$_selectedFlush",
                    );
                    Navigator.of(context).pop();
                  },
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
