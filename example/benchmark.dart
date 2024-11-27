// ignore_for_file: avoid_print, lines_longer_than_80_chars

import 'dart:convert';
import 'dart:io';

import 'package:msgpack_dart/msgpack_dart.dart' as m2;

const int _times = 10000;

Future<void> main(List<String> args) async {
  print('Warming Up...');
  for (var i = 0; i < _times; i++) {
    final jsonStr = json.encode({'hello': 'world'});

    json.encode(json.decode(jsonStr));
  }

  if (args.contains('--savings')) {
    final numbers = <int>[];
    for (var i = 1; i <= 100000; i++) {
      numbers.add(i);
    }

    final jsonBytes = utf8.encode(json.encode(numbers)).length;
    final msgpack2Bytes = m2.serialize(numbers).length;
    print('JSON: $jsonBytes bytes, MSGPACK: $msgpack2Bytes bytes');
    exit(0);
  }

  final objects = {
    'One': 1,
    'Five Hundred Thousand': 500000,
    'List of Small Integers': [1, 2, 3],
    'Simple Map': {'hello': 'world'},
    '5.02817472928': 5.02817472928,
    'Multiple Type Map': {
      'String': 'Hello World',
      'Integer': 1,
      'Double': 2.0154,
      'Array': const [1, 2, 3, 'Hello'],
    },
    'Medium Data': {
      '/downstream/wemo/CoffeeMaker-1_0-221421S0000731/Brew_Age': [
        [1440366101049, -123881],
        [1440366102047, -123882],
        [1440366103049, -123883],
        [1440366104046, -123884],
        [1440366105062, -123885],
        [1440366106050, -123886],
        [1440366107046, -123887],
        [1440366108045, -123888],
        [1440366109036, -123889],
        [1440366110048, -123890],
        [1440366111047, -123891],
        [1440366112037, -123892],
        [1440366113048, -123893],
        [1440366114048, -123894],
        [1440366115046, -123895],
        [1440366116044, -123896],
        [1440366117045, -123897],
        [1440366118049, -123898],
        [1440366119046, -123899],
        [1440366120042, -123900],
        [1440366121047, -123901],
        [1440366122048, -123902],
        [1440366123046, -123903],
        [1440366124055, -123904],
        [1440366126059, -123906],
        [1440366127054, -123907],
        [1440366128047, -123908],
        [1440366129051, -123909],
        [1440366130051, -123910],
        [1440366131048, -123911],
        [1440366132050, -123912],
        [1440366133032, -123913],
        [1440366134045, -123914],
        [1440366135050, -123915],
        [1440366136049, -123916],
      ],
    },
  };

  var markdown = false;
  if (args.contains('-m')) markdown = true;

  if (args.contains('-u')) {
    if (markdown) {
      print('Deserialize\n===');
    } else {
      print('=== Deserialize ===');
    }

    for (final key in objects.keys) {
      testObjectDecode(key, objects[key], markdown);
    }
  } else if (args.contains('-a')) {
    if (markdown) {
      print('Serialize\n===');
    } else {
      print('=== Serialize ===');
    }
    for (final key in objects.keys) {
      testObjectEncode(key, objects[key], markdown);
    }
    if (markdown) {
      print('Deserialize\n===');
    } else {
      print('=== Deserialize ===');
    }
    for (final key in objects.keys) {
      testObjectDecode(key, objects[key], markdown);
    }
  } else {
    if (markdown) {
      print('Serialize\n===');
    } else {
      print('=== Serialize ===');
    }

    for (final key in objects.keys) {
      testObjectEncode(key, objects[key], markdown);
    }
  }
}

