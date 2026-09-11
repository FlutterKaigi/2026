/// The registration code currently issued by the event staff.
final class SupportLtCode {
  const SupportLtCode({required this.code, required this.issuedAt});

  final String code;
  final DateTime issuedAt;
}

/// An attendee whose Support LT registration was verified by the server.
final class SupportLtRegistration {
  const SupportLtRegistration({required this.uid, required this.displayName, required this.registeredAt});

  final String uid;
  final String displayName;
  final DateTime registeredAt;
}
