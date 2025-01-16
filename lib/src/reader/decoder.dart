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
  Sink<Uint8List> startChunkedConversion(Sink<dynamic> sink) =>
      _DecoderWrappingSink(this, sink);
}

class _DecoderWrappingSink implements Sink<Uint8List> {
  final MsgpackDecoder _decoder;
  final Sink<dynamic> _sink;

  final _buffer = BytesBuilder();
  int _offset = 0;

  _DecoderWrappingSink(this._decoder, this._sink);

  @override
  void add(Uint8List data) {
    _buffer.add(data);
    _flush();
  }

  @override
  void close() {
    if (!_flush()) {
      throw const FormatException('Invalid MsgPack data');
    }
    _sink.close();
  }

  bool _flush() {
    final bytes = _buffer.toBytes();
    try {
      final deserializer = Deserializer(
        bytes,
        initialOffset: _offset,
        _decoder._codec,
        extDecoder: _decoder._extDecoder,
        copyBinaryData: _decoder.copyBinaryData,
      );
      while (_offset < _buffer.length) {
        _sink.add(deserializer.decode());
        _offset = deserializer.currentOffset;
      }

      return true;
      // ignore: avoid_catching_errors
    } on RangeError {
      return false;
      // ignore: avoid_catching_errors
    } on ArgumentError {
      return false;
    } finally {
      if (_offset == _buffer.length) {
        // if the buffer was fully consumed, clear it
        _buffer.clear();
        _offset = 0;
      } else if (_buffer.length >= 1024 * 1024 * 10) {
        // if the buffer is larger than 10MB, clear it
        // and preserve the remaining data
        _buffer.clear();
        _buffer.add(bytes.sublist(_offset));
        _offset = 0;
      }
    }
  }
}
