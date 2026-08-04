import 'dart:convert';
import 'dart:typed_data';

/// JSON イベントの種別。
enum JsonEventType { objectStart, objectEnd, arrayStart, arrayEnd, key, value }

/// ストリーミング JSON パーサーが生成する 1 イベント。
class JsonEvent {
  const JsonEvent(this.type, {this.key, this.value});

  final JsonEventType type;
  final String? key;
  final Object? value;
}

/// JSON 構文エラー（位置は内部診断用）。
class JsonParseException implements Exception {
  const JsonParseException(this.message, {this.offset});

  final String message;
  final int? offset;

  @override
  String toString() => 'JsonParseException($message @ $offset)';
}

/// 巨大ファイルを全文 String 化せずに解析するストリーミング JSON
/// トークナイザー。
///
/// 文字列とスカラーだけをチャンク境界をまたいで保持し、コンテナ全体は
/// 保持しない。構文状態はコンテナごとのスタックで管理する。
class JsonEventParser {
  static const int _maxStringBytes = 4 * 1024 * 1024;
  static const int _maxNumberChars = 128;

  // object: 0=keyOrEnd, 1=colon, 2=value, 3=commaOrEnd
  // array:  0=valueOrEnd, 1=commaOrEnd
  final List<_Frame> _stack = [];
  final List<int> _buffer = [];
  int _pos = 0;
  bool _rootStarted = false;
  bool _rootDone = false;

  bool _inString = false;
  bool _stringIsKey = false;
  bool _stringEscaped = false;
  final BytesBuilder _stringRaw = BytesBuilder(copy: false);

  /// チャンクを追加し、追加分で確定したイベントを返す。
  List<JsonEvent> addChunk(List<int> chunk) {
    if (chunk.isNotEmpty) _buffer.addAll(chunk);
    final events = <JsonEvent>[];
    while (true) {
      final event = _tryParseNext();
      if (event == null) break;
      events.add(event);
    }
    _compact();
    return events;
  }

  /// 入力終了時処理。未クローズの構造や末尾ゴミを検出する。
  void finish() {
    while (true) {
      final before = _pos;
      final event = _tryParseNext(atEof: true);
      if (event == null && _pos == before) break;
    }
    _skipWhitespace();
    if (_inString) {
      throw const JsonParseException('unterminated string');
    }
    if (_stack.isNotEmpty) {
      throw const JsonParseException('unterminated container');
    }
    if (!_rootDone) {
      throw const JsonParseException('empty or incomplete document');
    }
    if (_pos < _buffer.length) {
      throw JsonParseException('trailing data after root value', offset: _pos);
    }
    _compact();
  }

  JsonEvent? _tryParseNext({bool atEof = false}) {
    while (true) {
      if (_inString) return _continueString();
      _skipWhitespace();
      if (_pos >= _buffer.length) return null;
      if (_rootDone) {
        throw JsonParseException(
          'trailing data after root value',
          offset: _pos,
        );
      }

      if (_stack.isEmpty) {
        if (_rootStarted) {
          throw JsonParseException('invalid root state', offset: _pos);
        }
        return _parseValue(atEof: atEof);
      }

      final frame = _stack.last;
      if (frame.isObject) {
        switch (frame.state) {
          case 0:
            final b = _buffer[_pos];
            if (b == 0x7D) return _closeContainer(isObject: true);
            if (b != 0x22) {
              throw JsonParseException(
                'expected object key or "}"',
                offset: _pos,
              );
            }
            _beginString(isKey: true);
            return _continueString();
          case 1:
            if (_buffer[_pos] != 0x3A) {
              throw JsonParseException('expected ":"', offset: _pos);
            }
            _pos++;
            frame.state = 2;
            continue;
          case 2:
            return _parseValue(atEof: atEof);
          case 3:
            final b = _buffer[_pos];
            if (b == 0x2C) {
              _pos++;
              frame.state = 0;
              continue;
            }
            if (b == 0x7D) return _closeContainer(isObject: true);
            throw JsonParseException('expected "," or "}"', offset: _pos);
          default:
            throw StateError('invalid object parser state');
        }
      } else {
        switch (frame.state) {
          case 0:
            if (_buffer[_pos] == 0x5D) {
              return _closeContainer(isObject: false);
            }
            return _parseValue(atEof: atEof);
          case 1:
            final b = _buffer[_pos];
            if (b == 0x2C) {
              _pos++;
              frame.state = 0;
              continue;
            }
            if (b == 0x5D) return _closeContainer(isObject: false);
            throw JsonParseException('expected "," or "]"', offset: _pos);
          default:
            throw StateError('invalid array parser state');
        }
      }
    }
  }

  JsonEvent? _parseValue({required bool atEof}) {
    final b = _buffer[_pos];
    if (b == 0x7B) {
      _markValueStarted(container: true);
      _pos++;
      _stack.add(_Frame.object());
      return const JsonEvent(JsonEventType.objectStart);
    }
    if (b == 0x5B) {
      _markValueStarted(container: true);
      _pos++;
      _stack.add(_Frame.array());
      return const JsonEvent(JsonEventType.arrayStart);
    }
    if (b == 0x22) {
      _beginString(isKey: false);
      return _continueString();
    }

    final scalar = _parseScalar(atEof: atEof);
    if (scalar == null) return null;
    _markValueStarted(container: false);
    return JsonEvent(JsonEventType.value, value: scalar.value);
  }

