import 'package:flutter/foundation.dart';

import '../core/models.dart';
import '../core/opennow_bridge.dart';

/// Dart counterpart of `qml/state/ShellStore.qml`: a single owner for shell
/// navigation, session state and the feature responses routed from the core.
/// It is deliberately a ChangeNotifier rather than a new global singleton so
/// tests can construct isolated instances.
class ShellStore extends ChangeNotifier {
  ShellStore({
    required OpenNowBridge bridge,
    required OpenNowStreamBridge stream,
  })
    // ignore: prefer_initializing_formals
    : _bridge = bridge,
       // ignore: prefer_initializing_formals
       _stream = stream;

  final OpenNowBridge _bridge;
  final OpenNowStreamBridge _stream;

  int _destination = 0;
  Account? _account;
  List<Game> _library = const [];
  List<Game> _recent = const [];
  List<Game> _featured = const [];
  bool _busy = false;
  bool _demoMode = false;
  bool _streamActive = false;
  String? _error;
  StreamDiagnostics _diagnostics = const StreamDiagnostics();

  // Appearance settings mirror `ShellStore.settings` on the desktop side.
  String _themePackId = 'nocturne';
  String _themeMode = 'auto';
  String _accent = 'blue';
  bool _accentOverridden = false;
  bool _translucent = false;

  int get destination => _destination;
  Account? get account => _account;
  List<Game> get library => _library;
  List<Game> get recent => _recent;
  List<Game> get featured => _featured;
  bool get busy => _busy;
  bool get demoMode => _demoMode;
  bool get streamActive => _streamActive;
  String? get error => _error;
  StreamDiagnostics get diagnostics => _diagnostics;
  OpenNowStreamBridge get stream => _stream;

  String get themePackId => _themePackId;
  String get themeMode => _themeMode;
  String get accent => _accent;
  bool get accentOverridden => _accentOverridden;
  bool get translucent => _translucent;

  Future<void> initialize() async {
    _busy = true;
    _error = null;
    notifyListeners();

    try {
      await _bridge.request('core.hello', {
        'protocolVersion': 6,
        'shell': 'flutter-android',
        'shellVersion': '0.1.0',
      });
      await _refreshAccount();
      await _refreshCatalog();
    } on CoreRequestException catch (error) {
      // Until the core is exposed as a library the mobile shell runs against
      // local sample data so the UI can still be developed and reviewed.
      _demoMode = true;
      _error = error.message;
      _loadDemoData();
      debugPrint('Core unavailable, using demo data: $error');
    } finally {
      _busy = false;
      notifyListeners();
    }
  }

  Future<void> _refreshAccount() async {
    final result = await _bridge.request('auth.accounts.list');
    final accounts = (result['accounts'] as List<dynamic>?) ?? const [];
    if (accounts.isNotEmpty) {
      _account = Account.fromJson(accounts.first as Map<String, dynamic>);
    }
  }

  Future<void> _refreshCatalog() async {
    final result = await _bridge.request('catalog.library.list', {'limit': 40});
    final items = (result['games'] as List<dynamic>?) ?? const [];
    _library = items
        .map((item) => Game.fromJson(item as Map<String, dynamic>))
        .toList(growable: false);
  }

  void _loadDemoData() {
    _account = const Account(
      userId: 'demo',
      displayName: 'Demo player',
      membershipTier: MembershipTier.ultimate,
      providerName: 'NVIDIA',
    );
    _library = const [
      Game(
        id: 'demo-1',
        name: 'Cyberpunk 2077',
        genre: 'RPG',
        favorite: true,
        pinned: true,
      ),
      Game(id: 'demo-2', name: 'Hades II', genre: 'Roguelike', favorite: true),
      Game(id: 'demo-3', name: 'Forza Horizon 5', genre: 'Racing'),
      Game(id: 'demo-4', name: 'Baldur’s Gate 3', genre: 'RPG'),
      Game(id: 'demo-5', name: 'Counter-Strike 2', genre: 'FPS'),
      Game(id: 'demo-6', name: 'Stardew Valley', genre: 'Simulation'),
    ];
    _recent = _library.take(3).toList(growable: false);
    _featured = _library.skip(2).take(4).toList(growable: false);
  }

  void goTo(int index) {
    if (index == _destination) return;
    _destination = index;
    notifyListeners();
  }

  Future<void> launch(Game game) async {
    _error = null;
    _busy = true;
    notifyListeners();
    try {
      final decision = await _bridge.request('catalog.launch.inspect', {
        'appId': game.id,
        if (game.variantId != null) 'variantId': game.variantId,
      });
      final launch = LaunchDecision.fromJson(
        decision['decision'] as Map<String, dynamic>? ?? const {},
      );
      if (!launch.ready) {
        _error = launch.message.isEmpty
            ? 'This game is not ready to launch'
            : launch.message;
        return;
      }
      final session = await _bridge.request('session.create', {
        'appId': game.id,
        if (game.variantId != null) 'variantId': game.variantId,
      });
      await _startStream(session);
    } on CoreRequestException catch (error) {
      _error = error.message;
    } finally {
      _busy = false;
      notifyListeners();
    }
  }

  Future<void> _startStream(Map<String, dynamic> session) async {
    await _stream.start({
      'abiVersion': 18,
      'session': session,
      'video': {
        'codec': 'h264',
        'bitDepth': '8bit',
        'chroma': '420',
        'hdr': false,
      },
    });
    _streamActive = true;
    _diagnostics = const StreamDiagnostics(stage: 'pending_android_platform');
    notifyListeners();
  }

  Future<void> stopSession() async {
    await _stream.stop();
    _streamActive = false;
    _diagnostics = const StreamDiagnostics();
    notifyListeners();
  }

  Future<void> refreshDiagnostics() async {
    _diagnostics = StreamDiagnostics.fromJson(await _stream.diagnostics());
    notifyListeners();
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }

  Future<void> setSetting(String key, Object value) async {
    switch (key) {
      case 'themePack':
        _themePackId = '$value';
      case 'appTheme':
        _themeMode = '$value';
      case 'appAccentColor':
        _accent = '$value';
      case 'themeAccentOverride':
        _accentOverridden = value == true;
      case 'translucentUI':
        _translucent = value == true;
    }
    notifyListeners();
    try {
      await _bridge.request('settings.set', {
        'settings': {key: value},
      });
    } on CoreRequestException catch (error) {
      debugPrint('Setting not persisted: $error');
    }
  }
}
