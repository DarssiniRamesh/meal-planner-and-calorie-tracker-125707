import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../services/db_service.dart';
import '../models/user.dart';

class AuthProvider extends ChangeNotifier {
  final DbService _db = DbService();
  AppUser? _user;

  AppUser? get user => _user;
  bool get isAuthenticated => _user != null;

  // PUBLIC_INTERFACE
  Future<void> loadSession() async {
    final prefs = await SharedPreferences.getInstance();
    final id = prefs.getInt('current_user_id');
    final email = prefs.getString('current_user_email');
    final name = prefs.getString('current_user_display_name');
    if (id != null && email != null) {
      _user = AppUser(id: id, email: email, displayName: name);
    }
    notifyListeners();
  }

  Future<void> _saveSession(AppUser user) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('current_user_id', user.id);
    await prefs.setString('current_user_email', user.email);
    if (user.displayName != null) {
      await prefs.setString('current_user_display_name', user.displayName!);
    } else {
      await prefs.remove('current_user_display_name');
    }
  }

  // PUBLIC_INTERFACE
  Future<String?> register(String email, String password, {String? displayName}) async {
    try {
      final id = await _db.registerUser(email, password, displayName: displayName);
      _user = AppUser(id: id, email: email.trim().toLowerCase(), displayName: displayName);
      await _saveSession(_user!);
      notifyListeners();
      return null;
    } catch (e) {
      return e.toString();
    }
  }

  // PUBLIC_INTERFACE
  Future<String?> login(String email, String password) async {
    final res = await _db.loginUser(email, password);
    if (res == null) return 'Invalid email or password';
    _user = AppUser(
      id: res['id'] as int,
      email: res['email'] as String,
      displayName: res['display_name'] as String?,
    );
    await _saveSession(_user!);
    notifyListeners();
    return null;
  }

  // PUBLIC_INTERFACE
  Future<void> logout() async {
    _user = null;
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('current_user_id');
    await prefs.remove('current_user_email');
    await prefs.remove('current_user_display_name');
    notifyListeners();
  }
}
