class CashItemModel {
  String name;
  double amount;
  bool isFixed;

  CashItemModel({
    required this.name,
    required this.amount,
    this.isFixed = true,
  });
}