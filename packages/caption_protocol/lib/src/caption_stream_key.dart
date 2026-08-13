final class CaptionStreamKey {
  const CaptionStreamKey({required this.roomId, required this.sessionId});

  final String roomId;
  final String sessionId;

  @override
  bool operator ==(Object other) =>
      identical(this, other) || other is CaptionStreamKey && roomId == other.roomId && sessionId == other.sessionId;

  @override
  int get hashCode => Object.hash(roomId, sessionId);

  @override
  String toString() => '$roomId/$sessionId';
}
