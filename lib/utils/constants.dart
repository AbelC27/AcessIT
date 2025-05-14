class AppConstants {
  // API endpoints
  static const String gateApiBaseUrl = 'http://192.168.0.100:5000';
  static const String validateEndpoint = '/validate';
  static const String logsEndpoint = '/logs';

  // BLE settings
  static const String bleDeviceName = 'ESP32_GATE';
  static const String bleServiceUuid = '12345678-1234-5678-1234-56789abcdef0';
  static const String bleCharacteristicUuid =
      'abcdef12-3456-7890-abcd-ef1234567890';

  // Secure storage keys
  static const String keyAccessCode = 'access_code';
  static const String keyUserId = 'user_id';
}
