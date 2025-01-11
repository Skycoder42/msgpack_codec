import 'dart:convert';
import 'dart:typed_data';

import 'data_writer.dart';
import 'ext_encoder.dart';
import 'serializer.dart';

class MsgpackEncoder extends Converter<dynamic, Uint8List> {
  final Encoding _codec;
  final ExtEncoder? _extEncoder;

  const MsgpackEncoder({
    Encoding codec = utf8,
    ExtEncoder? extEncoder,
  })  : _codec = codec,
        _extEncoder = extEncoder;

  @override
  Uint8List convert(dynamic input) {
    final writer = ByteBufferDataWriter();
    final serializer = Serializer(writer, _codec, _extEncoder);
    serializer.encode(input);
    return writer.takeBytes();
  }

  @override
  Sink<dynamic> startChunkedConversion(Sink<Uint8List> sink) {
    final writer = SinkDataWriter(sink);
    final serializer = Serializer(writer, _codec, _extEncoder);
    return _SerializerSink(writer, serializer);
  }
}

class _SerializerSink implements Sink<dynamic> {
  final SinkDataWriter _writer;
  final Serializer _serializer;

  _SerializerSink(this._writer, this._serializer);

  @override
  void add(dynamic data) {
    _serializer.encode(data);
  }

  @override
  void close() => _writer.finalize();
}
