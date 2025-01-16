import 'dart:convert';
import 'dart:io';

Future<void> main(List<String> args) async {
  final testDataFile =
      File('test/msgpack-test-suite/dist/msgpack-test-suite.json');
  final testDataJson = await testDataFile.readAsString();
  final condensedJson = json.encode(json.decode(testDataJson));

  final outFile = File('test/msgpack_test_suite_test.g.dart');
  await outFile.writeAsString('''
part of 'msgpack_test_suite_test.dart';

Map<String, dynamic> _loadTestData() => json.decode(
      // ignore: lines_longer_than_80_chars
      '$condensedJson',
    ) as Map<String, dynamic>;

Future<void> _validateUpToDate() async {
  final testDataFile =
      File('test/msgpack-test-suite/dist/msgpack-test-suite.json');
  final testDataJson = await testDataFile.readAsString();
  final testData = json.decode(testDataJson) as Map<String, dynamic>;
  expect(_loadTestData(), testData);
}
''');
}
