# Data

Thin data access package for FlutterKaigi 2026.

The package currently contains only the `news` sample collection. Add new models and repositories when product code needs the collection.

## Local Emulator

```dart
import 'package:data/data.dart';

// Call once at app startup (for example in main()).
await FirebaseInitializer.ensureInitialized();

final repository = FirestoreNewsRepository();
final news = await repository.fetchNews();
```

`ensureInitialized` connects to the local Firebase Emulator suite via
`cloud_firestore` / `firebase_auth`, defaulting to:

- Project ID: `dev-flutterkaigi-2026`
- Firestore Emulator: `localhost:8080`
- Auth Emulator: `localhost:9099`

Android Emulator apps should pass `host: '10.0.2.2'`.

## Code Generation

Models use Freezed. Regenerate code from the repository root after changing
model definitions:

```bash
fvm dart run melos gen
```
