import 'dart:typed_data';

abstract class ExtDecoder {
  /// Return null if the data cannot be decoded
  dynamic decodeObject(int extType, Uint8List data);
}
