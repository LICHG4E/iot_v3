import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:iot_v3/services/auth_service.dart';

enum AuthStatus {
  initializing,
  unauthenticated,
  awaitingEmailVerification,
  authenticated,
}

class AuthController with ChangeNotifier {
  AuthController(this._authService) {
    _subscription = _authService.authStateChanges().listen(_handleAuthStateChanged);
  }

  final AuthService _authService;
  late final StreamSubscription<User?> _subscription;

  AuthStatus _status = AuthStatus.initializing;
  String? _errorMessage;
  User? _user;

  bool _loginLoading = false;
  bool _registerLoading = false;
  bool _resetLoading = false;
  bool _verificationLoading = false;

  AuthStatus get status => _status;
  String? get errorMessage => _errorMessage;
  User? get user => _user;
  bool get isLoginLoading => _loginLoading;
  bool get isRegisterLoading => _registerLoading;
  bool get isResetLoading => _resetLoading;
  bool get isVerificationLoading => _verificationLoading;
  bool get isInitializing => _status == AuthStatus.initializing;

  void _handleAuthStateChanged(User? user) {
    _user = user;
    if (user == null) {
      _status = AuthStatus.unauthenticated;
    } else if (user.emailVerified) {
      _status = AuthStatus.authenticated;
    } else {
      _status = AuthStatus.awaitingEmailVerification;
    }
    notifyListeners();
  }

  Future<void> signIn(String email, String password) async {
    _setLoading(login: true);
    try {
      await _authService.signIn(email: email.trim(), password: password.trim());
      _errorMessage = null;
      await _refreshAuthState();
    } on AuthFailure catch (failure) {
      _errorMessage = failure.message;
      notifyListeners();
    } finally {
      _setLoading(login: false);
    }
  }

  Future<void> register(String email, String password) async {
    _setLoading(register: true);
    try {
      await _authService.signUp(email: email.trim(), password: password.trim());
      _errorMessage = null;
      await _refreshAuthState();
    } on AuthFailure catch (failure) {
      _errorMessage = failure.message;
      notifyListeners();
    } finally {
      _setLoading(register: false);
    }
  }

  Future<void> sendPasswordReset(String email) async {
    _setLoading(reset: true);
    try {
      await _authService.sendPasswordReset(email.trim());
      _errorMessage = null;
    } on AuthFailure catch (failure) {
      _errorMessage = failure.message;
    } finally {
      _setLoading(reset: false);
    }
  }

  Future<void> resendVerificationEmail() async {
    final currentUser = _authService.currentUser;
    if (currentUser == null) return;
    _setLoading(verification: true);
    try {
      await _authService.sendEmailVerification(currentUser);
      _errorMessage = null;
    } on AuthFailure catch (failure) {
      _errorMessage = failure.message;
      notifyListeners();
    } finally {
      _setLoading(verification: false);
    }
  }

  Future<void> refreshUser() async {
    await _authService.reloadCurrentUser();
    await _refreshAuthState();
  }

  Future<void> logout() async {
    await _authService.signOut();
    _errorMessage = null;
    await _refreshAuthState();
  }

  Future<void> _refreshAuthState() async {
    final refreshedUser = _authService.currentUser;
    _user = refreshedUser;
    if (refreshedUser == null) {
      _status = AuthStatus.unauthenticated;
    } else if (refreshedUser.emailVerified) {
      _status = AuthStatus.authenticated;
    } else {
      _status = AuthStatus.awaitingEmailVerification;
    }
    notifyListeners();
  }

  void _setLoading({bool? login, bool? register, bool? reset, bool? verification}) {
    if (login != null) _loginLoading = login;
    if (register != null) _registerLoading = register;
    if (reset != null) _resetLoading = reset;
    if (verification != null) _verificationLoading = verification;
    notifyListeners();
  }

  @override
  void dispose() {
    _subscription.cancel();
    super.dispose();
  }
}
