import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'app.dart';
import 'core/opennow_bridge.dart';
import 'state/shell_store.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.landscapeLeft,
    DeviceOrientation.landscapeRight,
  ]);

  final bridge = MethodChannelOpenNowBridge();
  bridge.startListening();
  final store = ShellStore(bridge: bridge, stream: bridge.stream);

  runApp(OpenNowApp(store: store));
  // The shell renders immediately; core responses (or the demo fallback) fill
  // it in once the Rust bridge answers the handshake.
  await store.initialize();
}
