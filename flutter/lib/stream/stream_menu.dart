import 'package:flutter/material.dart';

import '../state/shell_scope.dart';

/// Port of `DesktopInStreamMenu.qml`: left drawer above the same video surface.
class StreamMenu extends StatelessWidget {
  const StreamMenu({super.key, required this.onClose});

  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) {
    final store = ShellScope.of(context);
    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        width: 320,
        margin: const EdgeInsets.fromLTRB(14, 14, 0, 14),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: const Color(0xF00E1018),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: const Color(0x24FFFFFF)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                const Icon(Icons.sports_esports, color: Colors.white),
                const SizedBox(width: 10),
                Text(
                  'IN GAME',
                  style: Theme.of(context).textTheme.labelSmall
                      ?.copyWith(color: Colors.white),
                ),
                const Spacer(),
                IconButton(
                  onPressed: onClose,
                  icon: const Icon(Icons.close, color: Colors.white),
                ),
              ],
            ),
            const Divider(color: Color(0x24FFFFFF)),
            _menuTile(Icons.sports_esports, 'Controllers', () {}),
            _menuTile(Icons.group_add, 'Invite a friend', () {}),
            _menuTile(Icons.mic_none, 'Microphone  Ctrl+Shift+M', () {}),
            _menuTile(Icons.bar_chart, 'Statistics  Ctrl+N', () {}),
            _menuTile(Icons.fullscreen, 'Fullscreen  F11', () {}),
            const Divider(color: Color(0x24FFFFFF)),
            _menuTile(
              Icons.logout,
              'End session  Ctrl+Shift+Q',
              () => _confirmEnd(context, store),
              danger: true,
            ),
          ],
        ),
      ),
    );
  }

  Widget _menuTile(
    IconData icon,
    String label,
    VoidCallback onTap, {
    bool danger = false,
  }) => ListTile(
    leading: Icon(icon, color: danger ? const Color(0xFFFF8A80) : Colors.white),
    title: Text(
      label,
      style: TextStyle(
        color: danger ? const Color(0xFFFF8A80) : Colors.white,
        fontSize: 13,
      ),
    ),
    onTap: onTap,
  );

  void _confirmEnd(BuildContext context, dynamic store) {
    showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('End session?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Keep playing'),
          ),
          FilledButton(
            onPressed: () {
              Navigator.pop(context);
              onClose();
              store.stopSession();
            },
            child: const Text('End session'),
          ),
        ],
      ),
    );
  }
}
