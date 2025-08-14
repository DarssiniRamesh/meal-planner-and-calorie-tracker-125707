import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../providers/auth_provider.dart';
import '../../providers/meal_provider.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _refresh();
  }

  Future<void> _refresh() async {
    final auth = context.read<AuthProvider>();
    if (auth.user == null) return;
    final meals = context.read<MealProvider>();
    await meals.refreshDay(auth.user!.id);
    await meals.refreshWeek(auth.user!.id);
    if (!mounted) return;
    setState(() => _loading = false);
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final meals = context.watch<MealProvider>();
    final total = meals.dayData?['total'] as double? ?? 0.0;

    return Scaffold(
      appBar: AppBar(title: const Text('Dashboard')),
      body: RefreshIndicator(
        onRefresh: _refresh,
        child: _loading
            ? const Center(child: CircularProgressIndicator())
            : ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Row(
                        children: [
                          CircleAvatar(
                            radius: 24,
                            child: Text((auth.user?.displayName ?? auth.user?.email ?? 'U').substring(0, 1).toUpperCase()),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('Hi, ${auth.user?.displayName ?? auth.user?.email ?? ''}',
                                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
                                const SizedBox(height: 4),
                                Text(DateFormat.yMMMMEEEEd().format(meals.selectedDate),
                                    style: const TextStyle(color: Colors.black54)),
                              ],
                            ),
                          ),
                          Chip(
                            label: Text('${total.toStringAsFixed(0)} kcal'),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Weekly Summary', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                          const SizedBox(height: 8),
                          _WeeklyBarChart(data: meals.weeklySummary),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  const Text('Tips', style: TextStyle(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  const Text('Track your meals daily to get accurate weekly summaries.'),
                ],
              ),
      ),
    );
  }
}

class _WeeklyBarChart extends StatelessWidget {
  final Map<String, double> data;
  const _WeeklyBarChart({required this.data});

  @override
  Widget build(BuildContext context) {
    if (data.isEmpty) {
      return const Text('No data yet. Add meal items to see your weekly summary.');
    }
    final entries = data.entries.toList()..sort((a, b) => a.key.compareTo(b.key));
    final max = (entries.map((e) => e.value).fold<double>(0.0, (p, c) => c > p ? c : p)).clamp(1.0, double.infinity);

    return SizedBox(
      height: 160,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: entries.map((e) {
          final d = DateTime.parse(e.key);
          final heightFactor = (e.value / max).clamp(0.0, 1.0);
          return Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                Text(e.value.toStringAsFixed(0), style: const TextStyle(fontSize: 12)),
                const SizedBox(height: 6),
                Flexible(
                  child: FractionallySizedBox(
                    heightFactor: heightFactor,
                    child: Container(
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.primary.withValues(
                          alpha: (0.2 + heightFactor * 0.7).clamp(0.0, 1.0).toDouble(),
                        ),
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 6),
                Text(DateFormat.Md().format(d), style: const TextStyle(fontSize: 12, color: Colors.black54)),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }
}
