/// Type of meal
enum MealType { breakfast, lunch, dinner, snack }

MealType mealTypeFromString(String value) {
  switch (value) {
    case 'breakfast':
      return MealType.breakfast;
    case 'lunch':
      return MealType.lunch;
    case 'dinner':
      return MealType.dinner;
    case 'snack':
      return MealType.snack;
    default:
      return MealType.breakfast;
  }
}

String mealTypeToString(MealType type) {
  switch (type) {
    case MealType.breakfast:
      return 'breakfast';
    case MealType.lunch:
      return 'lunch';
    case MealType.dinner:
      return 'dinner';
    case MealType.snack:
      return 'snack';
  }
}

/// Represents an item within a meal (a particular food with a given weight).
class MealItem {
  final int id;
  final int mealId;
  final String foodName;
  final double grams;
  final double caloriesPer100g;
  final double totalCalories;

  MealItem({
    required this.id,
    required this.mealId,
    required this.foodName,
    required this.grams,
    required this.caloriesPer100g,
    required this.totalCalories,
  });

  Map<String, dynamic> toMap() => {
        'id': id,
        'meal_id': mealId,
        'food_name': foodName,
        'grams': grams,
        'calories_per_100g': caloriesPer100g,
        'total_calories': totalCalories,
      };

  static MealItem fromMap(Map<String, dynamic> map) => MealItem(
        id: map['id'] as int,
        mealId: map['meal_id'] as int,
        foodName: map['food_name'] as String,
        grams: (map['grams'] as num).toDouble(),
        caloriesPer100g: (map['calories_per_100g'] as num).toDouble(),
        totalCalories: (map['total_calories'] as num).toDouble(),
      );
}

/// Represents a meal record (collection of items) for a user at a date/time and type.
class Meal {
  final int id;
  final int userId;
  final DateTime date; // Only date is meaningful (yyyy-mm-dd)
  final MealType mealType;
  final double totalCalories;

  Meal({
    required this.id,
    required this.userId,
    required this.date,
    required this.mealType,
    required this.totalCalories,
  });

  Map<String, dynamic> toMap() => {
        'id': id,
        'user_id': userId,
        'date': _yyyyMmDd(date),
        'meal_type': mealTypeToString(mealType),
        'total_calories': totalCalories,
      };

  static Meal fromMap(Map<String, dynamic> map) => Meal(
        id: map['id'] as int,
        userId: map['user_id'] as int,
        date: DateTime.parse(map['date'] as String),
        mealType: mealTypeFromString(map['meal_type'] as String),
        totalCalories: (map['total_calories'] as num).toDouble(),
      );
}

String _yyyyMmDd(DateTime date) => '${date.year.toString().padLeft(4, '0')}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
