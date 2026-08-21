import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

class DatabaseHelper {
  static final DatabaseHelper _instance = DatabaseHelper._internal();
  static Database? _database;

  factory DatabaseHelper() => _instance;

  DatabaseHelper._internal();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    String path = join(await getDatabasesPath(), 'currency_tracker.db');
    return await openDatabase(
      path,
      version: 5, // Incremented for News table
      onCreate: _onCreate,
      onUpgrade: (db, oldVersion, newVersion) async {
        if (oldVersion < 2) {
          await db.execute('ALTER TABLE Alerts ADD COLUMN alert_type TEXT DEFAULT "above"');
        }
        if (oldVersion < 3) {
          await _createWalletTable(db);
        }
        if (oldVersion < 4) {
          await db.execute('ALTER TABLE Rates ADD COLUMN buy REAL');
          await db.execute('ALTER TABLE Rates ADD COLUMN sell REAL');
        }
        if (oldVersion < 5) {
          await _createNewsTable(db);
        }
      },
    );
  }

  Future<void> _onCreate(Database db, int version) async {
    await db.execute('''
      CREATE TABLE Rates (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        currency_pair TEXT,
        rate REAL,
        buy REAL,
        sell REAL,
        timestamp TEXT
      )
    ''');

    await db.execute('''
      CREATE TABLE Alerts (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        currency_pair TEXT,
        target_rate REAL,
        alert_type TEXT,
        is_active INTEGER DEFAULT 1
      )
    ''');

    await _createWalletTable(db);
    await _createNewsTable(db);
  }

  Future<void> _createWalletTable(Database db) async {
    await db.execute('''
      CREATE TABLE Wallet (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        title TEXT,
        amount REAL,
        type TEXT,
        category TEXT,
        date TEXT,
        note TEXT,
        due_date TEXT,
        is_paid INTEGER DEFAULT 1
      )
    ''');
  }

  Future<void> _createNewsTable(Database db) async {
    await db.execute('''
      CREATE TABLE News (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        title_ar TEXT,
        title_en TEXT,
        desc_ar TEXT,
        desc_en TEXT,
        date TEXT,
        tag_ar TEXT,
        tag_en TEXT
      )
    ''');
  }

  // --- News ---
  Future<void> insertNews(List<Map<String, dynamic>> newsList) async {
    Database db = await database;
    await db.transaction((txn) async {
      for (var news in newsList) {
        // Check if exists by title to avoid duplicates
        var result = await txn.query('News', where: 'title_ar = ?', whereArgs: [news['title_ar']]);
        if (result.isEmpty) {
          await txn.insert('News', news);
        }
      }
    });
  }

  Future<List<Map<String, dynamic>>> queryAllNews() async {
    Database db = await database;
    return await db.query('News', orderBy: 'id DESC');
  }

  // --- Rates ---
  Future<void> saveRates(List<Map<String, dynamic>> rates) async {
    Database db = await database;
    await db.transaction((txn) async {
      for (var rate in rates) {
        await txn.insert('Rates', rate);
      }
    });
  }

  Future<List<Map<String, dynamic>>> getLatestSavedRates() async {
    Database db = await database;
    return await db.rawQuery('''
      SELECT r1.* FROM Rates r1
      INNER JOIN (
        SELECT currency_pair, MAX(timestamp) as max_ts 
        FROM Rates 
        GROUP BY currency_pair
      ) r2 ON r1.currency_pair = r2.currency_pair AND r1.timestamp = r2.max_ts
    ''');
  }

  Future<List<Map<String, dynamic>>> getHistory(String code, String period) async {
    Database db = await database;
    int limit = 7;
    if (period == 'Day') limit = 24;
    if (period == 'Month') limit = 30;
    if (period == 'Year') limit = 365;

    return await db.query(
      'Rates',
      where: 'currency_pair = ?',
      whereArgs: [code],
      orderBy: 'timestamp DESC',
      limit: limit,
    );
  }

  // --- Alerts ---
  Future<int> insertAlert(String currencyPair, double targetRate, String alertType) async {
    Database db = await database;
    return await db.insert('Alerts', {
      'currency_pair': currencyPair,
      'target_rate': targetRate,
      'alert_type': alertType,
      'is_active': 1
    });
  }

  Future<List<Map<String, dynamic>>> queryAllAlerts() async {
    Database db = await database;
    return await db.query('Alerts');
  }

  Future<int> deleteAlert(int id) async {
    Database db = await database;
    return await db.delete('Alerts', where: 'id = ?', whereArgs: [id]);
  }

  Future<int> updateAlertStatus(int id, bool isActive) async {
    Database db = await database;
    return await db.update(
      'Alerts',
      {'is_active': isActive ? 1 : 0},
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  // --- Wallet ---
  Future<int> insertWalletItem(Map<String, dynamic> row) async {
    Database db = await database;
    return await db.insert('Wallet', row);
  }

  Future<List<Map<String, dynamic>>> queryAllWallet() async {
    Database db = await database;
    return await db.query('Wallet', orderBy: 'date DESC');
  }

  Future<int> deleteWalletItem(int id) async {
    Database db = await database;
    return await db.delete('Wallet', where: 'id = ?', whereArgs: [id]);
  }
}
