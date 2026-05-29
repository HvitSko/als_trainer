import 'package:flutter/material.dart';
import '../../logic/game_engine.dart';
import '../../../../app_localization.dart'; // IMPORT TŁUMACZA

class H4TDialog extends StatefulWidget {
  final GameEngine engine;
  const H4TDialog({super.key, required this.engine});

  @override
  State<H4TDialog> createState() => _H4TDialogState();
}

class _H4TDialogState extends State<H4TDialog> {
  final List<String> hCauses = [
    "Hipoksja",
    "Hipowolemia",
    "Hipo/Hiperkaliemia",
    "Hipotermia",
  ];
  final List<String> tCauses = [
    "Tamponada",
    "Toxins (Zatrucia)",
    "Tension pneumothorax (Odma)",
    "Thrombosis (Zator)",
  ];

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: widget.engine,
      builder: (context, _) {
        final state = widget.engine.state;
        return Dialog(
          backgroundColor: Colors.transparent,
          insetPadding: const EdgeInsets.all(16),
          child: Container(
            constraints: BoxConstraints(
              maxWidth: MediaQuery.of(context).size.width * 0.55,
            ),
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.black87,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: Colors.purpleAccent, width: 2),
              boxShadow: const [
                BoxShadow(
                  color: Colors.purpleAccent,
                  blurRadius: 15,
                  spreadRadius: -5,
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      AppLoc.tr('Diagnostyka 4H4T', '4H4T Diagnostics'),
                      style: const TextStyle(
                        color: Colors.purpleAccent,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close, color: Colors.red),
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                      onPressed: () => Navigator.of(context).pop(),
                    ),
                  ],
                ),
                const Divider(
                  color: Colors.purpleAccent,
                  height: 20,
                  thickness: 1,
                ),

                Flexible(
                  child: SingleChildScrollView(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          AppLoc.tr(
                            '4H (Długie naciśnięcie ocenia)',
                            '4H (Long press to evaluate)',
                          ),
                          style: const TextStyle(color: Colors.blueAccent),
                        ),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: hCauses
                              .map((cause) => _buildChip(cause, state))
                              .toList(),
                        ),
                        const SizedBox(height: 20),
                        Text(
                          AppLoc.tr(
                            '4T (Długie naciśnięcie ocenia)',
                            '4T (Long press to evaluate)',
                          ),
                          style: const TextStyle(color: Colors.redAccent),
                        ),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: tCauses
                              .map((cause) => _buildChip(cause, state))
                              .toList(),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildChip(String cause, var state) {
    int status = state.h4tStatus[cause] ?? 0;
    Color bgColor = Colors.grey[800]!;
    if (status == 1) bgColor = Colors.green[800]!;
    if (status == -1) bgColor = Colors.redAccent;

    // MAGIA TŁUMACZA DO WIDOKU ENUMÓW (Wysyłamy do silnika polską nazwę bazową, żeby logika działała, ale w UI widzimy język)
    String displayCause = cause;
    if (AppLoc.isEn) {
      if (cause == "Hipoksja") displayCause = "Hypoxia";
      if (cause == "Hipowolemia") displayCause = "Hypovolemia";
      if (cause == "Hipo/Hiperkaliemia") displayCause = "Hypo/Hyperkalemia";
      if (cause == "Hipotermia") displayCause = "Hypothermia";
      if (cause == "Tamponada") displayCause = "Tamponade";
      if (cause == "Toxins (Zatrucia)") displayCause = "Toxins";
      if (cause == "Tension pneumothorax (Odma)")
        displayCause = "Tension Pneumothorax";
      if (cause == "Thrombosis (Zator)") displayCause = "Thrombosis (PE)";
    }

    bool isDominant = state.identifiedDominantCause == cause;

    return GestureDetector(
      onLongPress: () => _showEvaluationDialog(context, cause, displayCause),
      child: Container(
        decoration: isDominant
            ? BoxDecoration(
                border: Border.all(color: Colors.amberAccent, width: 2),
                borderRadius: BorderRadius.circular(20),
                boxShadow: const [
                  BoxShadow(
                    color: Colors.amber,
                    blurRadius: 8,
                    spreadRadius: -2,
                  ),
                ],
              )
            : null,
        child: ActionChip(
          label: Text(
            displayCause,
            style: const TextStyle(color: Colors.white),
          ),
          backgroundColor: bgColor,
          onPressed: () => widget.engine.considerCause(cause),
        ),
      ),
    );
  }

  void _showEvaluationDialog(
    BuildContext context,
    String cause,
    String displayCause,
  ) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Colors.grey[900],
        title: Text(
          "${AppLoc.tr('Ocena: ', 'Evaluate: ')}$displayCause",
          style: const TextStyle(color: Colors.orangeAccent),
        ),
        content: Text(
          AppLoc.tr(
            "Czy podjęto interwencje diagnostyczno-lecznicze, aby odhaczyć ten problem?",
            "Have diagnostic and therapeutic interventions been taken to clear this problem?",
          ),
          style: const TextStyle(color: Colors.white),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(AppLoc.tr("Anuluj", "Cancel")),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.blueAccent),
            onPressed: () {
              Navigator.pop(ctx);
              widget.engine.identifyDominantCause(cause);
            },
            child: Text(
              AppLoc.tr("DOMINUJĄCA", "DOMINANT"),
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
            onPressed: () {
              Navigator.pop(ctx);
              widget.engine.evaluate4H4TCause(cause);
            },
            child: Text(
              AppLoc.tr("Wykluczone/Rozpoznane", "Excluded/Recognized"),
            ),
          ),
        ],
      ),
    );
  }
}
