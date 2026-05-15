import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:intl/intl.dart';
import 'package:path/path.dart' as path;
import 'package:path_provider/path_provider.dart';
import 'package:sqflite/sqflite.dart' as sqflite_db;

import '../models/product.dart';
import '../models/qr_code.dart';
import '../models/transaction.dart';
import '../models/transaction_item.dart';
import '../utils/constants.dart';

class DatabaseHelper {
  DatabaseHelper._();

  static final DatabaseHelper instance = DatabaseHelper._();

  sqflite_db.Database? _database;
  String? _dbPath;

  /// Opens the local SQLite database and creates default settings on first run.
  Future<sqflite_db.Database> initDatabase() async {
    if (_database != null) return _database!;

    final directory = await getApplicationDocumentsDirectory();
    _dbPath = path.join(directory.path, AppConstants.databaseName);

    _database = await sqflite_db.openDatabase(
      _dbPath!,
      version: 1,
      onCreate: _createSchema,
    );

    await _seedDefaultSettings();
    return _database!;
  }

  /// Returns the initialized database, creating it if needed.
  Future<sqflite_db.Database> get database async {
    return initDatabase();
  }

  /// Creates all database tables used by the app's products, sales, QR codes,
  /// and settings features.
  Future<void> _createSchema(sqflite_db.Database db, int version) async {
    await db.execute('''
      CREATE TABLE products (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        product_code TEXT NOT NULL UNIQUE,
        name TEXT NOT NULL,
        price REAL NOT NULL,
        quantity REAL NOT NULL,
        created_at TEXT,
        updated_at TEXT
      )
    ''');

    await db.execute('''
      CREATE TABLE transactions (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        timestamp TEXT,
        total_amount REAL,
        payment_method TEXT,
        cash_received REAL,
        qr_label TEXT,
        store_name TEXT
      )
    ''');

    await db.execute('''
      CREATE TABLE transaction_items (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        transaction_id INTEGER,
        product_code TEXT,
        product_name TEXT,
        unit_price REAL,
        quantity REAL,
        subtotal REAL,
        FOREIGN KEY(transaction_id) REFERENCES transactions(id) ON DELETE CASCADE
      )
    ''');

    await db.execute('''
      CREATE TABLE qr_codes (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        label TEXT NOT NULL,
        image_path TEXT NOT NULL
      )
    ''');

    await db.execute('''
      CREATE TABLE settings (
        key TEXT PRIMARY KEY,
        value TEXT
      )
    ''');
  }

  /// Inserts default settings rows so the app always has baseline values.
  Future<void> _seedDefaultSettings() async {
    final db = await database;
    final defaults = <String, String>{
      AppConstants.settingStoreName: '',
      AppConstants.settingCurrency: 'PHP',
      AppConstants.settingPinEnabled: 'false',
      AppConstants.settingPinHash: '',
      AppConstants.settingSecurityQuestion: '',
      AppConstants.settingSecurityAnswerHash: '',
      AppConstants.settingLowStockThreshold:
          AppConstants.defaultLowStockThreshold.toString(),
      AppConstants.settingPinTimeoutMinutes:
          AppConstants.defaultPinTimeoutMinutes.toString(),
    };

    for (final entry in defaults.entries) {
      await db.insert(
        'settings',
        {'key': entry.key, 'value': entry.value},
        conflictAlgorithm: sqflite_db.ConflictAlgorithm.ignore,
      );
    }
  }

  /// Loads every persisted setting into a key-value map.
  Future<Map<String, String>> getSettingsMap() async {
    final db = await database;
    final rows = await db.query('settings');
    final map = <String, String>{};
    for (final row in rows) {
      map[(row['key'] ?? '') as String] = (row['value'] ?? '') as String;
    }
    return map;
  }

  /// Reads one setting value, returning [defaultValue] when nothing is stored.
  Future<String> getSettingValue(String key, {String defaultValue = ''}) async {
    final db = await database;
    final rows = await db.query(
      'settings',
      columns: ['value'],
      where: 'key = ?',
      whereArgs: [key],
      limit: 1,
    );
    if (rows.isEmpty) return defaultValue;
    return (rows.first['value'] ?? defaultValue) as String;
  }

  /// Saves a setting value, replacing any existing row with the same key.
  Future<void> setSettingValue(String key, String value) async {
    final db = await database;
    await db.insert(
      'settings',
      {'key': key, 'value': value},
      conflictAlgorithm: sqflite_db.ConflictAlgorithm.replace,
    );
  }

  /// Fetches products, optionally filtering by code or name.
  Future<List<ProductModel>> getProducts({String search = ''}) async {
    final db = await database;
    final trimmed = search.trim();
    final rows = trimmed.isEmpty
        ? await db.query('products', orderBy: 'name COLLATE NOCASE ASC')
        : await db.query(
            'products',
            where: 'product_code LIKE ? OR name LIKE ?',
            whereArgs: ['%$trimmed%', '%$trimmed%'],
            orderBy: 'name COLLATE NOCASE ASC',
          );
    return rows.map(ProductModel.fromMap).toList();
  }

