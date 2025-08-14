import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:provider/provider.dart';

import 'providers/auth_provider.dart';
import 'providers/meal_provider.dart';
import 'services/food_service.dart';
import 'screens/auth/login_screen.dart';
import 'screens/home/home_screen.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  try {
    // Load environment variables if available.
    await dotenv.load(fileName: ".env");
  } catch (_) {
    // If .env not found, continue with defaults. It's optional and documented in .env.example.
  }

  // Initialize FoodService to load JSON foods early (non-fatal if it fails)
  final foodService = FoodService();
  try {
    await foodService.init();
  } catch (_) {
    // If initialization fails (e.g., asset not found), continue startup to avoid a blank screen.
  }

  runApp(MyApp(foodService: foodService));
}

class MyApp extends StatelessWidget {
  final FoodService foodService;
  const MyApp({super.key, required this.foodService});

  ThemeData _buildTheme() {
    // Colors based on work item
    const primaryHex = 0xFF4CAF50;
    const secondaryHex = 0xFF8BC34A;
    const accentHex = 0xFFFF9800;

    final base = ThemeData(
      brightness: Brightness.light,
      colorScheme: ColorScheme.fromSeed(
        seedColor: const Color(primaryHex),
        primary: const Color(primaryHex),
        secondary: const Color(secondaryHex),
        tertiary: const Color(accentHex),
        brightness: Brightness.light,
      ),
      useMaterial3: true,
    );

    return base.copyWith(
      scaffoldBackgroundColor: Colors.white,
      appBarTheme: base.appBarTheme.copyWith(
        backgroundColor: Colors.white,
        elevation: 0.5,
        foregroundColor: const Color(primaryHex),
      ),
      inputDecorationTheme: base.inputDecorationTheme.copyWith(
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        filled: true,
        fillColor: Colors.grey.shade50,
      ),
      bottomNavigationBarTheme: base.bottomNavigationBarTheme.copyWith(
        selectedItemColor: const Color(primaryHex),
        unselectedItemColor: Colors.grey.shade600,
        showUnselectedLabels: true,
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(primaryHex),
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        ),
      ),
      chipTheme: base.chipTheme,
      cardTheme: base.cardTheme.copyWith(
        elevation: 0.5,
        surfaceTintColor: Colors.white,
        margin: const EdgeInsets.symmetric(vertical: 6, horizontal: 8),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider<AuthProvider>(create: (_) => AuthProvider()..loadSession()),
        ChangeNotifierProvider<MealProvider>(create: (_) => MealProvider()),
        Provider<FoodService>.value(value: foodService),
      ],
      child: Consumer<AuthProvider>(
        builder: (context, auth, _) {
          return MaterialApp(
            title: dotenv.get('APP_NAME', fallback: 'Diet Planner'),
            theme: _buildTheme(),
            home: auth.isAuthenticated ? const HomeScreen() : const LoginScreen(),
          );
        },
      ),
    );
  }
}
