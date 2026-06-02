# Data

Thin data access package for FlutterKaigi 2026.

The package currently contains only the `news` sample collection. Add new models and repositories when product code needs the collection.

## Local Emulator

```dart
import 'package:data/data.dart';

final repository = FirestoreNewsRepository(
  FirebaseDataClient.emulator(),
);

final news = await repository.fetchNews();
```

By default, the emulator client reads from:

- Project ID: `dev-flutterkaigi-2026`
- Firestore Emulator: `localhost:8080`

Android Emulator apps should pass `host: '10.0.2.2:8080'`.

## Code Generation

Models use Freezed. Regenerate code from the repository root after changing
model definitions:

```bash
fvm dart run melos gen
```
