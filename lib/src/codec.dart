import 'dart:convert';
import 'dart:typed_data';

import 'reader/decoder.dart';
import 'reader/ext_decoder.dart';
import 'writer/encoder.dart';
import 'writer/ext_encoder.dart';

class MsgpackCodec extends Codec<dynamic, Uint8List> {
  final Encoding _codec;
  final ExtEncoder? _extEncoder;
  final ExtDecoder? _extDecoder;
  final bool copyBinaryData;

  const MsgpackCodec({
    Encoding codec = utf8,
    ExtEncoder? extEncoder,
    ExtDecoder? extDecoder,
    this.copyBinaryData = false,
  }) : _codec = codec,
       _extEncoder = extEncoder,
       _extDecoder = extDecoder;

  @override
  Converter<dynamic, Uint8List> get encoder =>
      MsgpackEncoder(codec: _codec, extEncoder: _extEncoder);

  @override
  Converter<Uint8List, dynamic> get decoder => MsgpackDecoder(
    codec: _codec,
    extDecoder: _extDecoder,
    copyBinaryData: copyBinaryData,
  );
}

const msgPack = MsgpackCodec();
