// GENERATED CODE - DO NOT EDIT.
// axiom_flutter_generator 0.147.5
// realtime-chat: go-chat v0.1.0 variant default schema 7133b3dd3e55

import 'dart:convert';
import 'dart:typed_data';

import 'package:axiom_flutter/axiom_flutter.dart';

/// JSON helpers used by the generated models and client.
abstract final class AxiomGeneratedCodec {
  static String asString(Object? v) => v as String;
  static bool asBool(Object? v) => v as bool;
  static Object? asJson(Object? v) => v;
  static void asVoid(Object? v) {}

  static int asInt(Object? v) => switch (v) {
    int() => v,
    num() => v.toInt(),
    String() => int.parse(v),
    _ => throw FormatException('expected an integer, got $v'),
  };

  static double asDouble(Object? v) => switch (v) {
    num() => v.toDouble(),
    String() => double.parse(v),
    _ => throw FormatException('expected a number, got $v'),
  };

  static DateTime asDateTime(Object? v) => switch (v) {
    String() => DateTime.parse(v),
    int() => DateTime.fromMillisecondsSinceEpoch(v, isUtc: true),
    _ => throw FormatException('expected a date-time, got $v'),
  };

  /// Bytes travel as base64 strings; a list of ints is accepted too.
  static Uint8List asBytes(Object? v) => switch (v) {
    String() => base64Decode(v),
    List() => Uint8List.fromList(v.cast<int>()),
    _ => throw FormatException('expected bytes, got $v'),
  };

  static String bytesToJson(Uint8List v) => base64Encode(v);

  static Map<String, dynamic> asObject(Object? v) =>
      (v as Map).cast<String, dynamic>();

  static List<T> asList<T>(Object? v, T Function(Object?) item) => [
    for (final e in v as List) item(e),
  ];

  static Map<String, T> asMap<T>(Object? v, T Function(Object?) value) => {
    for (final e in (v as Map).entries) e.key as String: value(e.value),
  };

  static Map<K, T> asKeyedMap<K, T>(
    Object? v,
    K Function(String) key,
    T Function(Object?) value,
  ) => {
    for (final e in (v as Map).entries) key(e.key as String): value(e.value),
  };

  static bool deepEquals(Object? a, Object? b) {
    if (identical(a, b)) return true;
    if (a is List && b is List) {
      if (a.length != b.length) return false;
      for (var i = 0; i < a.length; i++) {
        if (!deepEquals(a[i], b[i])) return false;
      }
      return true;
    }
    if (a is Map && b is Map) {
      if (a.length != b.length) return false;
      for (final e in a.entries) {
        if (!b.containsKey(e.key) || !deepEquals(e.value, b[e.key])) {
          return false;
        }
      }
      return true;
    }
    return a == b;
  }

  static int deepHash(Object? v) => switch (v) {
    List() => Object.hashAll(v.map(deepHash)),
    Map() => Object.hashAllUnordered(
      v.entries.map((e) => Object.hash(deepHash(e.key), deepHash(e.value))),
    ),
    _ => v.hashCode,
  };

  /// Code and payload of a contract failure carried by [error]: the
  /// runtime's `failureCode`/`failurePayload`, else the server body in
  /// `details` (`{"error": {"code": ..., "payload": ...}}`).
  static (String?, Object?) failureParts(AxiomError error) {
    if (error.failureCode != null) {
      return (error.failureCode, error.failurePayload);
    }
    final details = error.details;
    if (details == null || details.isEmpty) return (null, null);
    try {
      final decoded = jsonDecode(details);
      if (decoded is Map) {
        final body = decoded['error'] is Map
            ? decoded['error'] as Map
            : decoded;
        final code = body['code'] ?? body['failure_code'];
        if (code is String) {
          return (code, body['payload'] ?? body['failure_payload']);
        }
      }
    } on FormatException {
      return (null, null);
    }
    return (null, null);
  }
}

class ChatMessage {
  const ChatMessage({
    required this.content,
    required this.sender,
    required this.timestamp,
  });

  factory ChatMessage.fromJson(Object? json) {
    final map = AxiomGeneratedCodec.asObject(json);
    return ChatMessage(
      content: AxiomGeneratedCodec.asString(map['content']),
      sender: AxiomGeneratedCodec.asString(map['sender']),
      timestamp: AxiomGeneratedCodec.asString(map['timestamp']),
    );
  }

  final String content;
  final String sender;
  final String timestamp;

  Map<String, dynamic> toJson() => <String, dynamic>{
    'content': content,
    'sender': sender,
    'timestamp': timestamp,
  };

  ChatMessage copyWith({String? content, String? sender, String? timestamp}) =>
      ChatMessage(
        content: content ?? this.content,
        sender: sender ?? this.sender,
        timestamp: timestamp ?? this.timestamp,
      );

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ChatMessage &&
          other.content == content &&
          other.sender == sender &&
          other.timestamp == timestamp;

  @override
  int get hashCode => Object.hashAll([content, sender, timestamp]);

  @override
  String toString() =>
      'ChatMessage(content: $content, sender: $sender, timestamp: $timestamp)';
}
