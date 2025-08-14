# Diet Planner Frontend

A Flutter mobile app that lets users:
- Register and log in
- Create and edit meal plans
- Search food items from local JSON
- Automatically calculate calories from grams and calories per 100g
- View daily and weekly summaries
- Browse meal history
- Enjoy a modern, light-themed, tab-based layout with Dashboard, Meal Plan, Food Search, and Profile

## Getting Started

- Optionally create a `.env` file based on `.env.example` in the project root to configure `APP_NAME`.
- Ensure Flutter SDK is installed.

### Run
```
flutter pub get
flutter run
```

### Data Storage
- Local persistence using `sqflite`.
- Session management using `shared_preferences`.

### Assets
- `assets/foods.json` contains the food catalog used for search and calorie calculation.

### Notes
- Long press a meal item in the Meal Plan tab to delete it.
- Use the add button (+) to add items to specific meal types (Breakfast, Lunch, Dinner, Snack).
