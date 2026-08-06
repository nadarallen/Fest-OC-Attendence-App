import 'dart:async';
import 'package:flutter/material.dart';
import '../models/user_session.dart';
import '../services/auth_service.dart';

class AuthProvider extends ChangeNotifier {
  final AuthService _authService = AuthService();

  UserSession? _session;
  bool _isLoading = true;
  bool _lastSessionExpired = false;
  Timer? _sessionTimer;

  UserSession? get session => _session;
  bool get isAuthenticated => _session != null && _session!.isValid;
  bool get isLoading => _isLoading;
  bool get lastSessionExpired => _lastSessionExpired;
  String? get currentUsername => _session?.username;
  String? get currentDisplayName => _session?.displayName;

  AuthProvider() {
    initializeAuth();
  }

  /// Initialize auth state from stored session
  Future<void> initializeAuth() async {
    _isLoading = true;
    notifyListeners();

    try {
      _session = await _authService.loadSavedSession();
      if (_session != null && _session!.isValid) {
        _startSessionTimer();
      } else {
        _session = null;
      }
    } catch (e) {
      _session = null;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Perform login with username and 6-digit Google Authenticator code
  Future<void> login(String username, String totpCode) async {
    _isLoading = true;
    _lastSessionExpired = false;
    notifyListeners();

    try {
      _session = await _authService.login(username: username, totpCode: totpCode);
      _startSessionTimer();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Logout current session
  Future<void> logout({bool isAutoLogout = false}) async {
    _stopSessionTimer();
    await _authService.logout();
    _session = null;
    _lastSessionExpired = isAutoLogout;
    notifyListeners();
  }

  /// Reset the session expired message flag after displaying to user
  void clearExpiredFlag() {
    _lastSessionExpired = false;
    notifyListeners();
  }

  void _startSessionTimer() {
    _stopSessionTimer();
    _sessionTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_session == null || !_session!.isValid) {
        logout(isAutoLogout: true);
      } else {
        notifyListeners(); // Refresh UI with updated remaining seconds countdown
      }
    });
  }

  void _stopSessionTimer() {
    _sessionTimer?.cancel();
    _sessionTimer = null;
  }

  @override
  void dispose() {
    _stopSessionTimer();
    super.dispose();
  }
}
