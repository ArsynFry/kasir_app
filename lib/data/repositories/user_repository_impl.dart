import 'dart:convert';

import '../../app/services/connectivity/connectivity_service.dart';
import '../../core/errors/errors.dart';
import '../../core/usecase/usecase.dart';
import '../../domain/entities/user_entity.dart';
import '../../domain/repositories/user_repository.dart';
import '../datasources/local/queued_action_local_datasource_impl.dart';
import '../datasources/local/user_local_datasource_impl.dart';
import '../datasources/remote/user_remote_datasource_impl.dart';
import '../models/queued_action_model.dart';
import '../models/user_model.dart';

class UserRepositoryImpl extends UserRepository {
  final UserLocalDatasourceImpl userLocalDatasource;
  final UserRemoteDatasourceImpl userRemoteDatasource;
  final QueuedActionLocalDatasourceImpl queuedActionLocalDatasource;

  UserRepositoryImpl({
    required this.userLocalDatasource,
    required this.userRemoteDatasource,
    required this.queuedActionLocalDatasource,
  });

  @override
  Future<Result<UserEntity>> getUser(String userId) async {
    try {
      if (ConnectivityService.isConnected) {
        var remote = await userRemoteDatasource.getUser(userId);
        return Result.success(remote?.toEntity());
      } else {
        var local = await userLocalDatasource.getUser(userId);
        return Result.success(local?.toEntity());
      }
    } catch (e) {
      return Result.error(APIError(message: e.toString()));
    }
  }

  @override
  Future<Result<String>> createUser(UserEntity user) async {
    try {
      var id = await userLocalDatasource.createUser(UserModel.fromEntity(user));

      if (ConnectivityService.isConnected) {
        await userRemoteDatasource.createUser(UserModel.fromEntity(user)..id = id);
      } else {
        await queuedActionLocalDatasource.createQueuedAction(
          QueuedActionModel(
            id: DateTime.now().millisecondsSinceEpoch,
            repository: 'UserRepositoryImpl',
            method: 'createUser',
            param: jsonEncode((UserModel.fromEntity(user)..id = id).toJson()),
            isCritical: false,
            createdAt: DateTime.now().toIso8601String(),
          ),
        );
      }

      return Result.success(id);
    } catch (e) {
      return Result.error(APIError(message: e.toString()));
    }
  }

  @override
  Future<Result<void>> deleteUser(String userId) async {
    try {
      await userLocalDatasource.deleteUser(userId);

      if (ConnectivityService.isConnected) {
        await userRemoteDatasource.deleteUser(userId);
      } else {
        await queuedActionLocalDatasource.createQueuedAction(
          QueuedActionModel(
            id: DateTime.now().millisecondsSinceEpoch,
            repository: 'UserRepositoryImpl',
            method: 'deleteUser',
            param: userId,
            isCritical: false,
            createdAt: DateTime.now().toIso8601String(),
          ),
        );
      }

      return Result.success(null);
    } catch (e) {
      return Result.error(APIError(message: e.toString()));
    }
  }

  @override
  Future<Result<void>> updateUser(UserEntity user) async {
    try {
      await userLocalDatasource.updateUser(UserModel.fromEntity(user));

      if (ConnectivityService.isConnected) {
        await userRemoteDatasource.updateUser(UserModel.fromEntity(user));
      } else {
        await queuedActionLocalDatasource.createQueuedAction(
          QueuedActionModel(
            id: DateTime.now().millisecondsSinceEpoch,
            repository: 'UserRepositoryImpl',
            method: 'updateUser',
            param: jsonEncode(UserModel.fromEntity(user).toJson()),
            isCritical: false,
            createdAt: DateTime.now().toIso8601String(),
          ),
        );
      }

      return Result.success(null);
    } catch (e) {
      return Result.error(APIError(message: e.toString()));
    }
  }

  // Perform a sync between local and remote data
}
