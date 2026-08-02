import 'dart:convert';

/// JSON イベントの種別。
enum JsonEventType { objectStart, objectEnd, arrayStart, arrayEnd, key, value }

/// ストリーミング JSON パーサーが生成する 1 イベント。
class JsonEvent {
  const JsonEvent(this.type, {this.key, this.value});

  final JsonEventType type;
  final String? key;
  final Object? value;
}

/// JSON 構文エラー（行・位置は内部診断のみに使い、ユーザーへは表示しない）。
class JsonParseException implements Exception {
  const JsonParseException(this.message, {this.offset});

  final String message;
  final int? offset;

  @override
  String toString() => 'JsonParseException($message @ $offset)';
}

enum _Mode { expectValue, expectKeyOrEnd, expectColon, expectCommaOrEnd }

/// 巨大ファイルを全文 String 化せずに解析するストリーミング JSON トークナイザー。
///
/// 設計書 10.1「全文 String 化しない」に対応する。入力は UTF-8 バイト列の
/// チャンク列で、オブジェクト・配列・キー・スカラーをイベントとして返す。
/// チャンク境界をまたぐトークン（文字列・数値・リテラル）は状態を保持して
/// 正しく連結する。文字列長・数値長には上限を設ける。
class JsonEventParser {
  static const int _maxStringBytes = 4 * 1024 * 1024; // 4MB
  static const int _maxNumberChars = 128;

  final List<int> _buffer = [];
  final List<bool> _stack = []; // true = object, false = array
  _Mode _mode = _Mode.expectValue;
  int _pos = 0;
  bool _rootDone = false;

  // 文字列解析の継続状態
  bool _inString = false;
  bool _stringEscaped = false;
  final BytesBuilder _stringRaw = BytesBuilder();

  /// チャンクを追加し、追加分で確定したイベントを返す。
  List<JsonEvent> addChunk(List<int> chunk) {
    _buffer.addAll(chunk);
    final events = <JsonEvent>[];
    while (true) {
      final e = _tryParseNext();
      if (e == null) break;
      events.add(e);
    }
    _compact();
    return events;
  }

  /// 入力終了時処理。未クローズの構造や末尾ゴミを検出する。
  void finish() {
    if (_rootDone) {
      _skipWhitespace();
      if (_pos < _buffer.length) {
        throw const JsonParseException('trailing data after root value');
      }
      return;
    }
    // ルート直下の数値/リテラルが区切りなしで終わるケースを確定
    if (_mode == _Mode.expectValue && _pos < _buffer.length) {
      final v = _parseScalar(atRoot: true);
      if (v != null) {
        _mode = _Mode.expectCommaOrEnd;
        _rootDone = true;
        _skipWhitespace();
        if (_pos < _buffer.length) {
          throw const JsonParseException('trailing data after root value');
        }
        return;
      }
    }
    if (_inString) {
      throw const JsonParseException('unterminated string');
    }
    if (_stack.isNotEmpty) {
      throw const JsonParseException('unterminated container');
    }
    if (_buffer.isNotEmpty && _pos < _buffer.length) {
      throw const JsonParseException('unexpected end of input');
    }
    throw const JsonParseException('empty or incomplete document');
  }

  void _compact() {
    if (_pos > 0) {
      _buffer.removeRange(0, _pos);
      _pos = 0;
    }
    if (_buffer.length > 64 * 1024 * 1024) {
      throw const JsonParseException('input exceeds internal buffer limit');
    }
  }

