import 'package:hive/hive.dart';

part 'category.g.dart';

@HiveType(typeId: 1)
class Category extends HiveObject {
  Category({
    required this.id,
    required this.name,
    required this.icon,
    required this.color,
    required this.type,
  });

  @HiveField(0)
  final String id;

  @HiveField(1)
  final String name;

  /// Material Icon name, e.g. "restaurant", "directions_car".
  @HiveField(2)
  final String icon;

  /// ARGB color value.
  @HiveField(3)
  final int color;

  /// "income" or "expense".
  @HiveField(4)
  final String type;

  bool get isIncome => type == 'income';

  Category copyWith({
    String? id,
    String? name,
    String? icon,
    int? color,
    String? type,
  }) {
    return Category(
      id: id ?? this.id,
      name: name ?? this.name,
      icon: icon ?? this.icon,
      color: color ?? this.color,
      type: type ?? this.type,
    );
  }

  Map<String, dynamic> toJson() => <String, dynamic>{
        'id': id,
        'name': name,
        'icon': icon,
        'color': color,
        'type': type,
      };

  factory Category.fromJson(Map<String, dynamic> json) => Category(
        id: json['id'] as String,
        name: json['name'] as String,
        icon: json['icon'] as String,
        color: json['color'] as int,
        type: json['type'] as String,
      );
}
