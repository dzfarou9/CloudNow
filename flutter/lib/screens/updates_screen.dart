import 'package:flutter/material.dart';

import '../theme/opennow_theme.dart';

/// Mirrors DesktopUpdatePanel.qml / DesktopUpdateHeadline.qml states.
class UpdatesScreen extends StatelessWidget {
  const UpdatesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final colors = OpenNowColors.of(context);
    return ListView(
      padding: const EdgeInsets.all(24),
      children: [
        Card(
          color: colors.surface,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'UP TO DATE',
                  style: Theme.of(context).textTheme.displaySmall,
                ),
                const SizedBox(height: 8),
                Text(
                  'OpenNOW checks for nightly packages on launch. Update channels and release notes are owned by opennow-core.',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
                const SizedBox(height: 16),
                FilledButton(
                  onPressed: () {},
                  child: const Text('Check for updates'),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
