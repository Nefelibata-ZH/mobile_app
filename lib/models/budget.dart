import 'package:hive/hive.dart';

part 'budget.g.dart';

@HiveType(typeId: 2)
class Budget extends HiveObject {
  Budget({
    required this.id,
    required this.categoryId,
    required this.amount,
    required this.month,
    required this.year,
  });

  @HiveField(0)
  final String id;

  @HiveField(1)
  final String categoryId;

  @HiveField(2)
  final double amount;

  /// 1–12.
  @HiveField(3)
  final int month;

  @HiveField(4)
  final int year;

  Budget copyWith({
    String? id,
    String? categoryId,
    double? amount,
    int? month,
    int? year,
  }) {
    return Budget(
      id: id ?? this.id,
      categoryId: categoryId ?? this.categoryId,
      amount: amount ?? this.amount,
      month: month ?? this.month,
      year: year ?? this.year,
    );
  }

  Map<String, dynamic> toJson() => <String, dynamic>{
        'id': id,
        'categoryId': categoryId,
        'amount': amount,
        'month': month,
        'year': year,
      };

  factory Budget.fromJson(Map<String, dynamic> json) => Budget(
        id: json['id'] as String,
        categoryId: json['categoryId'] as String,
        amount: (json['amount'] as num).toDouble(),
        month: json['month'] as int,
        year: json['year'] as int,
      );
}
