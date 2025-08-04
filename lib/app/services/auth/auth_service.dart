//import 'dart:io';

import 'package:supabase_flutter/supabase_flutter.dart';
// import 'package:flutter_dotenv/flutter_dotenv.dart';
// import 'package:google_sign_in/google_sign_in.dart';

import '../../../core/auth/auth_base.dart';
import '../../../core/errors/errors.dart';
import '../../../core/usecase/usecase.dart';

class AuthService implements AuthBase {
  /// Sign up with email & password
  Future<Result> signUp({required String email, required String password}) async {
    try {
      final response = await Supabase.instance.client.auth.signUp(
        email: email,
        password: password,
      );
      if (response.user != null) {
        return Result.success(response);
      } else {
        return Result.error(ServiceError(message: 'Sign up failed'));
      }
    } catch (e) {
      return Result.error(ServiceError(message: e.toString()));
    }
  }

  AuthService();

  @override
  Future<bool> isAuthenticated() async {
    final user = Supabase.instance.client.auth.currentUser;
    return user != null;
  }

  /// Return SupabaseUser? (or null if not logged in)
  @override
  User? getAuthData() {
    return Supabase.instance.client.auth.currentUser;
  }

  /// Sign in with email & password
  @override
  Future<Result> signIn({required String email, required String password}) async {
    try {
      final response = await Supabase.instance.client.auth.signInWithPassword(email: email, password: password);
      if (response.user != null) {
        return Result.success(response);
      } else {
        return Result.error(ServiceError(message: 'Sign in failed'));
      }
    } catch (e) {
      return Result.error(ServiceError(message: e.toString()));
    }
  }

  @override
  Future<bool> signOut() async {
    try {
      await Supabase.instance.client.auth.signOut();
      return true;
    } catch (e) {
      return false;
    }
  }
}
