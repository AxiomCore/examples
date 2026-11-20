// GENERATED CODE - DO NOT EDIT.
// axiom_flutter_generator 0.147.5
// py-example: py-example v0.0.6 variant default schema adb9b0e14c48

import 'dart:convert';
import 'dart:typed_data';

import 'package:axiom_flutter/axiom_flutter.dart';

const Object _unset = Object();

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

class Item {
  const Item({
    this.description,
    this.dodo,
    required this.id,
    required this.ownerId,
    required this.title,
  });

  factory Item.fromJson(Object? json) {
    final map = AxiomGeneratedCodec.asObject(json);
    return Item(
      description: map['description'] == null
          ? null
          : AxiomGeneratedCodec.asString(map['description']),
      dodo: map['dodo'] == null
          ? null
          : AxiomGeneratedCodec.asString(map['dodo']),
      id: AxiomGeneratedCodec.asString(map['id']),
      ownerId: AxiomGeneratedCodec.asString(map['owner_id']),
      title: AxiomGeneratedCodec.asString(map['title']),
    );
  }

  final String? description;
  final String? dodo;
  final String id;
  final String ownerId;
  final String title;

  Map<String, dynamic> toJson() => <String, dynamic>{
    if (description case final v?) 'description': v,
    if (dodo case final v?) 'dodo': v,
    'id': id,
    'owner_id': ownerId,
    'title': title,
  };

  Item copyWith({
    Object? description = _unset,
    Object? dodo = _unset,
    String? id,
    String? ownerId,
    String? title,
  }) => Item(
    description: identical(description, _unset)
        ? this.description
        : description as String?,
    dodo: identical(dodo, _unset) ? this.dodo : dodo as String?,
    id: id ?? this.id,
    ownerId: ownerId ?? this.ownerId,
    title: title ?? this.title,
  );

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Item &&
          other.description == description &&
          other.dodo == dodo &&
          other.id == id &&
          other.ownerId == ownerId &&
          other.title == title;

  @override
  int get hashCode => Object.hashAll([description, dodo, id, ownerId, title]);

  @override
  String toString() =>
      'Item(description: $description, dodo: $dodo, id: $id, ownerId: $ownerId, title: $title)';
}

/// Form validators for [Item] built from the contract field
/// rules. Each has the `TextFormField.validator` signature.
abstract final class ItemValidators {
  static String? id(String? value) {
    if (value == null || value.isEmpty) return 'Required';
    return null;
  }

  static String? ownerId(String? value) {
    if (value == null || value.isEmpty) return 'Required';
    return null;
  }

  static String? title(String? value) {
    if (value == null || value.isEmpty) return 'Required';
    return null;
  }

  /// All validators by wire field name.
  static const Map<String, String? Function(String?)> all = {
    'id': id,
    'owner_id': ownerId,
    'title': title,
  };
}

class ItemCreate {
  const ItemCreate({this.description, required this.title});

  factory ItemCreate.fromJson(Object? json) {
    final map = AxiomGeneratedCodec.asObject(json);
    return ItemCreate(
      description: map['description'] == null
          ? null
          : AxiomGeneratedCodec.asString(map['description']),
      title: AxiomGeneratedCodec.asString(map['title']),
    );
  }

  final String? description;
  final String title;

  Map<String, dynamic> toJson() => <String, dynamic>{
    if (description case final v?) 'description': v,
    'title': title,
  };

  ItemCreate copyWith({Object? description = _unset, String? title}) =>
      ItemCreate(
        description: identical(description, _unset)
            ? this.description
            : description as String?,
        title: title ?? this.title,
      );

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ItemCreate &&
          other.description == description &&
          other.title == title;

  @override
  int get hashCode => Object.hashAll([description, title]);

  @override
  String toString() => 'ItemCreate(description: $description, title: $title)';
}

/// Form validators for [ItemCreate] built from the contract field
/// rules. Each has the `TextFormField.validator` signature.
abstract final class ItemCreateValidators {
  static String? title(String? value) {
    if (value == null || value.isEmpty) return 'Required';
    return null;
  }

  /// All validators by wire field name.
  static const Map<String, String? Function(String?)> all = {'title': title};
}

class Token {
  const Token({required this.accessToken, required this.tokenType});

