import 'dart:typed_data';

abstract interface class ExtEncoder {
  /// Return null if object can't be encoded
  int? extTypeForObject(dynamic object);

  Uint8List encodeObject(dynamic object);
}
