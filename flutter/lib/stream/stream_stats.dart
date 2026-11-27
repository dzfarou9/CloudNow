import 'package:flutter/material.dart';

import '../state/shell_scope.dart';
import '../state/shell_store.dart';

/// Port of `DesktopStreamStats.qml`: the stage-by-stage diagnostics contract.
/// Audio continuing does not prove video health, so each stage is listed
/// separately instead of showing one generic "connected" indicator.
class StreamStatsOverlay extends StatelessWidget {
  const StreamStatsOverlay({super.key});

  @override
  Widget build(BuildContext context) {
    final store = ShellScope.of(context);
    return Align(
      alignment: Alignment.topLeft,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 320),
          child: Card(
            color: const Color(0xE6000E10),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'STREAM STATISTICS',
                    style: Theme.of(context).textTheme.labelSmall
                        ?.copyWith(color: Colors.white),
                  ),
                  const SizedBox(height: 10),
                  for (final entry in _rows(store))
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 3),
                      child: Row(
                        children: [
                          SizedBox(
                            width: 120,
                            child: Text(
                              entry.$1,
                              style: const TextStyle(
                                color: Color(0xFFA0AAB8),
                                fontSize: 11,
                              ),
                            ),
                          ),
                          Text(
                            entry.$2,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 11,
                            ),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  List<(String, String)> _rows(ShellStore store) {
    final diagnostics = store.diagnostics;
    return [
      ('Stage', diagnostics.stage),
      ('Receive', diagnostics.receive),
      ('Assembly', diagnostics.assembly),
      ('Decode', diagnostics.decode),
      ('Presentation', diagnostics.presentation),
      ('Feedback', diagnostics.feedback),
    ];
  }
}
