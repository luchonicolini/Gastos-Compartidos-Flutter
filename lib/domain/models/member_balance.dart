class MemberBalance {
  final String id;
  final String name;
  double balance;

  MemberBalance({
    required this.id,
    required this.name,
    required this.balance,
  });

  bool get isDebtor => balance < -0.01;
  bool get isCreditor => balance > 0.01;
  bool get isNeutral => !isDebtor && !isCreditor;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is MemberBalance && runtimeType == other.runtimeType && id == other.id;

  @override
  int get hashCode => id.hashCode;
}
