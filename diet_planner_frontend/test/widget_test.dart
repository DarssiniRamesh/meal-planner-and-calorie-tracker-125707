import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:diet_planner_frontend/main.dart';
import 'package:diet_planner_frontend/services/food_service.dart';

void main() {
  testWidgets('App renders and shows login or home', (WidgetTester tester) async {
    final foodService = FoodService();
    // Load foods manually for test
    await foodService.init();
    await tester.pumpWidget(MyApp(foodService: foodService));

    expect(find.byType(MaterialApp), findsOneWidget);
    // Should find at least one of the following screens/widgets
    expect(find.textContaining('Login', findRichText: true).evaluate().isNotEmpty ||
        find.textContaining('Dashboard', findRichText: true).evaluate().isNotEmpty, true);
  });
}
