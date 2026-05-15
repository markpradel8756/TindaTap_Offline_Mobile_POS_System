import 'package:crypto/crypto.dart';
import 'package:intl/intl.dart';
import 'dart:convert';

class Helpers {
  /// Formats a numeric amount with the currency symbol for the selected code.
  static String formatMoney(double value, String currencyCode) {
    final symbol = currencySymbol(currencyCode);
    final formatter = NumberFormat('#,##0.00', 'en_US');
    return '$symbol${formatter.format(value)}';
  }

  /// Returns the symbol used for a supported ISO currency code.
  static String currencySymbol(String currencyCode) {
    switch (currencyCode.toUpperCase()) {
      case 'EUR':
        return '€';
      case 'GBP':
        return '£';
      case 'USD':
        return r'$';
      case 'PHP':
      default:
        return '₱';
    }
  }

  /// Formats a date and time into a readable sales-friendly string.
  static String formatDateTime(DateTime dateTime) {
    return DateFormat('MMM d, yyyy h:mm a').format(dateTime);
  }

  /// Formats only the calendar date portion for concise displays.
  static String formatDate(DateTime dateTime) {
    return DateFormat('MMM d, yyyy').format(dateTime);
  }

  /// Formats only the time portion for receipts and transaction summaries.
  static String formatTime(DateTime dateTime) {
    return DateFormat('h:mm a').format(dateTime);
  }

  /// Returns the current timestamp in ISO 8601 format for storage.
  static String isoNow() => DateTime.now().toIso8601String();

  /// Safely parses an optional ISO timestamp string into a DateTime.
  static DateTime? tryParseDateTime(String? value) {
    if (value == null || value.isEmpty) return null;
    return DateTime.tryParse(value);
  }

  /// Produces a SHA-256 hash from a trimmed string value.
  static String sha256Hash(String value) {
    return sha256.convert(utf8.encode(value.trim())).toString();
  }

  /// Checks whether a file path points to an image format the app supports.
  static bool isSupportedImagePath(String path) {
    final lower = path.toLowerCase();
    return lower.endsWith('.png') ||
        lower.endsWith('.jpg') ||
        lower.endsWith('.jpeg') ||
        lower.endsWith('.webp');
  }
}