  /// Looks up a single product by its unique product code.
  Future<ProductModel?> getProductByCode(String productCode) async {
    final db = await database;
    final rows = await db.query(
      'products',
      where: 'product_code = ?',
      whereArgs: [productCode],
      limit: 1,
    );
    if (rows.isEmpty) return null;
    return ProductModel.fromMap(rows.first);
  }

  /// Looks up a single product by its database ID.
  Future<ProductModel?> getProductById(int id) async {
    final db = await database;
    final rows = await db.query(
      'products',
      where: 'id = ?',
      whereArgs: [id],
      limit: 1,
    );
    if (rows.isEmpty) return null;
    return ProductModel.fromMap(rows.first);
  }

  /// Inserts a new product row and stamps the created and updated timestamps.
  Future<int> insertProduct(ProductModel product) async {
    final db = await database;
    return db.insert(
      'products',
      product.toMap()
        ..remove('id')
        ..['created_at'] = product.createdAt ?? DateTime.now().toIso8601String()
        ..['updated_at'] =
            product.updatedAt ?? DateTime.now().toIso8601String(),
      conflictAlgorithm: sqflite_db.ConflictAlgorithm.abort,
    );
  }

  /// Updates an existing product row and refreshes its update timestamp.
  Future<int> updateProduct(ProductModel product) async {
    final db = await database;
    return db.update(
      'products',
      product.toMap()
        ..remove('id')
        ..['updated_at'] = DateTime.now().toIso8601String(),
      where: 'id = ?',
      whereArgs: [product.id],
    );
  }

  /// Deletes a product row by ID.
  Future<int> deleteProduct(int id) async {
    final db = await database;
    return db.delete('products', where: 'id = ?', whereArgs: [id]);
  }

  /// Saves a sale and its items in one transaction while decrementing stock.
  Future<int> saveTransaction({
    required SaleTransaction transaction,
    required List<TransactionItemModel> items,
  }) async {
    final db = await database;
    return db.transaction<int>((txn) async {
      final transactionId = await txn.insert(
        'transactions',
        transaction.toMap()..remove('id'),
      );

      for (final item in items) {
        final productRows = await txn.query(
          'products',
          where: 'product_code = ?',
          whereArgs: [item.productCode],
          limit: 1,
        );
        if (productRows.isEmpty) {
          throw Exception('Product ${item.productCode} was not found.');
        }

        final currentQuantity =
            (productRows.first['quantity'] as num?)?.toDouble() ?? 0;
        if (currentQuantity < item.quantity) {
          throw Exception(
            'Insufficient stock for ${item.productName}. Available: $currentQuantity',
          );
        }

        await txn.insert(
          'transaction_items',
          item.toMap()
            ..remove('id')
            ..['transaction_id'] = transactionId,
        );

        await txn.update(
          'products',
          {
            'quantity': currentQuantity - item.quantity,
            'updated_at': DateTime.now().toIso8601String(),
          },
          where: 'product_code = ?',
          whereArgs: [item.productCode],
        );
      }

      return transactionId;
    });
  }

  /// Returns all sales that occurred on the given date.
  Future<List<SaleTransaction>> getTransactionsByDate(DateTime date) async {
    final db = await database;
    final day = DateFormat('yyyy-MM-dd').format(date);
    final rows = await db.query(
      'transactions',
      where: 'date(timestamp) = date(?)',
      whereArgs: [day],
      orderBy: 'timestamp DESC',
    );
    return rows.map(SaleTransaction.fromMap).toList();
  }

  /// Returns the most recent sales ordered from newest to oldest.
  Future<List<SaleTransaction>> getRecentTransactions({int limit = 10}) async {
    final db = await database;
    final rows = await db.query(
      'transactions',
      orderBy: 'timestamp DESC',
      limit: limit,
    );
    return rows.map(SaleTransaction.fromMap).toList();
  }

  /// Returns the line items associated with one sale.
  Future<List<TransactionItemModel>> getTransactionItems(
      int transactionId) async {
    final db = await database;
    final rows = await db.query(
      'transaction_items',
      where: 'transaction_id = ?',
      whereArgs: [transactionId],
      orderBy: 'id ASC',
    );
    return rows.map(TransactionItemModel.fromMap).toList();
  }

  /// Calculates the total sales amount for a single day.
  Future<double> getDailySalesTotal(DateTime date) async {
    final db = await database;
    final day = DateFormat('yyyy-MM-dd').format(date);
    final rows = await db.rawQuery(
      'SELECT COALESCE(SUM(total_amount), 0) AS total FROM transactions WHERE date(timestamp) = date(?)',
      [day],
    );
    return (rows.first['total'] as num?)?.toDouble() ?? 0;
  }

