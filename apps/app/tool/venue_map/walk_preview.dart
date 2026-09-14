// Run the production walking screen without Firebase initialization.
import 'package:app/feature/venue_map/ui/page/venue_walk_page.dart';
import 'package:flutter/material.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  // Makes the real Flutter controls inspectable in the browser demo.
  WidgetsBinding.instance.ensureSemantics();
  runApp(
    MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'だしゅまると会場さんぽ | FlutterKaigi 2026',
      theme: ThemeData(
        useMaterial3: true,
        fontFamily: 'Noto Sans JP',
        colorScheme: ColorScheme.fromSeed(seedColor: green, surface: canvas),
        scaffoldBackgroundColor: canvas,
        textTheme: const TextTheme(bodyMedium: TextStyle(color: ink)),
        filledButtonTheme: FilledButtonThemeData(style: FilledButton.styleFrom(minimumSize: const Size(44, 48))),
      ),
      home: const VenueWalkPage(showcase: true),
    ),
  );
}
