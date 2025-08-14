import 'package:flutter/foundation.dart';

import '../services/db_service.dart';
import '../models/meal.dart';

class MealProvider extends ChangeNotifier {
  final DbService _db = DbService();

  DateTime _selectedDate = DateTime.now();
  DateTime get selectedDate => DateTime(_selectedDate.year, _selectedDate.month, _selectedDate.day);

  Map<String, dynamic>? _dayData; // {meals: [...], totals: double}
  Map<String, double> _weeklySummary = {};

  Map<String, dynamic>? get dayData => _dayData;
  Map<String, double> get weeklySummary => _weeklySummary;

  // PUBLIC_INTERFACE
  void setDate(DateTime date) {
    _selectedDate = DateTime(date.year, date.month, date.day);
    notifyListeners();
  }

  // PUBLIC_INTERFACE
  Future<void> refreshDay(int userId) async {
    final meals = await _db.getMealsByDate(userId, selectedDate);
    double dayTotal = 0.0;
    for (final m in meals) {
      dayTotal += (m['total_calories'] as num).toDouble();
    }
    _dayData = {'meals': meals, 'total': dayTotal};
    notifyListeners();
  }

  // PUBLIC_INTERFACE
  Future<void> refreshWeek(int userId) async {
    _weeklySummary = await _db.getWeeklyCaloriesSummary(userId, selectedDate);
    notifyListeners();
  }

  // PUBLIC_INTERFACE
  Future<void> addItem({
    required int userId,
    required DateTime date,
    required MealType mealType,
    required String foodName,
    required double grams,
    required double caloriesPer100g,
  }) async {
    await _db.addMealItem(
      userId: userId,
      date: date,
      mealType: mealType,
      foodName: foodName,
      grams: grams,
      caloriesPer100g: caloriesPer100g,
    );
    await refreshDay(userId);
    await refreshWeek(userId);
  }

  // PUBLIC_INTERFACE
  Future<void> deleteItem({required int userId, required int itemId}) async {
    await _db.deleteMealItem(itemId);
    await refreshDay(userId);
    await refreshWeek(userId);
  }
}
