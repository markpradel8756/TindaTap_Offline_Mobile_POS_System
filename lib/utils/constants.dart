class AppConstants {
  static const String appName = 'TindaTap';
  static const String databaseName = 'tindatap.db';

  static const String settingStoreName = 'store_name';
  static const String settingCurrency = 'currency';
  static const String settingPinEnabled = 'pin_enabled';
  static const String settingPinHash = 'pin_hash';
  static const String settingSecurityQuestion = 'security_question';
  static const String settingSecurityAnswerHash = 'security_answer_hash';
  static const String settingLowStockThreshold = 'low_stock_threshold';
  static const String settingPinTimeoutMinutes = 'pin_timeout_minutes';

  static const int defaultLowStockThreshold = 5;
  static const int defaultPinTimeoutMinutes = 5;

  static const List<String> supportedCurrencyCodes = [
    'PHP',
    'USD',
    'EUR',
    'GBP'
  ];

  static const Map<String, String> currencySymbols = {
    'PHP': '₱',
    'USD': r'$',
    'EUR': '€',
    'GBP': '£',
  };
}
