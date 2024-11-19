import 'dart:convert';

import 'package:json_annotation/json_annotation.dart';

part 'attribute.g.dart';

@JsonSerializable()
class Attribute {
  String? body;
  String? url;
  String? cardId;
  Attribute({this.body, this.url, this.cardId});

  factory Attribute.fromJson(Map<String, dynamic> json) => _$AttributeFromJson(json);

  Map<String, dynamic> toJson() => _$AttributeToJson(this);

  @override
  String toString() {
    return jsonEncode(this);
  }
}
