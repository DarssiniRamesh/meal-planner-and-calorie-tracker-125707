import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../providers/auth_provider.dart';
import '../../services/db_service.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  List<Map<String, dynamic>> _history = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final auth = context.read<AuthProvider>();
    if (auth.user == null) return;
    final db = DbService();
    final res = await db.getMealHistoryDates(auth.user!.id, limit: 60);
    setState(() {
      _history = res;
      _loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();

    return Scaffold(
      appBar: AppBar(title: const Text('Profile')),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                Card(
                  child: ListTile(
                    leading: const CircleAvatar(child: Icon(Icons.person)),
                    title: Text(auth.user?.displayName ?? auth.user?.email ?? ''),
                    subtitle: Text(auth.user?.email ?? ''),
                  ),
                ),
                const SizedBox(height: 12),
                Card(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const ListTile(
                        title: Text('Meal History'),
                        subtitle: Text('Recent days and their total calories'),
                      ),
                      const Divider(height: 1),
                      if (_history.isEmpty)
                        const Padding(
                          padding: EdgeInsets.all(16),
                          child: Text('No history yet. Add meal items to see them here.'),
                        )
                      else
                        ..._history.map((h) {
                          final date = DateTime.parse(h['date'] as String);
                          final total = (h['total'] as num).toDouble();
                          return ListTile(
                            leading: const Icon(Icons.calendar_today),
                            title: Text(DateFormat.yMMMMEEEEd().format(date)),
                            trailing: Text('${total.toStringAsFixed(0)} kcal'),
                          );
                        }),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                ElevatedButton.icon(
                  onPressed: () async {
                    await context.read<AuthProvider>().logout();
                    if (!mounted) return;
                    // Navigator will automatically show login due to AuthProvider consumer at root
                  },
                  icon: const Icon(Icons.logout),
                  label: const Text('Logout'),
                )
              ],
            ),
    );
  }
}
