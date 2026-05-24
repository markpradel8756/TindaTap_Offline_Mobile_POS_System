import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

class BackupService {
  BackupService._();

  static final BackupService instance = BackupService._();
  static const MethodChannel _channel = MethodChannel('tindatap/saf_backup');

  bool get _isAndroid =>
      !kIsWeb && defaultTargetPlatform == TargetPlatform.android;

  /// Opens Android's native save dialog and writes the backup bytes to it.
  Future<bool> exportBackup({
    required String fileName,
    required Uint8List data,
  }) async {
    if (!_isAndroid) {
      throw UnsupportedError('Export backup is available on Android only.');
    }

    try {
      final result = await _channel.invokeMethod<bool>(
        'exportBackup',
        <String, dynamic>{
          'fileName': fileName,
          'mimeType': 'application/json',
          'data': data,
        },
      );
      return result ?? false;
    } on PlatformException catch (e) {
      throw Exception(e.message ?? 'Unable to export the backup file.');
    }
  }

  /// Opens Android's native file picker and returns the selected backup text.
  Future<String?> importBackup() async {
    if (!_isAndroid) {
      throw UnsupportedError('Import backup is available on Android only.');
    }

    try {
      final bytes = await _channel.invokeMethod<Uint8List?>('importBackup');
      if (bytes == null || bytes.isEmpty) {
        return null;
      }
      return utf8.decode(bytes, allowMalformed: false);
    } on PlatformException catch (e) {
      throw Exception(e.message ?? 'Unable to import the backup file.');
    } on FormatException {
      throw Exception('The selected backup file is not valid UTF-8 text.');
    }
  }
}
