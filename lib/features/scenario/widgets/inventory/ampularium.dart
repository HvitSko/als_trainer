import 'package:flutter/material.dart';

class AmpulariumDialog extends StatefulWidget {
  // Tu leżał błąd! Teraz Ampularium oczekuje onDrugPrepared z dwiema wartościami.
  final Function(String drug, String dose) onDrugPrepared;

  const AmpulariumDialog({super.key, required this.onDrugPrepared});

  @override
  State<AmpulariumDialog> createState() => _AmpulariumDialogState();
}

class _AmpulariumDialogState extends State<AmpulariumDialog> {
  String? selectedDrug;

  final Map<String, List<String>> drugDatabase = {
    'Adenozyna': ['6 mg', '12 mg', '18 mg'],
    'Adrenalina': ['1 mg', '0.5 mg', '0.3 mg'],
    'Amiodaron': ['300 mg', '150 mg'],
    'Atropina': ['1 mg', '0.5 mg'],
    'Budezonid': ['1 mg', '2 mg'],
    'Captopril': ['12.5 mg', '25 mg'],
    'Chlorek Sodu 0,9%': ['10 ml', '100 ml', '250 ml', '500 ml'],
    'Clonazepam': ['1 mg'],
    'Deksametazon': ['4 mg', '8 mg'],
    'Diazepam': ['5 mg', '10 mg'],
    'Drotaweryna': ['40 mg'],
    'Fentanyl': ['0.1 mg', '0.05 mg'],
    'Flumazenil': ['0.5 mg'],
    'Furosemid': ['20 mg', '40 mg'],
    'Glukagon': ['1 mg'],
    'Glukoza 5%': ['250 ml'],
    'Glukoza 20%': ['10 ml', '50 ml'],
    'Heparyna': ['5000 j.m.'],
    'Hydrokortyzon': ['100 mg'],
    'Hydroksyzyna': ['100 mg'],
    'Ibuprofen': ['200 mg', '400 mg'],
    'Ketoprofen': ['100 mg'],
    'Klemastyna': ['2 mg'],
    'Klopidogrel': ['300 mg', '600 mg'],
    'Lidokaina': ['100 mg'],
    'Mannitol': ['100 ml'],
    'Metamizol': ['1 g', '2.5 g'],
    'Metoklopramid': ['10 mg'],
    'Metoprolol': ['5 mg'],
    'Midazolam': ['2 mg', '5 mg', '10 mg'],
    'Monoazotan Izosorbidu': ['20 mg'],
    'Morfina': ['10 mg', '5 mg'],
    'Nalokson': ['0.4 mg'],
    'Nitrogliceryna': ['0.4 mg (aerozol)', '5 mg (tabl)'],
    'Papaweryna': ['40 mg'],
    'Paracetamol': ['500 mg', '1 g'],
    'Płyn wieloelektrolitowy (PWE)': ['500 ml'],
    'Roztwory koloidowe': ['500 ml'],
    'Roztwór Ringera': ['500 ml'],
    'Salbutamol': ['2.5 mg', '5 mg'],
    'Siarczan Magnezu': ['2 g'],
    'Ticagrelor': ['180 mg'],
    'Tietylperazyna': ['6.5 mg'],
    'Tlen': ['15 l/min', '2-6 l/min'],
    'Urapidyl': ['25 mg', '50 mg'],
    'Wodorowęglan Sodu 8,4%': ['50 ml'],
  };

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(
        selectedDrug == null
            ? 'Wybierz lek'
            : 'Wybierz dawkę dla: $selectedDrug',
        style: const TextStyle(color: Colors.orange),
      ),
      backgroundColor: Colors.grey[900],
      content: SizedBox(
        width: double.maxFinite,
        height: 400,
        child: selectedDrug == null ? _buildDrugGrid() : _buildDoseList(),
      ),
    );
  }

  Widget _buildDrugGrid() {
    return GridView.builder(
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        childAspectRatio: 2.5,
        crossAxisSpacing: 8,
        mainAxisSpacing: 8,
      ),
      itemCount: drugDatabase.keys.length,
      itemBuilder: (context, index) {
        final drug = drugDatabase.keys.elementAt(index);
        return ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.blueGrey[900],
          ),
          onPressed: () => setState(() => selectedDrug = drug),
          child: Text(
            drug,
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 12),
          ),
        );
      },
    );
  }

  Widget _buildDoseList() {
    final doses = drugDatabase[selectedDrug!]!;
    return Column(
      children: [
        ...doses.map(
          (dose) => ListTile(
            title: Text(
              dose,
              style: const TextStyle(color: Colors.white, fontSize: 18),
            ),
            trailing: const Icon(Icons.add_circle_outline, color: Colors.green),
            onTap: () {
              widget.onDrugPrepared(selectedDrug!, dose);
              Navigator.pop(context);
            },
          ),
        ),
        const Spacer(),
        TextButton(
          onPressed: () => setState(() => selectedDrug = null),
          child: const Text(
            '<- Powrót do leków',
            style: TextStyle(color: Colors.white),
          ),
        ),
      ],
    );
  }
}