  factory Token.fromJson(Object? json) {
    final map = AxiomGeneratedCodec.asObject(json);
    return Token(
      accessToken: AxiomGeneratedCodec.asString(map['access_token']),
      tokenType: AxiomGeneratedCodec.asString(map['token_type']),
    );
  }

  final String accessToken;
  final String tokenType;

  Map<String, dynamic> toJson() => <String, dynamic>{
    'access_token': accessToken,
    'token_type': tokenType,
  };

  Token copyWith({String? accessToken, String? tokenType}) => Token(
    accessToken: accessToken ?? this.accessToken,
    tokenType: tokenType ?? this.tokenType,
  );

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Token &&
          other.accessToken == accessToken &&
          other.tokenType == tokenType;

  @override
  int get hashCode => Object.hashAll([accessToken, tokenType]);

  @override
  String toString() =>
      'Token(accessToken: $accessToken, tokenType: $tokenType)';
}

/// Form validators for [Token] built from the contract field
/// rules. Each has the `TextFormField.validator` signature.
abstract final class TokenValidators {
  static String? accessToken(String? value) {
    if (value == null || value.isEmpty) return 'Required';
    return null;
  }

  static String? tokenType(String? value) {
    if (value == null || value.isEmpty) return 'Required';
    return null;
  }

  /// All validators by wire field name.
  static const Map<String, String? Function(String?)> all = {
    'access_token': accessToken,
    'token_type': tokenType,
  };
}

class User {
  const User({required this.email, required this.id, required this.role});

  factory User.fromJson(Object? json) {
    final map = AxiomGeneratedCodec.asObject(json);
    return User(
      email: map['email'],
      id: AxiomGeneratedCodec.asString(map['id']),
      role: AxiomGeneratedCodec.asString(map['role']),
    );
  }

  final Object? email;
  final String id;
  final String role;

  Map<String, dynamic> toJson() => <String, dynamic>{
    'email': email,
    'id': id,
    'role': role,
  };

  User copyWith({Object? email, String? id, String? role}) => User(
    email: email ?? this.email,
    id: id ?? this.id,
    role: role ?? this.role,
  );

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is User &&
          AxiomGeneratedCodec.deepEquals(other.email, email) &&
          other.id == id &&
          other.role == role;

  @override
  int get hashCode =>
      Object.hashAll([AxiomGeneratedCodec.deepHash(email), id, role]);

  @override
  String toString() => 'User(email: $email, id: $id, role: $role)';
}

/// Form validators for [User] built from the contract field
/// rules. Each has the `TextFormField.validator` signature.
abstract final class UserValidators {
  static String? id(String? value) {
    if (value == null || value.isEmpty) return 'Required';
    return null;
  }

  static String? role(String? value) {
    if (value == null || value.isEmpty) return 'Required';
    return null;
  }

  /// All validators by wire field name.
  static const Map<String, String? Function(String?)> all = {
    'id': id,
    'role': role,
  };
}

class UserCreate {
  const UserCreate({required this.email, required this.password});

  factory UserCreate.fromJson(Object? json) {
    final map = AxiomGeneratedCodec.asObject(json);
    return UserCreate(
      email: map['email'],
      password: AxiomGeneratedCodec.asString(map['password']),
    );
  }

  final Object? email;
  final String password;

  Map<String, dynamic> toJson() => <String, dynamic>{
    'email': email,
    'password': password,
  };

  UserCreate copyWith({Object? email, String? password}) => UserCreate(
    email: email ?? this.email,
    password: password ?? this.password,
  );

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is UserCreate &&
          AxiomGeneratedCodec.deepEquals(other.email, email) &&
          other.password == password;

  @override
  int get hashCode =>
      Object.hashAll([AxiomGeneratedCodec.deepHash(email), password]);

  @override
  String toString() => 'UserCreate(email: $email, password: $password)';
}

/// Form validators for [UserCreate] built from the contract field
/// rules. Each has the `TextFormField.validator` signature.
abstract final class UserCreateValidators {
  static String? password(String? value) {
    if (value == null || value.isEmpty) return 'Required';
    return null;
  }

  /// All validators by wire field name.
  static const Map<String, String? Function(String?)> all = {
    'password': password,
  };
}
