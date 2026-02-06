import 'package:flutter_native_image_compress/flutter_native_image_compress.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('clamps quality to 0-100', () {
    const high = CompressOptions(quality: 150);
    const low = CompressOptions(quality: -10);

    expect(high.quality, 100);
    expect(low.quality, 0);
  });

  test('allows null dimensions and clamps negatives to null', () {
    const options = CompressOptions();
    const negative = CompressOptions(maxWidth: -1, maxHeight: -2);

    expect(options.maxWidth, isNull);
    expect(options.maxHeight, isNull);
    expect(negative.maxWidth, isNull);
    expect(negative.maxHeight, isNull);
  });
}
