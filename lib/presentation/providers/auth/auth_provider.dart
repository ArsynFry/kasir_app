import 'package:flutter/foundation.dart';

import '../../../app/services/auth/auth_service.dart';
import '../../../core/errors/errors.dart';
import '../../../core/usecase/usecase.dart';
import '../../../domain/entities/user_entity.dart';
import '../../../domain/repositories/user_repository.dart';
import '../../../domain/usecases/user_usecases.dart';

class AuthProvider extends ChangeNotifier {
  final UserRepository userRepository;

  AuthProvider({required this.userRepository});

  Future<Result<String>> signIn({required String email, required String password}) async {
    try {
      var res = await AuthService().signIn(email: email, password: password);

      if (res.isHasError) {
        return Result.error(res.error);
      }

      var saveUserRes = await saveUser();

      return saveUserRes;
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
