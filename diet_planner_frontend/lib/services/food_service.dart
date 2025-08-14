import 'dart:convert';

import 'package:flutter/services.dart' show rootBundle;

import '../models/food_item.dart';

/// FoodService loads and searches local JSON food data.
class FoodService {
  List<FoodItem> _items = [];

  // PUBLIC_INTERFACE
  Future<void> init() async {
    final raw = await rootBundle.loadString('assets/foods.json');
    final List<dynamic> list = jsonDecode(raw) as List<dynamic>;
    _items = list.map((e) => FoodItem.fromMap(e as Map<String, dynamic>)).toList();
    _items.sort((a, b) => a.name.compareTo(b.name));
  }

  // PUBLIC_INTERFACE
  List<FoodItem> search(String query, {int limit = 100}) {
    final q = query.trim().toLowerCase();
    if (q.isEmpty) return _items.take(limit).toList();
    final results = _items.where((e) => e.name.toLowerCase().contains(q)).take(limit).toList();
    return results;
  }

  // PUBLIC_INTERFACE
  FoodItem? getByName(String name) {
    try {
      return _items.firstWhere((e) => e.name.toLowerCase() == name.toLowerCase());
    } catch (_) {
      return null;
    }
  }

  // PUBLIC_INTERFACE
  List<FoodItem> get all => _items;
}
