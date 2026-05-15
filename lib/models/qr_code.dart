class QrCodeEntry {
  final int? id;
  final String label;
  final String imagePath;

  const QrCodeEntry({
    this.id,
    required this.label,
    required this.imagePath,
  });

  /// Converts this QR code entry into a SQLite-compatible map.
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'label': label,
      'image_path': imagePath,
    };
  }

  /// Builds a QR code entry from a database row.
  factory QrCodeEntry.fromMap(Map<String, dynamic> map) {
    return QrCodeEntry(
      id: map['id'] as int?,
      label: (map['label'] ?? '') as String,
      imagePath: (map['image_path'] ?? '') as String,
    );
  }
}