// ignore: avoid_positional_boolean_parameters
dynamic testObjectDecode(String desc, dynamic input, bool markdown) {
  if (markdown) {
    print('$desc\n---');
  } else {
    print('$desc:');
  }
  final packedJson = json.encode(input);

  final watch = Stopwatch();
  final watchTotal = Stopwatch();
  final times = <int>[];
  watchTotal.start();
  for (var i = 1; i <= _times; i++) {
    watch.reset();
    watch.start();
    json.decode(packedJson);
    watch.stop();
    times.add(watch.elapsedMicroseconds);
  }
  var totalTime = watchTotal.elapsedMicroseconds;
  var avgTime = totalTime / _times;
  times.sort((a, b) => a.compareTo(b));

  if (!markdown) {
    print('  JSON:');
    print('    Total Time: $totalTime microseconds (${totalTime / 1000}ms)');
    print('    Average Time: $avgTime microseconds (${avgTime / 1000}ms)');
    print(
      '    Longest Time: ${times.last} microseconds (${times.last / 1000}ms)',
    );
    print(
      '    Shortest Time: ${times.first} microseconds (${times.first / 1000}ms)',
    );
  }
  final jTotal = totalTime;
  final jAvg = avgTime;
  final jLong = times.last;
  final jShort = times.first;

  watch.reset();
  times.clear();
  watchTotal.reset();
  for (var i = 1; i <= _times; i++) {
    watch.reset();
    watch.start();
    watch.stop();
    times.add(watch.elapsedMicroseconds);
  }
  watch.stop();
  totalTime = watchTotal.elapsedMicroseconds;
  avgTime = totalTime / _times;
  times.sort((a, b) => a.compareTo(b));
  if (!markdown) {
    print('  MsgPack2:');
    print('    Total Time: $totalTime microseconds (${totalTime / 1000}ms)');
    print('    Average Time: $avgTime microseconds (${avgTime / 1000}ms)');
    print(
      '    Longest Time: ${times.last} microseconds (${times.last / 1000}ms)',
    );
    print(
      '    Shortest Time: ${times.first} microseconds (${times.first / 1000}ms)',
    );
  }
  final nTotal = totalTime;
  final nAvg = avgTime;
  final nLong = times.last;
  final nShort = times.first;

  watch.reset();
  times.clear();
  watchTotal.reset();
  for (var i = 1; i <= _times; i++) {
    watch.reset();
    watch.start();
    watch.stop();
    times.add(watch.elapsedMicroseconds);
  }
  watch.stop();
  totalTime = watchTotal.elapsedMicroseconds;
  avgTime = totalTime / _times;
  times.sort((a, b) => a.compareTo(b));
  if (!markdown) {
    print('  msgpack_dart');
    print('    Total Time: $totalTime microseconds (${totalTime / 1000}ms)');
    print('    Average Time: $avgTime microseconds (${avgTime / 1000}ms)');
    print(
      '    Longest Time: ${times.last} microseconds (${times.last / 1000}ms)',
    );
    print(
      '    Shortest Time: ${times.first} microseconds (${times.first / 1000}ms)',
    );
  }
  final n2Total = totalTime;
  final n2Avg = avgTime;
  final n2Long = times.last;
  final n2Short = times.first;

  if (markdown) {
    print('Time | JSON | MsgPack2 | msgpack_dart |');
    print('-----|------|----------|--------------|');
    print(
      'Total | $jTotal μs (${jTotal / 1000}ms) | $nTotal μs (${nTotal / 1000}ms) |$n2Total μs (${n2Total / 1000}ms)',
    );
    print(
      'Average | $jAvg μs (${jAvg / 1000}ms) | $nAvg μs (${nAvg / 1000}ms) |$n2Avg μs (${n2Avg / 1000}ms)',
    );
    print(
      'Longest | $jLong μs (${jLong / 1000}ms) | $nLong μs (${nLong / 1000}ms) |$n2Long μs (${n2Long / 1000}ms)',
    );
    print(
      'Shortest | $jShort μs (${jShort / 1000}ms) | '
      '$nShort μs (${nShort / 1000}ms) |'
      '$n2Short μs (${n2Short / 1000}ms)',
    );
  }

  var bestAvg = n2Avg;
  var fastest = 'msgpack_dart';
  if (nAvg < bestAvg) {
    bestAvg = nAvg;
    fastest = 'MsgPack2';
  }
  if (jAvg < bestAvg) {
    bestAvg = jAvg;
    fastest = 'JSON';
  }

  if (markdown) {
    print('Fastest | $fastest\n');
  } else {
    print('  $fastest was fastest');
  }
}

