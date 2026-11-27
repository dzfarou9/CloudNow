import 'package:flutter/material.dart';

import '../state/shell_scope.dart';
import '../state/shell_store.dart';
import '../theme/opennow_theme.dart';
import '../theme/palette.dart';

/// Port of `DesktopSettingsScreen.qml`: searchable group nav plus one page per
/// category. Appearance is wired end-to-end to the bridge; the remaining pages
/// list the desktop's settings keys so the tree stays visible while the core
/// library work is pending.
class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  int _group = 0;
  final _search = TextEditingController();

  static const groups = [
    'Stream',
    'Network',
    'Audio',
    'Controls',
    'Recording',
    'Appearance',
    'Console mode',
    'Account',
    'Updates',
    'About & support',
  ];

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final store = ShellScope.of(context);
    return Row(
      children: [
        SizedBox(
          width: 220,
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(12),
                child: TextField(
                  controller: _search,
                  decoration: const InputDecoration(
                    hintText: 'Search settings',
                    prefixIcon: Icon(Icons.search, size: 18),
                    isDense: true,
                  ),
                  onChanged: (_) => setState(() {}),
                ),
              ),
              Expanded(
                child: ListView.builder(
                  itemCount: groups.length,
                  itemBuilder: (context, index) => ListTile(
                    selected: _group == index,
                    selectedTileColor: OpenNowColors.of(context).raised,
                    title: Text(groups[index]),
                    onTap: () => setState(() => _group = index),
                  ),
                ),
              ),
            ],
          ),
        ),
        const VerticalDivider(width: 1),
        Expanded(
          child: _group == 5
              ? _AppearancePage(store: store)
              : _GenericPage(group: groups[_group], store: store),
        ),
      ],
    );
  }
}

class _AppearancePage extends StatelessWidget {
  const _AppearancePage({required this.store});

  final ShellStore store;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(24),
      children: [
        Text('THEME PACK', style: Theme.of(context).textTheme.labelSmall),
        const SizedBox(height: 10),
        Wrap(
          spacing: 10,
          runSpacing: 10,
          children: [
            for (final pack in themePacks)
              ChoiceChip(
                label: Text('${pack.name} · ${pack.detail}'),
                selected: store.themePackId == pack.id,
                onSelected: (_) => store.setSetting('themePack', pack.id),
              ),
          ],
        ),
        const SizedBox(height: 24),
        _SettingRow(
          label: 'Appearance',
          value: store.themeMode,
          onChanged: (value) => store.setSetting('appTheme', value),
          choices: const ['auto', 'light', 'dark'],
        ),
        _SettingRow(
          label: 'Accent',
          value: store.accent,
          onChanged: (value) {
            store.setSetting('appAccentColor', value);
            store.setSetting('themeAccentOverride', true);
          },
          choices: accentChoices,
        ),
        SwitchListTile(
          title: const Text('Translucent UI'),
          value: store.translucent,
          onChanged: (value) => store.setSetting('translucentUI', value),
        ),
      ],
    );
  }
}

class _SettingRow extends StatelessWidget {
  const _SettingRow({
    required this.label,
    required this.value,
    required this.choices,
    required this.onChanged,
  });

  final String label;
  final String value;
  final List<String> choices;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 6),
    child: Row(
      children: [
        SizedBox(width: 140, child: Text(label)),
        DropdownButton<String>(
          value: choices.contains(value) ? value : choices.first,
          items: [
            for (final choice in choices)
              DropdownMenuItem(value: choice, child: Text(choice)),
          ],
          onChanged: (next) {
            if (next != null) onChanged(next);
          },
        ),
      ],
    ),
  );
}

class _GenericPage extends StatelessWidget {
  const _GenericPage({required this.group, required this.store});

  final String group;
  final ShellStore store;

  @override
  Widget build(BuildContext context) {
    final keys = _keysFor(group);
    return ListView(
      padding: const EdgeInsets.all(24),
      children: [
        Text(
          group.toUpperCase(),
          style: Theme.of(context).textTheme.displaySmall,
        ),
        const SizedBox(height: 16),
        for (final key in keys)
          ListTile(
            title: Text(key),
            subtitle: const Text('Owned by opennow-core · settings.set'),
          ),
      ],
    );
  }

  static List<String> _keysFor(String group) => switch (group) {
    'Stream' => [
      'videoBackend',
      'resolution',
      'frameRate',
      'bitrate',
      'hdr',
      'dlssOverrides',
    ],
    'Network' => ['region', 'proxy', 'queueServer', 'networkTest'],
    'Audio' => ['audioOutputDevice', 'microphoneMode', 'volume'],
    'Controls' => ['keyboardLayout', 'controllerDeadzone', 'shortcutBindings'],
    'Recording' => ['replayEnabled', 'recordingPath', 'statsFields'],
    'Console mode' => ['consoleMode', 'consoleUiScale', 'consoleProfile'],
    'Account' => ['startAsLastUsedAccount', 'membership', 'linkedStores'],
    'Updates' => ['updateChannel', 'automaticUpdates', 'releaseNotes'],
    _ => ['version', 'diagnostics', 'legal', 'feedback'],
  };
}
