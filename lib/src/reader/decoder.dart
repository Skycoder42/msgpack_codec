import 'dart:convert';
import 'dart:typed_data';

import 'deserializer.dart';
import 'ext_decoder.dart';

class MsgpackDecoder extends Converter<Uint8List, dynamic> {
  final Encoding _codec;
  final ExtDecoder? _extDecoder;
  final bool copyBinaryData;

  const MsgpackDecoder({
    Encoding codec = utf8,
    ExtDecoder? extDecoder,
    this.copyBinaryData = false,
  })  : _codec = codec,
        _extDecoder = extDecoder;

  @override
  dynamic convert(Uint8List input) {
    final deserializer = Deserializer(
      input,
      _codec,
      extDecoder: _extDecoder,
      copyBinaryData: copyBinaryData,
    );
    return deserializer.decode();
  }

  @override
  Sink<Uint8List> startChunkedConversion(Sink<dynamic> sink) {
    // TODO: implement startChunkedConversion
    throw UnimplementedError();
  }
}
