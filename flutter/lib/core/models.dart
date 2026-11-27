// Plain Dart mirrors of the JSON payloads the Qt shell consumes from
// opennow-core. Keeping them framework-free makes them testable and keeps
// UI state from reaching into raw maps.

enum MembershipTier { free, performance, ultimate, unknown }

MembershipTier tierFromString(String? value) => switch (value) {
  'FREE' => MembershipTier.free,
  'PERFORMANCE' => MembershipTier.performance,
  'ULTIMATE' => MembershipTier.ultimate,
  _ => MembershipTier.unknown,
};

class Account {
  const Account({
    required this.userId,
    required this.displayName,
    this.email,
    this.avatarUrl,
    this.membershipTier = MembershipTier.unknown,
    this.providerName = 'NVIDIA',
    this.alliance = false,
    this.hasPin = false,
    this.needsSignIn = false,
  });

  factory Account.fromJson(Map<String, dynamic> json) => Account(
    userId: '${json['userId'] ?? ''}',
    displayName: '${json['displayName'] ?? 'Unknown'}',
    email: json['email'] as String?,
    avatarUrl: json['avatarUrl'] as String?,
    membershipTier: tierFromString(json['membershipTier'] as String?),
    providerName: '${json['providerName'] ?? 'NVIDIA'}',
    alliance: json['alliance'] as bool? ?? false,
    hasPin: json['hasPin'] as bool? ?? false,
    needsSignIn: json['needsSignIn'] as bool? ?? false,
  );

  final String userId;
  final String displayName;
  final String? email;
  final String? avatarUrl;
  final MembershipTier membershipTier;
  final String providerName;
  final bool alliance;
  final bool hasPin;
  final bool needsSignIn;
}

class Game {
  const Game({
    required this.id,
    required this.name,
    this.variantId,
    this.artworkUrl,
    this.developer,
    this.genre,
    this.favorite = false,
    this.pinned = false,
  });

  factory Game.fromJson(Map<String, dynamic> json) => Game(
    id: '${json['appId'] ?? json['id'] ?? ''}',
    variantId: json['variantId'] as String?,
    name: '${json['game'] ?? json['name'] ?? 'Unknown'}',
    artworkUrl: json['artworkUrl'] as String?,
    developer: json['developer'] as String?,
    genre: json['genre'] as String?,
    favorite: json['favorite'] as bool? ?? false,
    pinned: json['pinned'] as bool? ?? false,
  );

  final String id;
  final String name;
  final String? variantId;
  final String? artworkUrl;
  final String? developer;
  final String? genre;
  final bool favorite;
  final bool pinned;
}

class LaunchDecision {
  const LaunchDecision({required this.status, required this.message});

  factory LaunchDecision.fromJson(Map<String, dynamic> json) => LaunchDecision(
    status: '${json['status'] ?? 'unavailable'}',
    message: '${json['message'] ?? ''}',
  );

  final String status;
  final String message;

  bool get ready => status == 'ready';
}

class StreamDiagnostics {
  const StreamDiagnostics({
    this.stage = 'idle',
    this.receive = 'idle',
    this.assembly = 'idle',
    this.decode = 'idle',
    this.presentation = 'idle',
    this.feedback = 'idle',
    this.streaming = false,
  });

  factory StreamDiagnostics.fromJson(Map<String, dynamic> json) =>
      StreamDiagnostics(
        stage: '${json['stage'] ?? 'idle'}',
        receive: '${json['receive'] ?? 'idle'}',
        assembly: '${json['assembly'] ?? 'idle'}',
        decode: '${json['decode'] ?? 'idle'}',
        presentation: '${json['presentation'] ?? 'idle'}',
        feedback: '${json['feedback'] ?? 'idle'}',
        streaming: json['streaming'] as bool? ?? false,
      );

  final String stage;
  final String receive;
  final String assembly;
  final String decode;
  final String presentation;
  final String feedback;
  final bool streaming;
}

class UpdateInfo {
  const UpdateInfo({required this.version, required this.notes});

  final String version;
  final String notes;
}
