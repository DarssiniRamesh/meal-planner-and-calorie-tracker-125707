import 'dart:async';
import 'dart:convert';

import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';
import 'package:crypto/crypto.dart';

import '../models/meal.dart';

/// Database service for local persistence (users, meals, and meal items).
class DbService {
  static final DbService _instance = DbService._internal();
  factory DbService() => _instance;
  DbService._internal();

  Database? _db;

  // PUBLIC_INTERFACE
  Future<Database> get database async {
    if (_db != null) return _db!;
    _db = await _init();
    return _db!;
  }

  Future<Database> _init() async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, 'diet_planner.db');

    return openDatabase(
      path,
      version: 1,
      onCreate: (db, version) async {
        await db.execute('''
          CREATE TABLE users (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            email TEXT UNIQUE NOT NULL,
            password_hash TEXT NOT NULL,
            display_name TEXT
          );
        ''');
        await db.execute('CREATE INDEX idx_users_email ON users(email);');

        await db.execute('''
          CREATE TABLE meals(
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            user_id INTEGER NOT NULL,
            date TEXT NOT NULL,
            meal_type TEXT NOT NULL,
            total_calories REAL NOT NULL DEFAULT 0,
            FOREIGN KEY(user_id) REFERENCES users(id) ON DELETE CASCADE
          );
        ''');
        await db.execute('CREATE INDEX idx_meals_user_date ON meals(user_id, date);');

        await db.execute('''
          CREATE TABLE meal_items(
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            meal_id INTEGER NOT NULL,
            food_name TEXT NOT NULL,
            grams REAL NOT NULL,
            calories_per_100g REAL NOT NULL,
            total_calories REAL NOT NULL,
            FOREIGN KEY(meal_id) REFERENCES meals(id) ON DELETE CASCADE
          );
        ''');
        await db.execute('CREATE INDEX idx_meal_items_meal ON meal_items(meal_id);');
      },
    );
  }

  String _hashPassword(String password) {
    final bytes = utf8.encode(password);
    final digest = sha256.convert(bytes);
    return digest.toString();
  }

  // PUBLIC_INTERFACE
  Future<int> registerUser(String email, String password, {String? displayName}) async {
    final db = await database;
    final hashed = _hashPassword(password);
    try {
      return await db.insert('users', {
        'email': email.trim().toLowerCase(),
        'password_hash': hashed,
        'display_name': displayName,
      });
    } on DatabaseException catch (e) {
      if (e.isUniqueConstraintError()) {
        throw Exception('Email already exists');
      }
      rethrow;
    }
  }

  // PUBLIC_INTERFACE
  Future<Map<String, dynamic>?> loginUser(String email, String password) async {
    final db = await database;
    final hashed = _hashPassword(password);
    final res = await db.query(
      'users',
      where: 'email = ? AND password_hash = ?',
      whereArgs: [email.trim().toLowerCase(), hashed],
      limit: 1,
    );
    if (res.isEmpty) return null;
    return res.first;
  }

  // Ensure a meal exists for the (user, date, type) and return its id.
  Future<int> _ensureMeal(int userId, DateTime date, MealType type) async {
    final db = await database;
    final dateStr = _yyyyMmDd(date);
    final existing = await db.query('meals',
        where: 'user_id = ? AND date = ? AND meal_type = ?',
        whereArgs: [userId, dateStr, mealTypeToString(type)],
        limit: 1);
    if (existing.isNotEmpty) {
      return existing.first['id'] as int;
    }
    return await db.insert('meals', {
      'user_id': userId,
      'date': dateStr,
      'meal_type': mealTypeToString(type),
      'total_calories': 0.0,
    });
    // total will be updated as items added
  }

  Future<void> _recomputeMealTotal(int mealId) async {
    final db = await database;
    final total = Sqflite.firstIntValue(await db.rawQuery(
          'SELECT COALESCE(SUM(total_calories),0) as total FROM meal_items WHERE meal_id = ?',
          [mealId],
        )) ??
        0;
    await db.update('meals', {'total_calories': total.toDouble()}, where: 'id = ?', whereArgs: [mealId]);
  }

  // PUBLIC_INTERFACE
  Future<int> addMealItem({
    required int userId,
    required DateTime date,
    required MealType mealType,
    required String foodName,
    required double grams,
    required double caloriesPer100g,
  }) async {
    final db = await database;
    final mealId = await _ensureMeal(userId, date, mealType);
    final totalCalories = (caloriesPer100g * (grams / 100.0));
    final id = await db.insert('meal_items', {
      'meal_id': mealId,
      'food_name': foodName,
      'grams': grams,
      'calories_per_100g': caloriesPer100g,
      'total_calories': totalCalories,
    });
    await _recomputeMealTotal(mealId);
    return id;
  }

  // PUBLIC_INTERFACE
  Future<void> deleteMealItem(int itemId) async {
    final db = await database;
    final row = await db.query('meal_items', where: 'id = ?', whereArgs: [itemId], limit: 1);
    if (row.isEmpty) return;
    final mealId = row.first['meal_id'] as int;
    await db.delete('meal_items', where: 'id = ?', whereArgs: [itemId]);
    await _recomputeMealTotal(mealId);
  }

  // PUBLIC_INTERFACE
  Future<List<Map<String, dynamic>>> getMealsByDate(int userId, DateTime date) async {
    final db = await database;
    final dateStr = _yyyyMmDd(date);
    final meals = await db.query('meals', where: 'user_id = ? AND date = ?', whereArgs: [userId, dateStr]);
    if (meals.isEmpty) return [];
    final mealIds = meals.map((e) => e['id']).toList();
    final items = await db.query('meal_items',
        where: 'meal_id IN (${List.filled(mealIds.length, '?').join(',')})', whereArgs: mealIds);
    // Attach items to meals
    final mealsWithItems = <Map<String, dynamic>>[];
    for (final m in meals) {
      final id = m['id'] as int;
      final its = items.where((it) => it['meal_id'] == id).toList();
      mealsWithItems.add({...m, 'items': its});
    }
    return mealsWithItems;
  }

  // PUBLIC_INTERFACE
  Future<double> getDailyTotalCalories(int userId, DateTime date) async {
    final db = await database;
    final dateStr = _yyyyMmDd(date);
    final total = Sqflite.firstIntValue(await db.rawQuery(
          'SELECT COALESCE(SUM(total_calories),0) as total FROM meals WHERE user_id = ? AND date = ?',
          [userId, dateStr],
        )) ??
        0;
    return total.toDouble();
  }

  // PUBLIC_INTERFACE
  Future<Map<String, double>> getWeeklyCaloriesSummary(int userId, DateTime endDateInclusive) async {
    // Returns a map yyyy-mm-dd -> totalCalories for last 7 days ending at endDateInclusive
    final db = await database;
    final end = DateTime(endDateInclusive.year, endDateInclusive.month, endDateInclusive.day);
    final start = end.subtract(const Duration(days: 6));
    final startStr = _yyyyMmDd(start);
    final endStr = _yyyyMmDd(end);
    final res = await db.rawQuery('''
      SELECT date, COALESCE(SUM(total_calories),0) as total
      FROM meals
      WHERE user_id = ? AND date BETWEEN ? AND ?
      GROUP BY date
      ORDER BY date ASC
    ''', [userId, startStr, endStr]);

    final out = <String, double>{};
    DateTime d = start;
    for (int i = 0; i < 7; i++) {
      out[_yyyyMmDd(d)] = 0.0;
      d = d.add(const Duration(days: 1));
    }
    for (final row in res) {
      out[row['date'] as String] = (row['total'] as num).toDouble();
    }
    return out;
  }

  // PUBLIC_INTERFACE
  Future<List<Map<String, dynamic>>> getMealHistoryDates(int userId, {int limit = 30}) async {
    final db = await database;
    final res = await db.rawQuery('''
      SELECT date, COALESCE(SUM(total_calories),0) as total
      FROM meals
      WHERE user_id = ?
      GROUP BY date
      ORDER BY date DESC
      LIMIT ?
    ''', [userId, limit]);
    return res;
  }
}

String _yyyyMmDd(DateTime date) =>
    '${date.year.toString().padLeft(4, '0')}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
