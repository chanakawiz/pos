class DeviceSession {
  final String apiUrl;
  final int? storeId;
  final String storeCode;
  final String storeName;
  final int? deviceId;
  final String deviceCode;
  final String deviceName;
  final int? cashierId;
  final String cashierName;
  final String cashierEmail;
  final String? cashSessionUuid;
  final int? cashSessionId;
  final double openingFloat;
  final DateTime? openedAt;
  final bool isPaired;

  const DeviceSession({
    this.apiUrl = 'http://127.0.0.1:8000',
    this.storeId = 1,
    this.storeCode = 'STORE-001',
    this.storeName = 'OmniLuxe Flagship',
    this.deviceId = 1,
    this.deviceCode = 'ROAMING-01',
    this.deviceName = 'Handheld Register 01',
    this.cashierId,
    this.cashierName = '',
    this.cashierEmail = '',
    this.cashSessionUuid,
    this.cashSessionId,
    this.openingFloat = 0.00,
    this.openedAt,
    this.isPaired = true,
  });

  bool get hasActiveShift => cashSessionUuid != null;

  DeviceSession copyWith({
    String? apiUrl,
    int? storeId,
    String? storeCode,
    String? storeName,
    int? deviceId,
    String? deviceCode,
    String? deviceName,
    int? cashierId,
    bool clearCashier = false,
    String? cashierName,
    String? cashierEmail,
    String? cashSessionUuid,
    int? cashSessionId,
    double? openingFloat,
    DateTime? openedAt,
    bool? isPaired,
  }) {
    return DeviceSession(
      apiUrl: apiUrl ?? this.apiUrl,
      storeId: storeId ?? this.storeId,
      storeCode: storeCode ?? this.storeCode,
      storeName: storeName ?? this.storeName,
      deviceId: deviceId ?? this.deviceId,
      deviceCode: deviceCode ?? this.deviceCode,
      deviceName: deviceName ?? this.deviceName,
      cashierId: clearCashier ? null : (cashierId ?? this.cashierId),
      cashierName: clearCashier ? '' : (cashierName ?? this.cashierName),
      cashierEmail: clearCashier ? '' : (cashierEmail ?? this.cashierEmail),
      cashSessionUuid: cashSessionUuid ?? this.cashSessionUuid,
      cashSessionId: cashSessionId ?? this.cashSessionId,
      openingFloat: openingFloat ?? this.openingFloat,
      openedAt: openedAt ?? this.openedAt,
      isPaired: isPaired ?? this.isPaired,
    );
  }

  Map<String, dynamic> toJson() => {
    'apiUrl': apiUrl,
    'storeId': storeId,
    'storeCode': storeCode,
    'storeName': storeName,
    'deviceId': deviceId,
    'deviceCode': deviceCode,
    'deviceName': deviceName,
    'cashierId': cashierId,
    'cashierName': cashierName,
    'cashierEmail': cashierEmail,
    'cashSessionUuid': cashSessionUuid,
    'cashSessionId': cashSessionId,
    'openingFloat': openingFloat,
    'openedAt': openedAt?.toIso8601String(),
    'isPaired': isPaired,
  };

  factory DeviceSession.fromJson(Map<String, dynamic> json) => DeviceSession(
    apiUrl: json['apiUrl'] ?? 'http://127.0.0.1:8000',
    storeId: json['storeId'],
    storeCode: json['storeCode'] ?? 'STORE-001',
    storeName: json['storeName'] ?? 'OmniLuxe Flagship',
    deviceId: json['deviceId'],
    deviceCode: json['deviceCode'] ?? 'ROAMING-01',
    deviceName: json['deviceName'] ?? 'Handheld Register 01',
    cashierId: json['cashierId'],
    cashierName: json['cashierName'] ?? '',
    cashierEmail: json['cashierEmail'] ?? '',
    cashSessionUuid: json['cashSessionUuid'],
    cashSessionId: json['cashSessionId'],
    openingFloat: (json['openingFloat'] as num?)?.toDouble() ?? 0.00,
    openedAt: json['openedAt'] != null ? DateTime.parse(json['openedAt']) : null,
    isPaired: json['isPaired'] ?? false,
  );
}
