import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path/path.dart' as path;
import 'package:path_provider/path_provider.dart';

import '../database/database_helper.dart';
import '../models/qr_code.dart';
import '../utils/constants.dart';
import '../utils/helpers.dart';

class SettingsProvider extends ChangeNotifier {
  final DatabaseHelper _databaseHelper = DatabaseHelper.instance;

  bool _initialized = false;
  String _storeName = '';
  String _currencyCode = 'PHP';
  bool _pinEnabled = false;
  String _pinHash = '';
  String _securityQuestion = '';
  String _securityAnswerHash = '';
  int _lowStockThreshold = AppConstants.defaultLowStockThreshold;
  int _pinTimeoutMinutes = AppConstants.defaultPinTimeoutMinutes;
  List<QrCodeEntry> _qrCodes = [];

  /// Indicates whether settings have finished loading from persistent storage.
  bool get initialized => _initialized;

  /// Returns the saved store name shown throughout the app.
  String get storeName => _storeName;

  /// Returns the currently selected currency code.
  String get currencyCode => _currencyCode;

  /// Returns the matching currency symbol for the active currency code.
  String get currencySymbol => Helpers.currencySymbol(_currencyCode);

  /// Returns true when app PIN protection is enabled.
  bool get pinEnabled => _pinEnabled;

  /// Returns the stored hash of the current PIN.
  String get pinHash => _pinHash;

  /// Returns the security question used for PIN recovery.
  String get securityQuestion => _securityQuestion;

  /// Returns the stored hash of the security answer.
  String get securityAnswerHash => _securityAnswerHash;

  /// Returns the configured low-stock threshold used in inventory checks.
  int get lowStockThreshold => _lowStockThreshold;

  /// Returns the number of idle minutes before the app locks itself.
  int get pinTimeoutMinutes => _pinTimeoutMinutes;

  /// Returns the cached QR codes as a read-only list.
  List<QrCodeEntry> get qrCodes => List.unmodifiable(_qrCodes);

  /// Reports whether setup is complete enough to enter the main app.
  bool get isSetupComplete => _storeName.trim().isNotEmpty;

  /// Loads all persisted settings and cached QR codes into memory.
  Future<void> loadSettings() async {
    final settings = await _databaseHelper.getSettingsMap();
    _storeName = settings[AppConstants.settingStoreName] ?? '';
    _currencyCode = settings[AppConstants.settingCurrency] ?? 'PHP';
    _pinEnabled =
        (settings[AppConstants.settingPinEnabled] ?? 'false') == 'true';
    _pinHash = settings[AppConstants.settingPinHash] ?? '';
    _securityQuestion = settings[AppConstants.settingSecurityQuestion] ?? '';
    _securityAnswerHash =
        settings[AppConstants.settingSecurityAnswerHash] ?? '';
    _lowStockThreshold =
        int.tryParse(settings[AppConstants.settingLowStockThreshold] ?? '') ??
            AppConstants.defaultLowStockThreshold;
    _pinTimeoutMinutes =
        int.tryParse(settings[AppConstants.settingPinTimeoutMinutes] ?? '') ??
            AppConstants.defaultPinTimeoutMinutes;
    _qrCodes = await _databaseHelper.getQrCodes();
    _initialized = true;
    notifyListeners();
  }

  /// Refreshes the QR code list from the database.
  Future<void> refreshQrCodes() async {
    _qrCodes = await _databaseHelper.getQrCodes();
    notifyListeners();
  }

  /// Saves a new store name and keeps the in-memory value in sync.
  Future<void> updateStoreName(String value) async {
    final trimmed = value.trim();
    await _databaseHelper.setSettingValue(
        AppConstants.settingStoreName, trimmed);
    _storeName = trimmed;
    notifyListeners();
  }

  /// Stores a new currency code, falling back to PHP if the value is invalid.
  Future<void> updateCurrencyCode(String value) async {
    final normalized =
        AppConstants.supportedCurrencyCodes.contains(value.toUpperCase())
            ? value.toUpperCase()
            : 'PHP';
    await _databaseHelper.setSettingValue(
        AppConstants.settingCurrency, normalized);
    _currencyCode = normalized;
    notifyListeners();
  }

  /// Saves the low-stock threshold while preventing negative values.
  Future<void> updateLowStockThreshold(int value) async {
    final threshold = value < 0 ? 0 : value;
    await _databaseHelper.setSettingValue(
      AppConstants.settingLowStockThreshold,
      threshold.toString(),
    );
    _lowStockThreshold = threshold;
    notifyListeners();
  }

  /// Saves the PIN timeout, enforcing a minimum of one minute.
  Future<void> updatePinTimeoutMinutes(int value) async {
    final timeout = value < 1 ? 1 : value;
    await _databaseHelper.setSettingValue(
      AppConstants.settingPinTimeoutMinutes,
      timeout.toString(),
    );
    _pinTimeoutMinutes = timeout;
    notifyListeners();
  }

