import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

/// Mirrors the envelope documented in `docs/core-protocol.md`:
/// `{"type":"request","id":"...","method":"...","params":{...}}`.
class CoreRequestException implements Exception {
  const CoreRequestException(this.code, this.message);

  final String code;
  final String message;

  @override
  String toString() => 'CoreRequestException($code): $message';
}

abstract class OpenNowBridge {
  Future<Map<String, dynamic>> request(
    String method, [
    Map<String, dynamic> params = const {},
  ]);

  Stream<Map<String, dynamic>> get events;

  Future<void> dispose();
}

/// Talks to the Rust bridge over the platform channel. The same JSON envelope
/// is used on desktop (newline-delimited stdio) and Android (MethodChannel), so
/// the Dart state layer does not need to know which platform it is on.
class MethodChannelOpenNowBridge implements OpenNowBridge {
  MethodChannelOpenNowBridge({OpenNowStreamBridge? streamBridge})
    : _streamBridge = streamBridge ?? OpenNowStreamBridge();

  static const MethodChannel _core = MethodChannel(
    'com.opencloudgaming.opennow/core',
  );
  static const EventChannel _coreEvents = EventChannel(
    'com.opencloudgaming.opennow/coreEvents',
  );

  final OpenNowStreamBridge _streamBridge;
  final StreamController<Map<String, dynamic>> _events =
      StreamController<Map<String, dynamic>>.broadcast();
  StreamSubscription<dynamic>? _eventSubscription;
  int _nextId = 0;

  @override
  Stream<Map<String, dynamic>> get events => _events.stream;

  OpenNowStreamBridge get stream => _streamBridge;

  void startListening() {
    if (_eventSubscription != null) return;
    _eventSubscription = _coreEvents.receiveBroadcastStream().listen((
      dynamic raw,
    ) {
      try {
        final decoded = jsonDecode(raw as String) as Map<String, dynamic>;
        _events.add(decoded);
      } on FormatException catch (error) {
        debugPrint('Ignoring malformed core event: $error');
      }
    }, onError: (Object error) => _events.addError(error));
  }

  @override
  Future<Map<String, dynamic>> request(
    String method, [
    Map<String, dynamic> params = const {},
  ]) async {
    _nextId += 1;
    final envelope = jsonEncode({
      'type': 'request',
      'id': '$_nextId',
      'method': method,
      'params': params,
    });
    final raw = await _core.invokeMethod<String>('request', {
      'request': envelope,
    });
    if (raw == null) {
      throw const CoreRequestException(
        'empty_response',
        'Bridge returned no data',
      );
    }
    final decoded = jsonDecode(raw) as Map<String, dynamic>;
    final error = decoded['error'] as Map<String, dynamic>?;
    if (error != null) {
      throw CoreRequestException(
        '${error['code'] ?? 'unknown'}',
        '${error['message'] ?? 'Unknown core error'}',
      );
    }
    return (decoded['result'] as Map<String, dynamic>?) ?? <String, dynamic>{};
  }

  @override
  Future<void> dispose() async {
    await _eventSubscription?.cancel();
    await _events.close();
  }
}

/// Stream lifecycle and gameplay input live on their own channel so the
/// high-rate input methods never contend with account/settings requests.
class OpenNowStreamBridge {
  static const MethodChannel _channel = MethodChannel(
    'com.opencloudgaming.opennow/stream',
  );

  Future<int> createTexture() async {
    final id = await _channel.invokeMethod<dynamic>('createTexture');
    return (id as num).toInt();
  }

  Future<void> releaseTexture() =>
      _channel.invokeMethod<void>('releaseTexture');

  Future<void> start(Map<String, dynamic> config) =>
      _channel.invokeMethod<void>('start', {'config': jsonEncode(config)});

  Future<void> stop() => _channel.invokeMethod<void>('stop');

  Future<void> submitKey(int keyCode, int action, int modifiers) =>
      _channel.invokeMethod<void>('submitKey', {
        'keyCode': keyCode,
        'action': action,
        'modifiers': modifiers,
      });

  Future<void> submitText(String text) =>
      _channel.invokeMethod<void>('submitText', {'text': text});

  Future<void> submitMouse(double dx, double dy, int buttons) =>
      _channel.invokeMethod<void>('submitMouse', {
        'dx': dx,
        'dy': dy,
        'buttons': buttons,
      });

  Future<void> requestKeyframe() =>
      _channel.invokeMethod<void>('requestKeyframe');

  Future<Map<String, dynamic>> diagnostics() async {
    final raw = await _channel.invokeMethod<String>('diagnostics');
    if (raw == null) return {};
    return jsonDecode(raw) as Map<String, dynamic>;
  }
}
