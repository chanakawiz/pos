class CustomerModel {
  final int? id;
  final String uuid;
  final String name;
  final String? phone;
  final String? email;
  final String? address;
  final int loyaltyPoints;
  final double creditLimit;
  final double balance;
  final int version;

  const CustomerModel({
    this.id,
    required this.uuid,
    required this.name,
    this.phone,
    this.email,
    this.address,
    this.loyaltyPoints = 0,
    this.creditLimit = 0.0,
    this.balance = 0.0,
    this.version = 1,
  });

  factory CustomerModel.fromJson(Map<String, dynamic> json) {
    return CustomerModel(
      id: json['id'] is int ? json['id'] : null,
      uuid: json['uuid']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
      phone: json['phone']?.toString(),
      email: json['email']?.toString(),
      address: json['address']?.toString(),
      loyaltyPoints: (json['loyalty_points'] is int) ? json['loyalty_points'] : 0,
      creditLimit: (json['credit_limit'] is num) ? (json['credit_limit'] as num).toDouble() : 0.0,
      balance: (json['balance'] is num) ? (json['balance'] as num).toDouble() : 0.0,
      version: (json['version'] is int) ? json['version'] : 1,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'uuid': uuid,
      'name': name,
      'phone': phone,
      'email': email,
      'address': address,
      'loyalty_points': loyaltyPoints,
      'credit_limit': creditLimit,
      'balance': balance,
      'version': version,
    };
  }

  factory CustomerModel.fromDbMap(Map<String, dynamic> map) {
    return CustomerModel(
      id: map['id'] as int?,
      uuid: map['uuid'] as String,
      name: map['name'] as String,
      phone: map['phone'] as String?,
      email: map['email'] as String?,
      address: map['address'] as String?,
      loyaltyPoints: (map['loyalty_points'] as int?) ?? 0,
      creditLimit: (map['credit_limit'] as num?)?.toDouble() ?? 0.0,
      balance: (map['balance'] as num?)?.toDouble() ?? 0.0,
      version: (map['version'] as int?) ?? 1,
    );
  }

  Map<String, dynamic> toDbMap() {
    return {
      'uuid': uuid,
      'name': name,
      'phone': phone,
      'email': email,
      'address': address,
      'loyalty_points': loyaltyPoints,
      'credit_limit': creditLimit,
      'balance': balance,
      'version': version,
    };
  }
}
