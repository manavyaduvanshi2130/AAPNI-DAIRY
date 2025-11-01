class MilkEntry {
  int? id;
  int customerId;
  String date;
  String shift;
  double quantity;
  double fat;
  double snf;
  double rate;
  double amount;

  MilkEntry({
    this.id,
    required this.customerId,
    required this.date,
    required this.shift,
    required this.quantity,
    required this.fat,
    this.snf = 8.0,
    this.rate = 0.0,
    this.amount = 0.0,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'customer_id': customerId,
      'date': date,
      'shift': shift,
      'quantity': quantity,
      'fat': fat,
      'snf': snf,
      'rate': rate,
      'amount': amount,
    };
  }

  factory MilkEntry.fromMap(Map<String, dynamic> map) {
    return MilkEntry(
      id: map['id'],
      customerId: map['customer_id'],
      date: map['date'],
      shift: map['shift'],
      quantity: map['quantity'],
      fat: map['fat'],
      snf: map['snf'] ?? 8.0,
      rate: map['rate'],
      amount: map['amount'],
    );
  }
}
