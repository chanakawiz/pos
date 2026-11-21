class PosCustomer {
  final int? id;
  final String uuid;
  final String name;
  final String phone;
  final String? email;
  final String vipTier; // 'silver', 'gold', 'black'
  final int loyaltyPoints;
  final double totalSpend;
  final double creditLimit;

  const PosCustomer({
    this.id,
    required this.uuid,
    required this.name,
    required this.phone,
    this.email,
    this.vipTier = 'silver',
    this.loyaltyPoints = 0,
    this.totalSpend = 0.0,
    this.creditLimit = 0.0,
  });

  String get normalizedTier {
    final t = vipTier.toLowerCase();
    if (t.contains('black') || t.contains('diamond') || t.contains('platinum')) {
      return 'black';
    }
    if (t.contains('gold') || t.contains('elite')) {
      return 'gold';
    }
    return 'silver';
  }

  String get tierTitle {
    switch (normalizedTier) {
      case 'black':
        return 'Black Diamond';
      case 'gold':
        return 'Gold Elite';
      default:
        return 'Silver Privilege';
    }
  }

  double get tierDiscountPercent {
    switch (normalizedTier) {
      case 'black':
        return 10.0;
      case 'gold':
        return 5.0;
      default:
        return 0.0;
    }
  }

  double get pointsMultiplier {
    switch (normalizedTier) {
      case 'black':
        return 2.0;
      case 'gold':
        return 1.5;
      default:
        return 1.0;
    }
  }

  String get maskedPhone {
    final digits = phone.replaceAll(RegExp(r'\s+'), '');
    if (digits.length < 6) return phone;
    final prefix = digits.substring(0, digits.length >= 10 ? 5 : 3);
    final suffix = digits.substring(digits.length - 3);
    return '$prefix •••• $suffix';
  }

  factory PosCustomer.fromJson(Map<String, dynamic> json) {
    return PosCustomer(
      id: json['id'] is int ? json['id'] : int.tryParse(json['id']?.toString() ?? ''),
      uuid: json['uuid']?.toString() ?? 'cust-${json['id'] ?? 'local'}',
      name: json['name']?.toString() ?? 'VIP Customer',
      phone: json['phone']?.toString() ?? '',
      email: json['email']?.toString(),
      vipTier: json['vip_tier']?.toString() ?? json['tier_title']?.toString() ?? 'silver',
      loyaltyPoints: (json['loyalty_points'] as num?)?.toInt() ?? 0,
      totalSpend: (json['total_spend'] as num?)?.toDouble() ?? 0.0,
      creditLimit: (json['credit_limit'] as num?)?.toDouble() ?? 0.0,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'uuid': uuid,
    'name': name,
    'phone': phone,
    'email': email,
    'vip_tier': normalizedTier,
    'loyalty_points': loyaltyPoints,
    'total_spend': totalSpend,
    'credit_limit': creditLimit,
  };
}
