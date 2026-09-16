// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'favorites.swagger.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

FavoriteCreate _$FavoriteCreateFromJson(Map<String, dynamic> json) =>
    FavoriteCreate(
      productId: (json['product_id'] as num).toInt(),
    );

Map<String, dynamic> _$FavoriteCreateToJson(FavoriteCreate instance) =>
    <String, dynamic>{
      'product_id': instance.productId,
    };

FavoriteResponse _$FavoriteResponseFromJson(Map<String, dynamic> json) =>
    FavoriteResponse(
      id: (json['id'] as num).toInt(),
      productId: (json['product_id'] as num).toInt(),
      createdAt: DateTime.parse(json['created_at'] as String),
    );

Map<String, dynamic> _$FavoriteResponseToJson(FavoriteResponse instance) =>
    <String, dynamic>{
      'id': instance.id,
      'product_id': instance.productId,
      'created_at': instance.createdAt.toIso8601String(),
    };

ValidationError _$ValidationErrorFromJson(Map<String, dynamic> json) =>
    ValidationError(
      loc: (json['loc'] as List<dynamic>?)?.map((e) => e as String).toList() ??
          [],
      msg: json['msg'] as String,
      type: json['type'] as String,
    );

Map<String, dynamic> _$ValidationErrorToJson(ValidationError instance) =>
    <String, dynamic>{
      'loc': instance.loc,
      'msg': instance.msg,
      'type': instance.type,
    };

HTTPValidationError _$HTTPValidationErrorFromJson(Map<String, dynamic> json) =>
    HTTPValidationError(
      detail: (json['detail'] as List<dynamic>?)
              ?.map((e) => ValidationError.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
    );

Map<String, dynamic> _$HTTPValidationErrorToJson(
        HTTPValidationError instance) =>
    <String, dynamic>{
      'detail': instance.detail?.map((e) => e.toJson()).toList(),
    };
