import '../usecase/usecase.dart';

abstract class AuthBase {
  Future<bool> isAuthenticated();
  dynamic getAuthData();
  Future<Result> signIn({required String email, required String password});
  Future<bool> signOut();
}
