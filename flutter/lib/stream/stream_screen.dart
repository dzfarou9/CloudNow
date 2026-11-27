import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../core/opennow_bridge.dart';
import '../state/shell_scope.dart';
import 'exit_confirm.dart';
import 'stream_menu.dart';
import 'stream_stats.dart';

/// Counterpart of `DesktopStreamScreen.qml`. The Texture widget is created
/// once and kept alive for the whole session: F3 stats, Ctrl+G menus and exit
/// confirmations are stacked above it, never replacing the video surface.
class StreamScreen extends StatefulWidget {
  const StreamScreen({super.key});

  @override
  State<StreamScreen> createState() => _StreamScreenState();
}

class _StreamScreenState extends State<StreamScreen> {
  final FocusNode _focus = FocusNode();
  late OpenNowStreamBridge _stream;
  int? _textureId;
  bool _menuOpen = false;
  bool _statsOpen = false;
  bool _confirmExit = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _stream = _stream;
    _createSurface();
    _focus.requestFocus();
  }

  Future<void> _createSurface() async {
    final stream = _stream;
    try {
      final id = await stream.createTexture();
      if (mounted) setState(() => _textureId = id);
    } on PlatformException catch (error) {
      if (mounted) setState(() => _error = error.message);
    }
  }

  @override
  void dispose() {
    _focus.dispose();
    _stream.releaseTexture();
    super.dispose();
  }

  KeyEventResult _onKeyEvent(FocusNode node, KeyEvent event) {
    // Local shortcuts are consumed before gameplay keys are forwarded.
    if (event is KeyDownEvent || event is KeyRepeatEvent) {
      if (event.logicalKey == LogicalKeyboardKey.f11) {
        _toggleFullscreen();
        return KeyEventResult.handled;
      }
      if (event.logicalKey == LogicalKeyboardKey.f3 ||
          (event.logicalKey == LogicalKeyboardKey.keyN &&
              HardwareKeyboard.instance.isControlPressed)) {
        setState(() => _statsOpen = !_statsOpen);
        return KeyEventResult.handled;
      }
      if (event.logicalKey == LogicalKeyboardKey.keyG &&
          HardwareKeyboard.instance.isControlPressed) {
        setState(() => _menuOpen = !_menuOpen);
        return KeyEventResult.handled;
      }
      if (event.logicalKey == LogicalKeyboardKey.escape) {
        // Escape is a gameplay key: show the exit confirmation, but do not
        // swallow it if the user chooses to keep playing.
        setState(() => _confirmExit = true);
        return KeyEventResult.handled;
      }
      _stream.submitKey(
        event.logicalKey.keyId,
        event is KeyRepeatEvent ? 2 : 1,
        _modifiers(),
      );
    }
    if (event is KeyUpEvent) {
      _stream.submitKey(event.logicalKey.keyId, 0, _modifiers());
    }
    return KeyEventResult.handled;
  }

  int _modifiers() {
    final keyboard = HardwareKeyboard.instance;
    var value = 0;
    if (keyboard.isControlPressed) value |= 1;
    if (keyboard.isShiftPressed) value |= 2;
    if (keyboard.isAltPressed) value |= 4;
    if (keyboard.isMetaPressed) value |= 8;
    return value;
  }

  void _toggleFullscreen() {
    // Fullscreen/display-size changes are coordinate-space changes. The native
    // side must recompute pointer mapping from the current viewport.
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Focus(
      focusNode: _focus,
      onKeyEvent: _onKeyEvent,
      child: Scaffold(
        backgroundColor: Colors.black,
        body: Stack(
          fit: StackFit.expand,
          children: [
            if (_textureId != null)
              Texture(textureId: _textureId!)
            else
              Center(
                child: _error == null
                    ? const CircularProgressIndicator()
                    : Text(_error!, style: TextStyle(color: colors.error)),
              ),
            GestureDetector(
              onPanUpdate: (details) {
                _stream.submitMouse(details.delta.dx, details.delta.dy, 0);
              },
              child: const SizedBox.expand(),
            ),
            const Positioned(top: 24, right: 24, child: _SessionClock()),
            if (_statsOpen) const Positioned.fill(child: StreamStatsOverlay()),
            if (_menuOpen)
              StreamMenu(onClose: () => setState(() => _menuOpen = false)),
            if (_confirmExit)
              StreamExitConfirm(
                onKeepPlaying: () => setState(() => _confirmExit = false),
                onEndSession: () {
                  setState(() => _confirmExit = false);
                  ShellScope.of(context).stopSession();
                },
              ),
          ],
        ),
      ),
    );
  }
}

class _SessionClock extends StatefulWidget {
  const _SessionClock();

  @override
  State<_SessionClock> createState() => _SessionClockState();
}

class _SessionClockState extends State<_SessionClock> {
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
    decoration: BoxDecoration(
      color: const Color(0xB3000000),
      borderRadius: BorderRadius.circular(18),
    ),
    child: Text(
      '00:00:00',
      style: Theme.of(context).textTheme.labelSmall
          ?.copyWith(color: Colors.white),
    ),
  );
}
