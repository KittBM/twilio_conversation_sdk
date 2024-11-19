// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'attribute.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

Attribute _$AttributeFromJson(Map<String, dynamic> json) => Attribute(
      body: json['body'] as String?,
      url: json['url'] as String?,
      cardId: json['cardId'] as String?,
    );

Map<String, dynamic> _$AttributeToJson(Attribute instance) => <String, dynamic>{
      'body': instance.body,
      'url': instance.url,
      'cardId': instance.cardId,
    };
