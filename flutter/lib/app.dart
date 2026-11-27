import 'package:flutter/material.dart';

import 'shell/shell_screen.dart';
import 'state/shell_scope.dart';
import 'state/shell_store.dart';
import 'theme/opennow_theme.dart';
import 'theme/palette.dart';

class OpenNowApp extends StatelessWidget {
  const OpenNowApp({super.key, required this.store});

  final ShellStore store;

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: store,
      builder: (context, _) {
        final pack = packById(store.themePackId);
        final platformBrightness = MediaQuery.platformBrightnessOf(context);
        final light =
            store.themeMode == 'light' ||
            (store.themeMode == 'auto' &&
                platformBrightness == Brightness.light);

        return MaterialApp(
          title: 'OpenNOW',
          debugShowCheckedModeBanner: false,
          theme: openNowThemeData(
            pack: pack,
            light: light,
            accent: store.accent,
            accentOverridden: store.accentOverridden,
            translucent: store.translucent,
          ),
          home: ShellScope(store: store, child: const ShellScreen()),
        );
      },
    );
  }
}
