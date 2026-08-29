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
      version: 9,
      onCreate: _onCreate,
      onUpgrade: (db, oldVersion, newVersion) async {
        if (oldVersion < 2) {
          await db.execute(
            'ALTER TABLE Alerts ADD COLUMN alert_type TEXT DEFAULT "above"',
          );
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
        if (oldVersion < 6) {
          await db.execute(
            'ALTER TABLE Wallet ADD COLUMN currency TEXT DEFAULT "SYP"',
          );
        }
        if (oldVersion < 7) {
          await _createGoalsTable(db);
        }
        if (oldVersion < 8) {
          // Rates from the previous provider use a different scale and cannot
          // be mixed with LiraScope market history.
          await db.delete('Rates');
          await _createRatesUniqueIndex(db);
        }
        if (oldVersion >= 5 && oldVersion < 9) {
          await db.execute('ALTER TABLE News ADD COLUMN source_name TEXT');
          await db.execute('ALTER TABLE News ADD COLUMN source_url TEXT');
          await db.execute('ALTER TABLE News ADD COLUMN image_url TEXT');
          await db.execute('ALTER TABLE News ADD COLUMN published_at TEXT');
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
    await _createRatesUniqueIndex(db);

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
    await _createGoalsTable(db);
  }

  Future<void> _createRatesUniqueIndex(Database db) async {
    await db.execute('''
      CREATE UNIQUE INDEX IF NOT EXISTS idx_rates_currency_timestamp
      ON Rates(currency_pair, timestamp)
    ''');
  }

  Future<void> _createGoalsTable(Database db) async {
    await db.execute('''
      CREATE TABLE Goals (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        title TEXT,
        target_amount REAL,
        saved_amount REAL DEFAULT 0,
        currency TEXT DEFAULT "SYP",
        deadline TEXT
      )
    ''');
  }

  Future<void> _createWalletTable(Database db) async {
    await db.execute('''
      CREATE TABLE Wallet (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        title TEXT,
        amount REAL,
        type TEXT,
        currency TEXT DEFAULT "SYP",
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
        tag_en TEXT,
        source_name TEXT,
        source_url TEXT,
        image_url TEXT,
        published_at TEXT
      )
    ''');
  }

  // --- News ---
  Future<void> insertNews(List<Map<String, dynamic>> newsList) async {
    Database db = await database;
    await db.transaction((txn) async {
      for (var news in newsList) {
        final sourceUrl = news['source_url']?.toString();
        final result = await txn.query(
          'News',
          where: sourceUrl == null || sourceUrl.isEmpty
              ? 'title_ar = ?'
              : 'source_url = ?',
          whereArgs: [
            sourceUrl == null || sourceUrl.isEmpty
                ? news['title_ar']
                : sourceUrl,
          ],
        );
        if (result.isEmpty) {
          await txn.insert('News', news);
        } else {
          await txn.update(
            'News',
            news,
            where: 'id = ?',
            whereArgs: [result.first['id']],
          );
        }
      }
    });
  }

  Future<List<Map<String, dynamic>>> queryAllNews() async {
    Database db = await database;
    return await db.query(
      'News',
      orderBy: "COALESCE(published_at, '') DESC, id DESC",
      limit: 30,
    );
  }

  // --- Rates ---
  Future<void> saveRates(List<Map<String, dynamic>> rates) async {
    Database db = await database;
    await db.transaction((txn) async {
      for (var rate in rates) {
        await txn.insert(
          'Rates',
          rate,
          conflictAlgorithm: ConflictAlgorithm.ignore,
        );
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

  Future<List<Map<String, dynamic>>> getHistory(
    String code,
    String period,
  ) async {
    Database db = await database;
    int limit = 7;
    if (period == 'Day') limit = 24;
    if (period == 'Month') limit = 30;
    if (period == 'Year') limit = 365;

    return await db.rawQuery(
      '''
      SELECT * FROM (
        SELECT * FROM Rates
        WHERE currency_pair = ?
        ORDER BY timestamp DESC
        LIMIT ?
      )
      ORDER BY timestamp ASC
      ''',
      [code, limit],
    );
  }

  // --- Alerts ---
  Future<int> insertAlert(
    String currencyPair,
    double targetRate,
    String alertType,
  ) async {
    Database db = await database;
    return await db.insert('Alerts', {
      'currency_pair': currencyPair,
      'target_rate': targetRate,
      'alert_type': alertType,
      'is_active': 1,
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

  Future<int> updateWalletItem(Map<String, dynamic> row) async {
    Database db = await database;
    return await db.update(
      'Wallet',
      row,
      where: 'id = ?',
      whereArgs: [row['id']],
    );
  }

  Future<List<Map<String, dynamic>>> queryAllWallet() async {
    Database db = await database;
    return await db.query('Wallet', orderBy: 'date DESC');
  }

  Future<int> deleteWalletItem(int id) async {
    Database db = await database;
    return await db.delete('Wallet', where: 'id = ?', whereArgs: [id]);
  }

  Future<void> clearWallet() async {
    Database db = await database;
    await db.delete('Wallet');
  }

  // --- Goals ---
  Future<int> insertGoal(Map<String, dynamic> row) async {
    Database db = await database;
    return await db.insert('Goals', row);
  }

  Future<List<Map<String, dynamic>>> queryAllGoals() async {
    Database db = await database;
    return await db.query('Goals');
  }

  Future<int> updateGoal(Map<String, dynamic> row) async {
    Database db = await database;
    return await db.update(
      'Goals',
      row,
      where: 'id = ?',
      whereArgs: [row['id']],
    );
  }

  Future<int> deleteGoal(int id) async {
    Database db = await database;
    return await db.delete('Goals', where: 'id = ?', whereArgs: [id]);
  }
}