  JsonEvent? _tryParseNext() {
    if (_inString) return _continueString();
    _skipWhitespace();
    if (_pos >= _buffer.length) return null;

    switch (_mode) {
      case _Mode.expectValue:
        return _parseValue();
      case _Mode.expectKeyOrEnd:
        return _parseKeyOrEnd();
      case _Mode.expectColon:
        return _parseColon();
      case _Mode.expectCommaOrEnd:
        return _parseCommaOrEnd();
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

  JsonEvent? _parseValue() {
    final b = _buffer[_pos];
    switch (b) {
      case 0x7B: // {
        _pos++;
        _stack.add(true);
        _mode = _Mode.expectKeyOrEnd;
        return const JsonEvent(JsonEventType.objectStart);
      case 0x5B: // [
        _pos++;
        _stack.add(false);
        _mode = _Mode.expectValue;
        return const JsonEvent(JsonEventType.arrayStart);
      case 0x22: // "
        _pos++;
        _inString = true;
        _stringEscaped = false;
        _stringRaw.clear();
        return _continueString();
      default:
        final v = _parseScalar();
        if (v == null) return null; // トークン未完
        _mode = _Mode.expectCommaOrEnd;
        return JsonEvent(JsonEventType.value, value: v);
    }
  }

  JsonEvent? _parseKeyOrEnd() {
    final b = _buffer[_pos];
    if (b == 0x7D) {
      // }
      _pos++;
      _stack.removeLast();
      if (_stack.isEmpty) _rootDone = true;
      _mode = _Mode.expectCommaOrEnd;
      return const JsonEvent(JsonEventType.objectEnd);
    }
    if (b == 0x22) {
      // "
      _pos++;
      _inString = true;
      _stringEscaped = false;
      _stringRaw.clear();
      final ev = _continueString();
      if (ev == null) return null;
      _mode = _Mode.expectColon;
      return JsonEvent(JsonEventType.key, key: ev.value as String);
    }
    throw JsonParseException('expected key or "}", got 0x${b.toRadixString(16)}',
        offset: _pos);
  }

  JsonEvent? _parseColon() {
    if (_buffer[_pos] != 0x3A) {
      // :
      throw const JsonParseException('expected ":"');
    }
    _pos++;
    _mode = _Mode.expectValue;
    return null;
  }

  JsonEvent? _parseCommaOrEnd() {
    final b = _buffer[_pos];
    if (b == 0x2C) {
      // ,
      _pos++;
      if (_stack.isEmpty) {
        throw const JsonParseException('comma after root value');
      }
      _mode = _stack.last ? _Mode.expectKeyOrEnd : _Mode.expectValue;
      return null;
    }
    if (b == 0x7D) {
      // }
      _pos++;
      _stack.removeLast();
      if (_stack.isEmpty) _rootDone = true;
      _mode = _Mode.expectCommaOrEnd;
      return const JsonEvent(JsonEventType.objectEnd);
    }
    if (b == 0x5D) {
      // ]
      _pos++;
      _stack.removeLast();
      if (_stack.isEmpty) _rootDone = true;
      _mode = _Mode.expectCommaOrEnd;
      return const JsonEvent(JsonEventType.arrayEnd);
    }
    throw JsonParseException(
        'expected "," "}" or "]", got 0x${b.toRadixString(16)}',
        offset: _pos);
  }

  /// 文字列の続きを解析する。完了したら値を返し、未完なら null。
  JsonEvent? _continueString() {
    while (_pos < _buffer.length) {
      final b = _buffer[_pos];
      _pos++;
      if (_stringEscaped) {
        _stringRaw.addByte(b);
        _stringEscaped = false;
        continue;
      }
      if (b == 0x5C) {
        // backslash
        _stringEscaped = true;
        continue;
      }
      if (b == 0x22) {
        // closing quote
        _inString = false;
        final raw = _stringRaw.takeBytes();
        return _decodeString(raw);
      }
      if (b < 0x20) {
        throw const JsonParseException('control character in string');
      }
      _stringRaw.addByte(b);
      if (_stringRaw.length > _maxStringBytes) {
        throw const JsonParseException('string too long');
      }
    }
    return null; // 未完
  }

  String _decodeString(List<int> raw) {
    final s = utf8.decode(raw, allowMalformed: false);
    if (!s.contains(r'\')) return s;
    final buf = StringBuffer();
    var i = 0;
    while (i < s.length) {
      final c = s[i];
      if (c != r'\' || i + 1 >= s.length) {
        buf.write(c);
        i++;
        continue;
      }
      final e = s[i + 1];
      if (e == 'u') {
        if (i + 6 > s.length) {
          throw const JsonParseException('invalid \\u escape');
        }
        final code = _hex4(s.substring(i + 2, i + 6));
        if (code >= 0xD800 &&
            code <= 0xDBFF &&
            i + 12 <= s.length &&
            s[i + 6] == r'\' &&
            s[i + 7] == 'u') {
          final low = _hex4(s.substring(i + 8, i + 12));
          if (low >= 0xDC00 && low <= 0xDFFF) {
            buf.writeCharCode(_combineSurrogate(code, low));
            i += 12;
            continue;
          }
        }
        buf.writeCharCode(code);
        i += 6;
        continue;
      }
      switch (e) {
        case '"':
          buf.write('"');
        case r'\':
          buf.write(r'\');
        case '/':
          buf.write('/');
        case 'b':
          buf.write('\b');
        case 'f':
          buf.write('\f');
        case 'n':
          buf.write('\n');
        case 'r':
          buf.write('\r');
        case 't':
          buf.write('\t');
        default:
          throw JsonParseException('invalid escape \\$e');
      }
      i += 2;
    }
    return buf.toString();
  }

  int _hex4(String s) {
    final v = int.tryParse(s, radix: 16);
    if (v == null) throw const JsonParseException('invalid \\u escape');
    return v;
  }

  int _combineSurrogate(int high, int low) =>
      0x10000 + ((high - 0xD800) << 10) + (low - 0xDC00);

  /// 数値またはリテラルを解析する。区切りが見えるまで確定しない。
  ///
  /// チャンク境界でトークンが途切れた場合は [pos] を進めず null を返す。
  /// [atRoot] が true のときはファイル末尾で区切りなしでも確定する。
  Object? _parseScalar({bool atRoot = false}) {
    final start = _pos;
    final b = _buffer[start];

    if (b == 0x2D || (b >= 0x30 && b <= 0x39)) {
      // 数値
      while (_pos < _buffer.length) {
        final c = _buffer[_pos];
        if ((c >= 0x30 && c <= 0x39) ||
            c == 0x2D ||
            c == 0x2B ||
            c == 0x2E ||
            c == 0x65 ||
            c == 0x45) {
          _pos++;
          if (_pos - start > _maxNumberChars) {
            throw const JsonParseException('number too long');
          }
        } else {
          break;
        }
      }
      final needsDelimiter = _pos < _buffer.length;
      if (!needsDelimiter && !atRoot) {
        _pos = start;
        return null; // 未完
      }
      final s = utf8.decode(_buffer.sublist(start, _pos), allowMalformed: false);
      final v = num.tryParse(s);
      if (v == null) {
        throw JsonParseException('invalid number: $s', offset: start);
      }
      return v;
    }

    // リテラル true / false / null
    const literals = {
      'true': true,
      'false': false,
      'null': null,
    };
    const maxLen = 5; // "false"
    if (_pos + maxLen > _buffer.length && !atRoot) {
      return null; // 未完
    }
    final limit = _pos + maxLen < _buffer.length ? _pos + maxLen : _buffer.length;
    final candidate =
        utf8.decode(_buffer.sublist(start, limit), allowMalformed: false);
    for (final entry in literals.entries) {
      final lit = entry.key;
      if (candidate.startsWith(lit)) {
        // リテラルの直後が区切りかどうか（atRoot では末尾でよい）
        final after = start + lit.length;
        if (after < _buffer.length) {
          final d = _buffer[after];
          final isDelim = d == 0x20 || d == 0x09 || d == 0x0A || d == 0x0D ||
              d == 0x2C || d == 0x7D || d == 0x5D;
          if (!isDelim) {
            throw JsonParseException('invalid literal near "$candidate"',
                offset: start);
          }
        } else if (!atRoot) {
          _pos = start;
          return null;
        }
        _pos = after;
        return entry.value;
      }
    }
    throw JsonParseException('invalid literal near "$candidate"', offset: start);
  }
}