  /// Aggregates sales totals for every day in the requested range.
  Future<Map<String, double>> getDailySalesTotalsInRange({
    required DateTime startDate,
    required DateTime endDate,
  }) async {
    final db = await database;
    final start = DateFormat('yyyy-MM-dd').format(startDate);
    final end = DateFormat('yyyy-MM-dd').format(endDate);

    final rows = await db.rawQuery(
      '''
      SELECT date(timestamp) AS sale_date,
             COALESCE(SUM(total_amount), 0) AS total
      FROM transactions
      WHERE date(timestamp) BETWEEN date(?) AND date(?)
      GROUP BY date(timestamp)
      ''',
      [start, end],
    );

    final totals = <String, double>{};
    for (final row in rows) {
      final date = (row['sale_date'] ?? '') as String;
      final total = (row['total'] as num?)?.toDouble() ?? 0;
      totals[date] = total;
    }
    return totals;
  }

  /// Produces the detailed rows used by the stock movement report.
  Future<List<Map<String, dynamic>>> getStockMovementRows() async {
    final db = await database;
    return db.rawQuery('''
      SELECT
        p.id,
        p.product_code,
        p.name,
        p.price,
        p.quantity,
        p.created_at,
        p.updated_at,
        COALESCE(
          (SELECT SUM(ti.quantity)
           FROM transaction_items ti
           WHERE ti.product_code = p.product_code),
          0
        ) AS total_sold,
        (
          SELECT MAX(t.timestamp)
          FROM transaction_items ti
          JOIN transactions t ON t.id = ti.transaction_id
          WHERE ti.product_code = p.product_code
        ) AS last_sold_at
      FROM products p
      ORDER BY p.name COLLATE NOCASE ASC
    ''');
  }

  /// Returns products ranked by quantity sold over the requested period.
  Future<List<Map<String, dynamic>>> getFastMovingProducts({
    int days = 30,
    int limit = 10,
  }) async {
    final db = await database;
    return db.rawQuery(
      '''
      SELECT
        ti.product_code,
        ti.product_name,
        SUM(ti.quantity) AS total_sold
      FROM transaction_items ti
      JOIN transactions t ON t.id = ti.transaction_id
      WHERE datetime(t.timestamp) >= datetime('now', ?)
      GROUP BY ti.product_code, ti.product_name
      ORDER BY total_sold DESC, ti.product_name ASC
      LIMIT ?
      ''',
      ['-${days} day', limit],
    );
  }

  /// Loads all QR code entries saved in the database.
  Future<List<QrCodeEntry>> getQrCodes() async {
    final db = await database;
    final rows = await db.query('qr_codes', orderBy: 'id DESC');
    return rows.map(QrCodeEntry.fromMap).toList();
  }

  /// Inserts a new QR code record.
  Future<int> insertQrCode(QrCodeEntry code) async {
    final db = await database;
    return db.insert(
      'qr_codes',
      code.toMap()..remove('id'),
      conflictAlgorithm: sqflite_db.ConflictAlgorithm.abort,
    );
  }

  /// Updates only the label for an existing QR code record.
  Future<int> updateQrCodeLabel({
    required int id,
    required String label,
  }) async {
    final db = await database;
    return db.update(
      'qr_codes',
      {'label': label},
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  /// Deletes a QR code record by ID.
  Future<int> deleteQrCode(int id) async {
    final db = await database;
    return db.delete('qr_codes', where: 'id = ?', whereArgs: [id]);
  }

  /// Copies the current database into the app's backups folder.
  Future<String> exportDatabaseCopy() async {
    final db = await database;
    final sourcePath = db.path;
    final documents = await getApplicationDocumentsDirectory();
    final backupDir = Directory(path.join(documents.path, 'backups'));
    if (!await backupDir.exists()) {
      await backupDir.create(recursive: true);
    }

    final timestamp = DateFormat('yyyyMMdd_HHmmss').format(DateTime.now());
    final fileName = 'tindatap_backup_$timestamp.db';
    final destinationPath = path.join(backupDir.path, fileName);
    await File(sourcePath).copy(destinationPath);
    return destinationPath;
  }

  /// Close the open database connection, if any.
  Future<void> closeDatabase() async {
    if (_database != null) {
      await _database!.close();
      _database = null;
    }
  }

  /// Replace the current database file with the provided [sourcePath] file.
  /// This will close the DB, copy the file over, and reinitialize the DB.
  Future<void> importDatabaseFromPath(String sourcePath) async {
    await closeDatabase();
    if (_dbPath == null) {
      final directory = await getApplicationDocumentsDirectory();
      _dbPath = path.join(directory.path, AppConstants.databaseName);
    }
    final dest = File(_dbPath!);
    await File(sourcePath).copy(dest.path);
    // Re-open the database
    await initDatabase();
  }

  /// Removes all transaction, product, and QR code data from the database.
  Future<void> clearAllData() async {
    final db = await database;
    await db.delete('transaction_items');
    await db.delete('transactions');
    await db.delete('products');
    await db.delete('qr_codes');
  }

  /// Exposes the current database file path for tests and diagnostics.
  @visibleForTesting
  String? get databasePath => _dbPath;
}
