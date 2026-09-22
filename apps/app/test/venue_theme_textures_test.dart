import 'dart:async';

import 'package:app/feature/venue_map/data/venue_theme_textures.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('cold dark startup requests only the dark floor', () async {
    final requests = <bool>[];
    final themes = VenueThemeTextures<String>(
      load: ({required dark}) async {
        requests.add(dark);
        return dark ? 'dark floor' : 'light floor';
      },
    )..dark = true;
    final applied = <(String, bool)>[];
    await themes.apply((texture, {required dark}) => applied.add((texture, dark)));
    expect(requests, [true]);
    expect(applied, [('dark floor', true)]);
  });

  test('rapid theme changes keep a complete appearance until the requested floor is ready', () async {
    final light = Completer<String>();
    final darkTexture = Completer<String>();
    final requests = <bool>[];
    final themes = VenueThemeTextures<String>(
      load: ({required dark}) {
        requests.add(dark);
        return dark ? darkTexture.future : light.future;
      },
    );
    final applied = <(String, bool)>[];
    void apply(String texture, {required bool dark}) => applied.add((texture, dark));
    final initial = themes.apply(apply);
    light.complete('light floor');
    await initial;
    themes.dark = true;
    final switching = themes.apply(apply);
    expect(applied, [('light floor', false)]);
    themes.dark = false;
    await themes.apply(apply);
    darkTexture.complete('dark floor');
    await switching;
    expect(applied.every((value) => value == ('light floor', false)), isTrue);
    themes.dark = true;
    await themes.apply(apply);
    expect(applied.last, ('dark floor', true));
    expect(requests, [false, true]);
  });

  test('a theme change during initial loading waits for the latest theme', () async {
    final light = Completer<String>();
    final darkTexture = Completer<String>();
    final themes = VenueThemeTextures<String>(load: ({required dark}) => dark ? darkTexture.future : light.future);
    final applied = <(String, bool)>[];
    final first = themes.apply((texture, {required dark}) => applied.add((texture, dark)));
    themes.dark = true;
    final second = themes.apply((texture, {required dark}) => applied.add((texture, dark)));
    darkTexture.complete('dark floor');
    await second;
    light.complete('light floor');
    await first;
    expect(applied, everyElement(('dark floor', true)));
  });

  test('failed texture loads can retry without discarding the visible theme', () async {
    var darkAttempts = 0;
    final themes = VenueThemeTextures<String>(
      load: ({required dark}) async {
        if (dark && darkAttempts++ == 0) {
          throw StateError('decode failed');
        }
        return dark ? 'dark floor' : 'light floor';
      },
    );
    final applied = <(String, bool)>[];
    void apply(String texture, {required bool dark}) => applied.add((texture, dark));
    await themes.apply(apply);
    themes.dark = true;
    await expectLater(themes.apply(apply), throwsStateError);
    expect(applied, [('light floor', false)]);
    await themes.apply(apply);
    expect(applied.last, ('dark floor', true));
  });

  test('disposing during a load never applies its result', () async {
    final pending = Completer<String>();
    final themes = VenueThemeTextures<String>(load: ({required dark}) => pending.future);
    final applied = <String>[];
    final operation = themes.apply((texture, {required dark}) => applied.add(texture));
    themes.dispose();
    pending.complete('unused floor');
    await operation;
    await themes.apply((texture, {required dark}) => applied.add(texture));
    expect(applied, isEmpty);
  });
}
