import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'package:flutter/foundation.dart';
import 'package:sqflite_common_ffi_web/sqflite_ffi_web.dart';
import '../models/food_log.dart';

class LocalDatabase {
  static final LocalDatabase instance = LocalDatabase._init();
  static Database? _database;

  LocalDatabase._init();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB('vegilog_local.db');
    return _database!;
  }

  Future<Database> _initDB(String filePath) async {
    if (kIsWeb) {
      databaseFactory = databaseFactoryFfiWebNoWebWorker;
      return await openDatabase(
        filePath,
        version: 2,
        onCreate: _createDB,
        onUpgrade: _upgradeDB,
      );
    }
    
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, filePath);

    return await openDatabase(
      path,
      version: 2,
      onCreate: _createDB,
      onUpgrade: _upgradeDB,
    );
  }

  Future _createDB(Database db, int version) async {
    const idType = 'INTEGER PRIMARY KEY AUTOINCREMENT';
    const textType = 'TEXT NOT NULL';
    const textNullable = 'TEXT';
    const integerNullable = 'INTEGER';
    const realNullable = 'REAL';
    const boolType = 'INTEGER NOT NULL';

    await db.execute('''
CREATE TABLE food_logs_local (
  local_id $idType,
  server_id $integerNullable,
  photo_path $textNullable,
  photo_url $textNullable,
  food_name $textType,
  meal_time $textType,
  category $textType,
  nutrition_notes $textNullable,
  calories $realNullable,
  carbs $realNullable,
  fat $realNullable,
  protein $realNullable,
  is_synced $boolType,
  created_at $textType
)
''');
  }

  Future _upgradeDB(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      // Add nutrition columns
      await db.execute('ALTER TABLE food_logs_local ADD COLUMN calories REAL');
      await db.execute('ALTER TABLE food_logs_local ADD COLUMN carbs REAL');
      await db.execute('ALTER TABLE food_logs_local ADD COLUMN fat REAL');
      await db.execute('ALTER TABLE food_logs_local ADD COLUMN protein REAL');
    }
  }

  // ==== CRUD for Food Logs ==== //
  
  Future<FoodLog> insertFoodLog(FoodLog log) async {
    final db = await instance.database;
    final id = await db.insert('food_logs_local', log.toLocalMap());
    return FoodLog(
      localId: id,
      id: log.id,
      photoPath: log.photoPath,
      photoUrl: log.photoUrl,
      foodName: log.foodName,
      mealTime: log.mealTime,
      category: log.category,
      nutritionNotes: log.nutritionNotes,
      calories: log.calories,
      carbs: log.carbs,
      fat: log.fat,
      protein: log.protein,
      isSynced: log.isSynced,
      createdAt: log.createdAt,
    );
  }

  Future<List<FoodLog>> getFoodLogs() async {
    final db = await instance.database;
    final result = await db.query(
      'food_logs_local',
      orderBy: 'meal_time DESC',
    );
    return result.map((json) => FoodLog.fromLocalMap(json)).toList();
  }
  
  Future<List<FoodLog>> getUnsyncedFoodLogs() async {
    final db = await instance.database;
    final result = await db.query(
      'food_logs_local',
      where: 'is_synced = ?',
      whereArgs: [0],
    );
    return result.map((json) => FoodLog.fromLocalMap(json)).toList();
  }

  Future<int> updateFoodLog(FoodLog log) async {
    final db = await instance.database;
    return await db.update(
      'food_logs_local',
      log.toLocalMap(),
      where: 'local_id = ?',
      whereArgs: [log.localId],
    );
  }

  Future<int> deleteFoodLog(int localId) async {
    final db = await instance.database;
    return await db.delete(
      'food_logs_local',
      where: 'local_id = ?',
      whereArgs: [localId],
    );
  }

  /// Clear ALL food logs from local DB (call on login/logout to prevent cross-user data leakage)
  Future<void> clearAllFoodLogs() async {
    final db = await instance.database;
    await db.delete('food_logs_local');
  }

  Future<void> replaceAllFoodLogs(List<FoodLog> logs) async {
    final db = await instance.database;
    await db.transaction((txn) async {
      // First delete all synced logs (keep unsynced ones)
      await txn.delete('food_logs_local', where: 'is_synced = 1');
      
      // Get remaining unsynced logs to check duplicates
      final unsynced = await txn.query('food_logs_local');
      final unsyncedServerIds = unsynced
          .map((e) => e['server_id'])
          .where((id) => id != null)
          .toList();
          
      // Insert new ones from server
      for (var log in logs) {
        if (!unsyncedServerIds.contains(log.id)) {
          await txn.insert('food_logs_local', log.toLocalMap());
        }
      }
    });
  }

  Future close() async {
    final db = await instance.database;
    db.close();
  }
}
