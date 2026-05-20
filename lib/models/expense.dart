import 'package:hive/hive.dart';

part 'expense.g.dart';

@HiveType(typeId: 0)
class Expense extends HiveObject {
  Expense({
    required this.id,
    required this.amount,
    required this.category,
    required this.date,
    required this.paymentMethod,
    this.note,
  });

  @HiveField(0)
  final String id;

  /// Positive = income, negative = expense.
  @HiveField(1)
  final double amount;

  @HiveField(2)
  final String category;

  @HiveField(3)
  final DateTime date;

  @HiveField(4)
  final String? note;

  @HiveField(5)
  final String paymentMethod;

  bool get isIncome => amount >= 0;

  Expense copyWith({
    String? id,
    double? amount,
    String? category,
    DateTime? date,
    String? note,
    String? paymentMethod,
  }) {
    return Expense(
      id: id ?? this.id,
      amount: amount ?? this.amount,
      category: category ?? this.category,
      date: date ?? this.date,
      note: note ?? this.note,
      paymentMethod: paymentMethod ?? this.paymentMethod,
    );
  }

  Map<String, dynamic> toJson() => <String, dynamic>{
        'id': id,
        'amount': amount,
        'category': category,
        'date': date.toIso8601String(),
        'note': note,
        'paymentMethod': paymentMethod,
      };

  factory Expense.fromJson(Map<String, dynamic> json) => Expense(
        id: json['id'] as String,
        amount: (json['amount'] as num).toDouble(),
        category: json['category'] as String,
        date: DateTime.parse(json['date'] as String),
        note: json['note'] as String?,
        paymentMethod: json['paymentMethod'] as String,
      );
}