  /// Disables PIN protection and clears all recovery data.
  Future<void> disablePin() async {
    _pinEnabled = false;
    _pinHash = '';
    _securityQuestion = '';
    _securityAnswerHash = '';

    await _databaseHelper.setSettingValue(
        AppConstants.settingPinEnabled, 'false');
    await _databaseHelper.setSettingValue(AppConstants.settingPinHash, '');
    await _databaseHelper.setSettingValue(
        AppConstants.settingSecurityQuestion, '');
    await _databaseHelper.setSettingValue(
        AppConstants.settingSecurityAnswerHash, '');
    notifyListeners();
  }

  /// Stores a freshly configured PIN, security question, and answer hash.
  Future<void> savePinConfiguration({
    required String pin,
    required String securityQuestion,
    required String securityAnswer,
  }) async {
    _pinHash = Helpers.sha256Hash(pin);
    _securityQuestion = securityQuestion.trim();
    _securityAnswerHash = Helpers.sha256Hash(securityAnswer);
    _pinEnabled = true;

    await _databaseHelper.setSettingValue(
        AppConstants.settingPinEnabled, 'true');
    await _databaseHelper.setSettingValue(
        AppConstants.settingPinHash, _pinHash);
    await _databaseHelper.setSettingValue(
      AppConstants.settingSecurityQuestion,
      _securityQuestion,
    );
    await _databaseHelper.setSettingValue(
      AppConstants.settingSecurityAnswerHash,
      _securityAnswerHash,
    );
    notifyListeners();
  }

  /// Updates the PIN while keeping the app protected.
  Future<void> updatePin(String newPin) async {
    _pinHash = Helpers.sha256Hash(newPin);
    _pinEnabled = true;
    await _databaseHelper.setSettingValue(
        AppConstants.settingPinEnabled, 'true');
    await _databaseHelper.setSettingValue(
        AppConstants.settingPinHash, _pinHash);
    notifyListeners();
  }

  /// Checks whether the provided PIN matches the stored PIN hash.
  bool verifyPin(String pin) {
    return _pinHash.isNotEmpty && Helpers.sha256Hash(pin) == _pinHash;
  }

  /// Checks whether the provided security answer matches the stored hash.
  bool verifySecurityAnswer(String answer) {
    return _securityAnswerHash.isNotEmpty &&
        Helpers.sha256Hash(answer) == _securityAnswerHash;
  }

  /// Copies a QR image into app storage and saves its label in the database.
  Future<QrCodeEntry> addQrCode({
    required String label,
    required XFile imageFile,
  }) async {
    if (!Helpers.isSupportedImagePath(imageFile.path)) {
      throw Exception(
          'Unsupported image format. Please upload PNG, JPG, or WEBP.');
    }

    final documents = await getApplicationDocumentsDirectory();
    final qrDirectory = Directory(path.join(documents.path, 'qr_images'));
    if (!await qrDirectory.exists()) {
      await qrDirectory.create(recursive: true);
    }

    final fileName =
        '${DateTime.now().millisecondsSinceEpoch}_${path.basename(imageFile.path)}';
    final destinationPath = path.join(qrDirectory.path, fileName);
    await File(imageFile.path).copy(destinationPath);

    final entry = QrCodeEntry(label: label.trim(), imagePath: destinationPath);
    final id = await _databaseHelper.insertQrCode(entry);
    final saved =
        QrCodeEntry(id: id, label: entry.label, imagePath: entry.imagePath);
    await refreshQrCodes();
    return saved;
  }

  /// Updates only the display label for an existing QR code entry.
  Future<void> updateQrCodeLabel(QrCodeEntry code, String label) async {
    final trimmed = label.trim();
    if (trimmed.isEmpty) {
      throw Exception('QR code label cannot be empty.');
    }
    if (code.id == null) {
      throw Exception('Unable to update this QR code.');
    }

    await _databaseHelper.updateQrCodeLabel(id: code.id!, label: trimmed);
    await refreshQrCodes();
  }

  /// Removes a QR code entry and deletes its stored image file.
  Future<void> deleteQrCode(QrCodeEntry code) async {
    if (code.id != null) {
      await _databaseHelper.deleteQrCode(code.id!);
    }
    final file = File(code.imagePath);
    if (await file.exists()) {
      await file.delete();
    }
    await refreshQrCodes();
  }

  /// Exports all store data into a JSON-friendly backup payload.
  Future<Map<String, dynamic>> exportBackupData() async {
    return _databaseHelper.exportBackupPayload();
  }

  /// Restores a validated backup payload and refreshes cached state.
  Future<void> importBackupData(Map<String, dynamic> payload) async {
    await _databaseHelper.importBackupPayload(payload);
    // reload settings and related cached items
    await loadSettings();
  }
}
