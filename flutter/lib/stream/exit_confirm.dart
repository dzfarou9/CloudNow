import 'package:flutter/material.dart';

import '../theme/opennow_theme.dart';

/// Port of `DesktopStreamExitConfirm.qml`. Dismissing the dialog must not
/// disturb media, so it only calls onKeepPlaying and leaves the surface alone.
class StreamExitConfirm extends StatelessWidget {
  const StreamExitConfirm({
    super.key,
    required this.onKeepPlaying,
    required this.onEndSession,
  });

  final VoidCallback onKeepPlaying;
  final VoidCallback onEndSession;

  @override
  Widget build(BuildContext context) {
    final colors = OpenNowColors.of(context);
    return AlertDialog(
      backgroundColor: colors.shell,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      title: const Text('End this session?'),
      content: const Text(
        'Your game will close and you will return to the OpenNOW library.',
      ),
      actions: [
        TextButton(onPressed: onKeepPlaying, child: const Text('Keep playing')),
        FilledButton(
          style: FilledButton.styleFrom(
            backgroundColor: colors.danger,
            foregroundColor: colors.label,
          ),
          onPressed: onEndSession,
          child: const Text('End session'),
        ),
      ],
    );
  }
}
