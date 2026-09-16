// ignore_for_file: type=lint

import 'package:json_annotation/json_annotation.dart';
import 'package:collection/collection.dart';
import 'dart:convert';

part 'favorites.swagger.g.dart';

@JsonSerializable(explicitToJson: true)
class FavoriteCreate {
  const FavoriteCreate({required this.productId});

  factory FavoriteCreate.fromJson(Map<String, dynamic> json) =>
      _$FavoriteCreateFromJson(json);

  static const toJsonFactory = _$FavoriteCreateToJson;
  Map<String, dynamic> toJson() => _$FavoriteCreateToJson(this);

  @JsonKey(name: 'product_id')
  final int productId;
  static const fromJsonFactory = _$FavoriteCreateFromJson;

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other is FavoriteCreate &&
            (identical(other.productId, productId) ||
                const DeepCollectionEquality().equals(
                  other.productId,
                  productId,
                )));
  }

  @override
  String toString() => jsonEncode(this);

  @override
  int get hashCode =>
      const DeepCollectionEquality().hash(productId) ^ runtimeType.hashCode;
}

extension $FavoriteCreateExtension on FavoriteCreate {
  FavoriteCreate copyWith({int? productId}) {
    return FavoriteCreate(productId: productId ?? this.productId);
  }

  FavoriteCreate copyWithWrapped({Wrapped<int>? productId}) {
    return FavoriteCreate(
      productId: (productId != null ? productId.value : this.productId),
    );
  }
}

@JsonSerializable(explicitToJson: true)
class FavoriteResponse {
  const FavoriteResponse({
    required this.id,
    required this.productId,
    required this.createdAt,
  });

  factory FavoriteResponse.fromJson(Map<String, dynamic> json) =>
      _$FavoriteResponseFromJson(json);

  static const toJsonFactory = _$FavoriteResponseToJson;
  Map<String, dynamic> toJson() => _$FavoriteResponseToJson(this);

  @JsonKey(name: 'id')
  final int id;
  @JsonKey(name: 'product_id')
  final int productId;
  @JsonKey(name: 'created_at')
  final DateTime createdAt;
  static const fromJsonFactory = _$FavoriteResponseFromJson;

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other is FavoriteResponse &&
            (identical(other.id, id) ||
                const DeepCollectionEquality().equals(other.id, id)) &&
            (identical(other.productId, productId) ||
                const DeepCollectionEquality().equals(
                  other.productId,
                  productId,
                )) &&
            (identical(other.createdAt, createdAt) ||
                const DeepCollectionEquality().equals(
                  other.createdAt,
                  createdAt,
                )));
  }

  @override
  String toString() => jsonEncode(this);

  @override
  int get hashCode =>
      const DeepCollectionEquality().hash(id) ^
      const DeepCollectionEquality().hash(productId) ^
      const DeepCollectionEquality().hash(createdAt) ^
      runtimeType.hashCode;
}

extension $FavoriteResponseExtension on FavoriteResponse {
  FavoriteResponse copyWith({int? id, int? productId, DateTime? createdAt}) {
    return FavoriteResponse(
      id: id ?? this.id,
      productId: productId ?? this.productId,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  FavoriteResponse copyWithWrapped({
    Wrapped<int>? id,
    Wrapped<int>? productId,
    Wrapped<DateTime>? createdAt,
  }) {
    return FavoriteResponse(
      id: (id != null ? id.value : this.id),
      productId: (productId != null ? productId.value : this.productId),
      createdAt: (createdAt != null ? createdAt.value : this.createdAt),
    );
  }
}

@JsonSerializable(explicitToJson: true)
class ValidationError {
  const ValidationError({
    required this.loc,
    required this.msg,
    required this.type,
  });

  factory ValidationError.fromJson(Map<String, dynamic> json) =>
      _$ValidationErrorFromJson(json);

  static const toJsonFactory = _$ValidationErrorToJson;
  Map<String, dynamic> toJson() => _$ValidationErrorToJson(this);

  @JsonKey(name: 'loc', defaultValue: <String>[])
  final List<String> loc;
  @JsonKey(name: 'msg')
  final String msg;
  @JsonKey(name: 'type')
  final String type;
  static const fromJsonFactory = _$ValidationErrorFromJson;

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other is ValidationError &&
            (identical(other.loc, loc) ||
                const DeepCollectionEquality().equals(other.loc, loc)) &&
            (identical(other.msg, msg) ||
                const DeepCollectionEquality().equals(other.msg, msg)) &&
            (identical(other.type, type) ||
                const DeepCollectionEquality().equals(other.type, type)));
  }

  @override
  String toString() => jsonEncode(this);

  @override
  int get hashCode =>
      const DeepCollectionEquality().hash(loc) ^
      const DeepCollectionEquality().hash(msg) ^
      const DeepCollectionEquality().hash(type) ^
      runtimeType.hashCode;
}

extension $ValidationErrorExtension on ValidationError {
  ValidationError copyWith({List<String>? loc, String? msg, String? type}) {
    return ValidationError(
      loc: loc ?? this.loc,
      msg: msg ?? this.msg,
      type: type ?? this.type,
    );
  }

  ValidationError copyWithWrapped({
    Wrapped<List<String>>? loc,
    Wrapped<String>? msg,
    Wrapped<String>? type,
  }) {
    return ValidationError(
      loc: (loc != null ? loc.value : this.loc),
      msg: (msg != null ? msg.value : this.msg),
      type: (type != null ? type.value : this.type),
    );
  }
}

@JsonSerializable(explicitToJson: true)
class HTTPValidationError {
  const HTTPValidationError({this.detail});

  factory HTTPValidationError.fromJson(Map<String, dynamic> json) =>
      _$HTTPValidationErrorFromJson(json);

  static const toJsonFactory = _$HTTPValidationErrorToJson;
  Map<String, dynamic> toJson() => _$HTTPValidationErrorToJson(this);

  @JsonKey(name: 'detail', defaultValue: <ValidationError>[])
  final List<ValidationError>? detail;
  static const fromJsonFactory = _$HTTPValidationErrorFromJson;

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other is HTTPValidationError &&
            (identical(other.detail, detail) ||
                const DeepCollectionEquality().equals(other.detail, detail)));
  }

  @override
  String toString() => jsonEncode(this);

  @override
  int get hashCode =>
      const DeepCollectionEquality().hash(detail) ^ runtimeType.hashCode;
}

extension $HTTPValidationErrorExtension on HTTPValidationError {
  HTTPValidationError copyWith({List<ValidationError>? detail}) {
    return HTTPValidationError(detail: detail ?? this.detail);
  }

  HTTPValidationError copyWithWrapped({
    Wrapped<List<ValidationError>?>? detail,
  }) {
    return HTTPValidationError(
      detail: (detail != null ? detail.value : this.detail),
    );
  }
}

// ignore: unused_element
String? _dateToJson(DateTime? date) {
  if (date == null) {
    return null;
  }

  final year = date.year.toString();
  final month = date.month < 10 ? '0${date.month}' : date.month.toString();
  final day = date.day < 10 ? '0${date.day}' : date.day.toString();

  return '$year-$month-$day';
}

class Wrapped<T> {
  final T value;
  const Wrapped.value(this.value);
}
