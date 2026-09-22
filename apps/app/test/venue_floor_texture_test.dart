import 'package:app/feature/venue_map/data/venue_floor_texture.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('both bundled floors fit the 3D texture budget and retain mipmaps', () async {
    var bytes = 0;
    try {
      for (final dark in [false, true]) {
        final texture = await loadVenueFloorTexture(dark: dark);
        final gpuTexture = texture.gpuTexture;
        expect(gpuTexture.width, 1774);
        expect(gpuTexture.height, 810);
        expect(gpuTexture.mipLevelCount, greaterThan(1));
        for (var level = 0; level < gpuTexture.mipLevelCount; level++) {
          bytes +=
              (gpuTexture.width >> level).clamp(1, gpuTexture.width) *
              (gpuTexture.height >> level).clamp(1, gpuTexture.height) *
              4;
        }
      }
    } on Exception catch (error) {
      if (!error.toString().contains('Flutter GPU requires the Impeller rendering backend')) {
        rethrow;
      }
      markTestSkipped('Requires --enable-impeller --enable-flutter-gpu');
      return;
    }
    expect(bytes, lessThan(15 * 1024 * 1024));
  });
}
