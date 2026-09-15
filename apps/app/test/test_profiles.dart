import 'package:data/data.dart';

UserProfile profile(String uid, String country) => UserProfile(
  id: uid,
  displayName: uid,
  countryOrRegion: country,
  createdAt: DateTime.utc(2026),
  updatedAt: DateTime.utc(2026),
);