// ignore: avoid_positional_boolean_parameters
dynamic testObjectEncode(String desc, dynamic input, bool markdown) {
  if (markdown) {
    print('$desc\n---');
  } else {
    print('$desc:');
  }
  final watch = Stopwatch();
  final watchTotal = Stopwatch();
  final times = <int>[];

  watchTotal.start();
  var size = utf8.encode(json.encode(input)).length;
  for (var i = 1; i <= _times; i++) {
    watch.reset();
    watch.start();
    json.encode(input);
    watch.stop();
    times.add(watch.elapsedMicroseconds);
  }
  var totalTime = watchTotal.elapsedMicroseconds;
  var avgTime = totalTime / _times;
  times.sort((a, b) => a.compareTo(b));
  if (!markdown) {
    print('  JSON:');
    print('    Total Time: $totalTime microseconds (${totalTime / 1000}ms)');
    print('    Average Time: $avgTime microseconds (${avgTime / 1000}ms)');
    print(
      '    Longest Time: ${times.last} microseconds (${times.last / 1000}ms)',
    );
    print(
      '    Shortest Time: ${times.first} microseconds (${times.first / 1000}ms)',
    );
    print('    Size: $size bytes');
  }
  final jTotal = totalTime;
  final jAvg = avgTime;
  final jLong = times.last;
  final jShort = times.first;
  final jSize = size;

  watch.reset();
  times.clear();
  watchTotal.reset();
  for (var i = 1; i <= _times; i++) {
    watch.reset();
    watch.start();
    watch.stop();
    times.add(watch.elapsedMicroseconds);
  }
  watch.stop();
  totalTime = watchTotal.elapsedMicroseconds;
  avgTime = totalTime / _times;
  times.sort((a, b) => a.compareTo(b));
  if (!markdown) {
    print('  MsgPack2:');
    print('    Total Time: $totalTime microseconds (${totalTime / 1000}ms)');
    print('    Average Time: $avgTime microseconds (${avgTime / 1000}ms)');
    print(
      '    Longest Time: ${times.last} microseconds (${times.last / 1000}ms)',
    );
    print(
      '    Shortest Time: ${times.first} microseconds (${times.first / 1000}ms)',
    );
    print('    Size: $size bytes');
  }
  final nTotal = totalTime;
  final nAvg = avgTime;
  final nLong = times.last;
  final nShort = times.first;
  final nSize = size;

  watch.reset();
  size = m2.serialize(input).length;
  times.clear();
  watchTotal.reset();
  for (var i = 1; i <= _times; i++) {
    watch.reset();
    watch.start();
    m2.serialize(input);
    watch.stop();
    times.add(watch.elapsedMicroseconds);
  }
  watch.stop();
  totalTime = watchTotal.elapsedMicroseconds;
  avgTime = totalTime / _times;
  times.sort((a, b) => a.compareTo(b));
  if (!markdown) {
    print('  msgpack_dart:');
    print('    Total Time: $totalTime microseconds (${totalTime / 1000}ms)');
    print('    Average Time: $avgTime microseconds (${avgTime / 1000}ms)');
    print(
      '    Longest Time: ${times.last} microseconds (${times.last / 1000}ms)',
    );
    print(
      '    Shortest Time: ${times.first} microseconds (${times.first / 1000}ms)',
    );
    print('    Size: $size bytes');
  }
  final n2Total = totalTime;
  final n2Avg = avgTime;
  final n2Long = times.last;
  final n2Short = times.first;
  final n2Size = size;

  if (markdown) {
    print('Time | JSON | MsgPack2 | msgpack_dart |');
    print('-----|------|---------|--------------|');
    print(
      'Total | $jTotal μs (${jTotal / 1000}ms) | $nTotal μs (${nTotal / 1000}ms) | $n2Total μs (${n2Total / 1000}ms)',
    );
    print(
      'Average | $jAvg μs (${jAvg / 1000}ms) | $nAvg μs (${nAvg / 1000}ms) | $n2Avg μs (${n2Avg / 1000}ms)',
    );
    print(
      'Longest | $jLong μs (${jLong / 1000}ms) | $nLong μs (${nLong / 1000}ms) | $n2Long μs (${n2Long / 1000}ms)',
    );
    print(
      'Shortest | $jShort μs (${jShort / 1000}ms) | $nShort μs (${nShort / 1000}ms) | $n2Short μs (${n2Short / 1000}ms)',
    );
    print('Size | $jSize bytes | $nSize bytes | $n2Size bytes');
  }

  var bestAvg = n2Avg;
  var fastest = 'msgpack_dart';
  if (nAvg < bestAvg) {
    bestAvg = nAvg;
    fastest = 'MsgPack2';
  }
  if (jAvg < bestAvg) {
    bestAvg = jAvg;
    fastest = 'JSON';
  }

  if (markdown) {
    print('Fastest | $fastest\n');
  } else {
    print('  $fastest was fastest');
  }
}
