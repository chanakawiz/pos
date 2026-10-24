class StoreModel {
  final String uuid;
  final String name;
  final String? code;
  final String currencySymbol;
  final String currencyCode;
  final String? address;
  final String? phone;
  final String? receiptHeader;
  final String? receiptFooter;

  const StoreModel({
    required this.uuid,
    required this.name,
    this.code,
    this.currencySymbol = 'Rs.',
    this.currencyCode = 'LKR',
    this.address,
    this.phone,
    this.receiptHeader,
    this.receiptFooter,
  });

  factory StoreModel.fromJson(Map<String, dynamic> json) {
    return StoreModel(
      uuid: json['uuid']?.toString() ?? '',
      name: json['name']?.toString() ?? 'SmartShop Store',
      code: json['code']?.toString(),
      currencySymbol: json['currency_symbol']?.toString() ?? 'Rs.',
      currencyCode: json['currency_code']?.toString() ?? 'LKR',
      address: json['address']?.toString(),
      phone: json['phone']?.toString(),
      receiptHeader: json['receipt_header']?.toString(),
      receiptFooter: json['receipt_footer']?.toString(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'uuid': uuid,
      'name': name,
      'code': code,
      'currency_symbol': currencySymbol,
      'currency_code': currencyCode,
      'address': address,
      'phone': phone,
      'receipt_header': receiptHeader,
      'receipt_footer': receiptFooter,
    };
  }
}

class UserModel {
  final String uuid;
  final String name;
  final String email;
  final String role;
  final StoreModel? store;

  const UserModel({
    required this.uuid,
    required this.name,
    required this.email,
    required this.role,
    this.store,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      uuid: json['uuid']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
      email: json['email']?.toString() ?? '',
      role: json['role']?.toString() ?? 'cashier',
      store: json['store'] is Map<String, dynamic>
          ? StoreModel.fromJson(json['store'] as Map<String, dynamic>)
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'uuid': uuid,
      'name': name,
      'email': email,
      'role': role,
      'store': store?.toJson(),
    };
  }
}