  void _beginString({required bool isKey}) {
    _pos++; // opening quote
    _inString = true;
    _stringIsKey = isKey;
    _stringEscaped = false;
    _stringRaw.clear();
  }

  JsonEvent? _continueString() {
    while (_pos < _buffer.length) {
      final b = _buffer[_pos++];
      if (_stringEscaped) {
        _stringRaw.addByte(b);
        _stringEscaped = false;
        continue;
      }
      if (b == 0x5C) {
        _stringRaw.addByte(b);
        _stringEscaped = true;
        continue;
      }
      if (b == 0x22) {
        _inString = false;
        final raw = _stringRaw.takeBytes();
        final decoded =
            jsonDecode('"${utf8.decode(raw, allowMalformed: false)}"')
                as String;
        if (_stringIsKey) {
          final frame = _stack.last;
          if (!frame.isObject || frame.state != 0) {
            throw StateError('key outside object');
          }
          frame.state = 1;
          return JsonEvent(JsonEventType.key, key: decoded);
        }
        _markValueStarted(container: false);
        return JsonEvent(JsonEventType.value, value: decoded);
      }
      if (b < 0x20) {
        throw JsonParseException(
          'control character in string',
          offset: _pos - 1,
        );
      }
      _stringRaw.addByte(b);
      if (_stringRaw.length > _maxStringBytes) {
        throw const JsonParseException('string too long');
      }
    }
    return null;
  }

  _ScalarResult? _parseScalar({required bool atEof}) {
    final start = _pos;
    while (_pos < _buffer.length && !_isDelimiter(_buffer[_pos])) {
      _pos++;
      if (_pos - start > _maxNumberChars) {
        throw const JsonParseException('scalar token too long');
      }
    }
    if (_pos == _buffer.length && !atEof) {
      _pos = start;
      return null;
    }
    if (_pos == start) {
      throw JsonParseException('expected value', offset: start);
    }

    final token = utf8.decode(
      _buffer.sublist(start, _pos),
      allowMalformed: false,
    );
    switch (token) {
      case 'true':
        return const _ScalarResult(true);
      case 'false':
        return const _ScalarResult(false);
      case 'null':
        return const _ScalarResult(null);
    }

    if (token.length > _maxNumberChars || !_jsonNumber.hasMatch(token)) {
      throw JsonParseException('invalid scalar: $token', offset: start);
    }
    final value = num.tryParse(token);
    if (value == null) {
      throw JsonParseException('invalid number: $token', offset: start);
    }
    return _ScalarResult(value);
  }

  JsonEvent _closeContainer({required bool isObject}) {
    final frame = _stack.last;
    if (frame.isObject != isObject) {
      throw JsonParseException('mismatched container close', offset: _pos);
    }
    _pos++;
    _stack.removeLast();
    if (_stack.isEmpty) _rootDone = true;
    return JsonEvent(
      isObject ? JsonEventType.objectEnd : JsonEventType.arrayEnd,
    );
  }

  void _markValueStarted({required bool container}) {
    if (_stack.isEmpty) {
      if (_rootStarted) {
        throw JsonParseException('multiple root values', offset: _pos);
      }
      _rootStarted = true;
      if (!container) _rootDone = true;
      return;
    }

    final parent = _stack.last;
    if (parent.isObject) {
      if (parent.state != 2) {
        throw JsonParseException('unexpected object value', offset: _pos);
      }
      parent.state = 3;
    } else {
      if (parent.state != 0) {
        throw JsonParseException('unexpected array value', offset: _pos);
      }
      parent.state = 1;
    }
  }

  void _skipWhitespace() {
    while (_pos < _buffer.length) {
      final b = _buffer[_pos];
      if (b == 0x20 || b == 0x09 || b == 0x0A || b == 0x0D) {
        _pos++;
      } else {
        break;
      }
    }
  }

  bool _isDelimiter(int b) =>
      b == 0x20 ||
      b == 0x09 ||
      b == 0x0A ||
      b == 0x0D ||
      b == 0x2C ||
      b == 0x7D ||
      b == 0x5D;

  void _compact() {
    if (_pos > 0) {
      _buffer.removeRange(0, _pos);
      _pos = 0;
    }
    if (_buffer.length > _maxStringBytes + _maxNumberChars) {
      throw const JsonParseException('input token exceeds internal limit');
    }
  }

  static final RegExp _jsonNumber = RegExp(
    r'^-?(?:0|[1-9]\d*)(?:\.\d+)?(?:[eE][+-]?\d+)?$',
  );
}

class _Frame {
  _Frame.object() : isObject = true, state = 0;

  _Frame.array() : isObject = false, state = 0;

  final bool isObject;
  int state;
}

class _ScalarResult {
  const _ScalarResult(this.value);

  final Object? value;
}
