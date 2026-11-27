import 'package:flutter/material.dart';

import '../core/models.dart';
import '../state/shell_store.dart';

/// Flutter counterpart of `DesktopGameModal.qml`: game details with readiness
/// notice, feature labels and the Play action. Game details stay modal so the
/// underlying route is preserved, like the desktop shell.
void showGameModal(BuildContext context, ShellStore store, Game game) {
  showDialog<void>(
    context: context,
    builder: (context) => AlertDialog(
      title: Text(game.name),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (game.genre != null) Text('Genre: ${game.genre}'),
          if (game.developer != null) Text('Developer: ${game.developer}'),
          const SizedBox(height: 12),
          Wrap(
            spacing: 6,
            children: const [
              Chip(label: Text('RTX')),
              Chip(label: Text('DLSS')),
              Chip(label: Text('HDR')),
            ],
          ),
          if (store.error != null) ...[
            const SizedBox(height: 12),
            Text(
              store.error!,
              style: TextStyle(color: Theme.of(context).colorScheme.error),
            ),
          ],
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Close'),
        ),
        FilledButton.icon(
          onPressed: () {
            Navigator.of(context).pop();
            store.launch(game);
          },
          icon: const Icon(Icons.play_arrow),
          label: const Text('Play'),
        ),
      ],
    ),
  );
}
