import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../models/meal.dart';
import '../../models/food_item.dart';
import '../../providers/auth_provider.dart';
import '../../providers/meal_provider.dart';
import '../../services/food_service.dart';

class MealPlanScreen extends StatefulWidget {
  const MealPlanScreen({super.key});

  @override
  State<MealPlanScreen> createState() => _MealPlanScreenState();
}

class _MealPlanScreenState extends State<MealPlanScreen> {
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _refresh();
  }

  Future<void> _refresh() async {
    final auth = context.read<AuthProvider>();
    if (auth.user == null) return;
    await context.read<MealProvider>().refreshDay(auth.user!.id);
    if (!mounted) return;
    setState(() => _loading = false);
  }

  Future<void> _pickDate() async {
    final meals = context.read<MealProvider>();
    final initial = meals.selectedDate;
    final picked = await showDatePicker(
      context: context,
      firstDate: DateTime.now().subtract(const Duration(days: 365)),
      lastDate: DateTime.now().add(const Duration(days: 365)),
      initialDate: initial,
    );
    if (!mounted) return;
    if (picked != null) {
      meals.setDate(picked);
      final auth = context.read<AuthProvider>();
      await meals.refreshDay(auth.user!.id);
      if (!mounted) return;
      setState(() {});
    }
  }

  Future<void> _addItemDialog(MealType type) async {
    final foodService = context.read<FoodService>();
    final auth = context.read<AuthProvider>();
    final meals = context.read<MealProvider>();

    FoodItem? selected;
    final gramsController = TextEditingController(text: '100');
    final searchController = TextEditingController();

    List<FoodItem> results = foodService.search('');

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (_) {
        return StatefulBuilder(
          builder: (ctx, setModalState) {
            void onSearch(String q) {
              setModalState(() {
                results = foodService.search(q);
              });
            }

            return Padding(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(ctx).viewInsets.bottom,
                left: 16,
                right: 16,
                top: 16,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text('Add ${mealTypeToString(type)} item', style: const TextStyle(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 10),
                  TextField(
                    controller: searchController,
                    decoration: const InputDecoration(prefixIcon: Icon(Icons.search), hintText: 'Search food'),
                    onChanged: onSearch,
                  ),
                  const SizedBox(height: 8),
                  SizedBox(
                    height: 200,
                    child: ListView.builder(
                      itemCount: results.length,
                      itemBuilder: (_, i) {
                        final item = results[i];
                        final selectedStyle = selected?.name == item.name
                            ? TextStyle(color: Theme.of(context).colorScheme.primary, fontWeight: FontWeight.bold)
                            : const TextStyle();
                        return ListTile(
                          title: Text(item.name, style: selectedStyle),
                          subtitle: Text('${item.caloriesPer100g.toStringAsFixed(0)} kcal / 100g'),
                          trailing: selected?.name == item.name ? const Icon(Icons.check_circle) : null,
                          onTap: () => setModalState(() => selected = item),
                        );
                      },
                    ),
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: gramsController,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(labelText: 'Grams'),
                  ),
                  const SizedBox(height: 12),
                  ElevatedButton.icon(
                    onPressed: selected == null
                        ? null
                        : () async {
                            final grams = double.tryParse(gramsController.text) ?? 100.0;
                            await meals.addItem(
                              userId: auth.user!.id,
                              date: meals.selectedDate,
                              mealType: type,
                              foodName: selected!.name,
                              grams: grams,
                              caloriesPer100g: selected!.caloriesPer100g,
                            );
                            if (ctx.mounted) Navigator.of(ctx).pop();
                          },
                    icon: const Icon(Icons.add),
                    label: const Text('Add item'),
                  ),
                  const SizedBox(height: 12),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _section(String title, List<Map<String, dynamic>> items) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: items.isEmpty
            ? Text('No $title items yet')
            : Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: const TextStyle(fontWeight: FontWeight.w600)),
                  const Divider(),
                  ...items.map((it) => ListTile(
                        title: Text(it['food_name'] as String),
                        subtitle: Text('${(it['grams'] as num).toString()} g'),
                        trailing: Text('${(it['total_calories'] as num).toStringAsFixed(0)} kcal'),
                        leading: const Icon(Icons.circle, size: 10),
                        onLongPress: () async {
                          final auth = context.read<AuthProvider>();
                          await context.read<MealProvider>().deleteItem(
                                userId: auth.user!.id,
                                itemId: it['id'] as int,
                              );
                        },
                      )),
                ],
              ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final meals = context.watch<MealProvider>();
    final dayData = meals.dayData;
    final dateStr = DateFormat.yMMMMEEEEd().format(meals.selectedDate);

    final allMeals = (dayData?['meals'] as List<Map<String, dynamic>>? ?? []);
    List<Map<String, dynamic>> forType(MealType t) =>
        allMeals.where((m) => (m['meal_type'] as String) == mealTypeToString(t)).expand((m) {
          final items = (m['items'] as List).cast<Map<String, dynamic>>();
          return items;
        }).toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Meal Plan'),
        actions: [
          IconButton(onPressed: _pickDate, icon: const Icon(Icons.calendar_month)),
        ],
      ),
      floatingActionButton: PopupMenuButton<MealType>(
        icon: const Icon(Icons.add),
        onSelected: (t) => _addItemDialog(t),
        itemBuilder: (ctx) => [
          const PopupMenuItem(value: MealType.breakfast, child: Text('Add to Breakfast')),
          const PopupMenuItem(value: MealType.lunch, child: Text('Add to Lunch')),
          const PopupMenuItem(value: MealType.dinner, child: Text('Add to Dinner')),
          const PopupMenuItem(value: MealType.snack, child: Text('Add to Snack')),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _refresh,
        child: _loading
            ? const Center(child: CircularProgressIndicator())
            : ListView(
                padding: const EdgeInsets.all(12),
                children: [
                  Text(dateStr, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                  const SizedBox(height: 8),
                  _section('Breakfast', forType(MealType.breakfast)),
                  _section('Lunch', forType(MealType.lunch)),
                  _section('Dinner', forType(MealType.dinner)),
                  _section('Snack', forType(MealType.snack)),
                  const SizedBox(height: 80),
                ],
              ),
      ),
    );
  }
}
