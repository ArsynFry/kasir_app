import 'package:flutter/foundation.dart';

import '../../../app/services/auth/auth_service.dart';
import '../../../core/errors/errors.dart';
import '../../../core/usecase/usecase.dart';
import '../../../domain/entities/user_entity.dart';
import '../../../domain/repositories/user_repository.dart';
import '../../../domain/usecases/user_usecases.dart';

class AuthProvider extends ChangeNotifier {
  Future<Result<String>> signUp({required String email, required String password, String? name}) async {
    try {
      var res = await AuthService().signUp(email: email, password: password);
      if (res.isHasError) {
        return Result.error(res.error);
      }
      // Cek apakah user sudah ada di tabel user, jika belum baru create
      var authData = AuthService().getAuthData();
      if (authData == null) {
        return Result.error(ServiceError(message: 'User not logged in'));
      }
      var checkUserRes = await GetUserUsecase(userRepository).call(authData.id);
      if (checkUserRes.isSuccess && checkUserRes.data != null) {
        // User sudah ada, tidak perlu create lagi
        return Result.success('User already exists');
      } else {
        // User belum ada, create
        var saveUserRes = await saveUser();
        return saveUserRes;
      }
    } catch (e) {
      return Result.error(UnknownError(message: e.toString()));
    }
  }

  final UserRepository userRepository;

  AuthProvider({required this.userRepository});

  Future<Result<String>> signIn({required String email, required String password}) async {
    try {
      var res = await AuthService().signIn(email: email, password: password);

      if (res.isHasError) {
        return Result.error(res.error);
      }

      // Cek apakah user sudah ada di tabel user, jika belum baru create
      var authData = AuthService().getAuthData();
      if (authData == null) {
        return Result.error(ServiceError(message: 'User not logged in'));
      }
      var checkUserRes = await GetUserUsecase(userRepository).call(authData.id);
      if (checkUserRes.isSuccess && checkUserRes.data != null) {
        // User sudah ada, tidak perlu create lagi
        return Result.success('User already exists');
      } else {
        // User belum ada, create
        var saveUserRes = await saveUser();
        return saveUserRes;
      }
    } catch (e) {
      return Result.error(UnknownError(message: e.toString()));
    }
  }

  Future<Result<String>> saveUser() async {
    var authData = AuthService().getAuthData();
    if (authData == null) {
      return Result.error(ServiceError(message: 'User not logged in'));
    }
    var user = UserEntity(
      id: authData.id,
      email: authData.email,
      name: authData.userMetadata?['name'] as String? ?? '',
      imageUrl: authData.userMetadata?['photo_url'] as String?,
      phone: authData.phone,
      birthdate: null,
    );

    return await CreateUserUsecase(userRepository).call(user);
  }
}
