import 'package:flutter/material.dart';
import '../../logic/game_engine.dart';

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
                // GÓRNA BELKA (TYTUŁ I ZAMYKACZ)
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Diagnostyka 4H4T',
                      style: TextStyle(
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

                // TWÓJ STARY, ZŁOTY KOD OPAKOWANY BEZPIECZNIE
                Flexible(
                  child: SingleChildScrollView(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Text(
                          '4H (Długie naciśnięcie ocenia)',
                          style: TextStyle(color: Colors.blueAccent),
                        ),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: hCauses
                              .map((cause) => _buildChip(cause, state))
                              .toList(),
                        ),
                        const SizedBox(height: 20),
                        const Text(
                          '4T (Długie naciśnięcie ocenia)',
                          style: TextStyle(color: Colors.redAccent),
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

    return GestureDetector(
      onLongPress: () => _showEvaluationDialog(context, cause),
      child: ActionChip(
        label: Text(cause, style: const TextStyle(color: Colors.white)),
        backgroundColor: bgColor,
        onPressed: () => widget.engine.considerCause(cause),
      ),
    );
  }

  void _showEvaluationDialog(BuildContext context, String cause) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Colors.grey[900],
        title: Text(
          "Ocena: $cause",
          style: const TextStyle(color: Colors.orangeAccent),
        ),
        content: const Text(
          "Czy podjęto interwencje diagnostyczno-lecznicze, aby odhaczyć ten problem?",
          style: TextStyle(color: Colors.white),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text("NIE"),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
            onPressed: () {
              Navigator.pop(ctx);
              widget.engine.evaluate4H4TCause(cause);
            },
            child: const Text("TAK, Wykluczone/Zabezpieczone"),
          ),
        ],
      ),
    );
  }
}
