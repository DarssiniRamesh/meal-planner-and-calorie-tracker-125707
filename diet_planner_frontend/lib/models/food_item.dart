/// Food item (from JSON) used for search and calorie calculations.
class FoodItem {
  final String name;
  final double caloriesPer100g;

  FoodItem({required this.name, required this.caloriesPer100g});

  factory FoodItem.fromMap(Map<String, dynamic> map) {
    return FoodItem(
      name: map['name'] as String,
      caloriesPer100g: (map['calories_per_100g'] as num).toDouble(),
    );
  }

  Map<String, dynamic> toMap() => {
        'name': name,
        'calories_per_100g': caloriesPer100g,
      };
}
