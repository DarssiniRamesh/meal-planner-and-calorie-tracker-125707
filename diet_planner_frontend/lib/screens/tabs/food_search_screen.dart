import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/food_item.dart';
import '../../services/food_service.dart';

class FoodSearchScreen extends StatefulWidget {
  final bool standalone;
  const FoodSearchScreen({super.key, this.standalone = false});

  @override
  State<FoodSearchScreen> createState() => _FoodSearchScreenState();
}

class _FoodSearchScreenState extends State<FoodSearchScreen> {
  List<FoodItem> _results = [];
  final _search = TextEditingController();

  @override
  void initState() {
    super.initState();
    final foodService = context.read<FoodService>();
    _results = foodService.search('');
  }

  void _onSearch(String q) {
    final foodService = context.read<FoodService>();
    setState(() {
      _results = foodService.search(q);
    });
  }

  @override
  Widget build(BuildContext context) {
    final body = Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(12),
          child: TextField(
            controller: _search,
            decoration: const InputDecoration(prefixIcon: Icon(Icons.search), hintText: 'Search foods'),
            onChanged: _onSearch,
          ),
        ),
        Expanded(
          child: _results.isEmpty
              ? const Center(child: Text('No results'))
              : ListView.builder(
                  itemCount: _results.length,
                  itemBuilder: (_, i) {
                    final f = _results[i];
                    return ListTile(
                      title: Text(f.name),
                      subtitle: Text('${f.caloriesPer100g.toStringAsFixed(0)} kcal / 100g'),
                      leading: const Icon(Icons.fastfood),
                    );
                  },
                ),
        )
      ],
    );

    if (widget.standalone) {
      return Scaffold(appBar: AppBar(title: const Text('Food Search')), body: body);
    }
    return body;
  }
}
