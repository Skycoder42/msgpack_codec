import 'package:dart_test_tools/test.dart';
import 'package:msgpack_dart/src/common/float.dart';
import 'package:test/test.dart';

void main() {
  group('$Float', () {
    testData(
      'equality wraps double',
      const [
        (Float(1.1), Float(1.1), true),
        (Float(1.1), 1, false),
        (Float(1.1), Float(1.2), false),
      ],
      (fixture) {
        expect(fixture.$1 == fixture.$2, fixture.$3);
        expect(fixture.$1.hashCode == fixture.$2.hashCode, fixture.$3);
      },
    );
  });
}
