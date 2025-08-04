import 'dart:convert';

import '../../app/services/connectivity/connectivity_service.dart';
import '../../core/errors/errors.dart';
import '../../core/usecase/usecase.dart';
import '../../domain/entities/transaction_entity.dart';
import '../../domain/repositories/transaction_repository.dart';
import '../datasources/local/queued_action_local_datasource_impl.dart';
import '../datasources/local/transaction_local_datasource_impl.dart';
import '../datasources/remote/transaction_remote_datasource_impl.dart';
import '../models/queued_action_model.dart';
import '../models/transaction_model.dart';

class TransactionRepositoryImpl extends TransactionRepository {
  final TransactionLocalDatasourceImpl transactionLocalDatasource;
  final TransactionRemoteDatasourceImpl transactionRemoteDatasource;
  final QueuedActionLocalDatasourceImpl queuedActionLocalDatasource;

  TransactionRepositoryImpl({
    required this.transactionLocalDatasource,
    required this.transactionRemoteDatasource,
    required this.queuedActionLocalDatasource,
  });

  @override
  Future<Result<int>> syncAllUserTransactions(String userId) async {
    try {
      if (ConnectivityService.isConnected) {
        // Sync logic removed
        return Result.success(0);
      }
      return Result.success(0);
    } catch (e) {
      return Result.error(APIError(message: e.toString()));
    }
  }

  @override
  Future<Result<List<TransactionEntity>>> getUserTransactions(
    String userId, {
    String orderBy = 'createdAt',
    String sortBy = 'DESC',
    int limit = 10,
    int? offset,
    String? contains,
  }) async {
    try {
      if (ConnectivityService.isConnected) {
        var remote = await transactionRemoteDatasource.getUserTransactions(
          userId,
          orderBy: orderBy,
          sortBy: sortBy,
          limit: limit,
          offset: offset,
          contains: contains,
        );
        return Result.success(remote.map((e) => e.toEntity()).toList());
      } else {
        var local = await transactionLocalDatasource.getUserTransactions(
          userId,
          orderBy: orderBy,
          sortBy: sortBy,
          limit: limit,
          offset: offset,
          contains: contains,
        );
        return Result.success(local.map((e) => e.toEntity()).toList());
      }
    } catch (e) {
      return Result.error(APIError(message: e.toString()));
    }
  }

  @override
  Future<Result<TransactionEntity>> getTransaction(int transactionId) async {
    try {
      if (ConnectivityService.isConnected) {
        var remote = await transactionRemoteDatasource.getTransaction(transactionId);
        return Result.success(remote?.toEntity());
      } else {
        var local = await transactionLocalDatasource.getTransaction(transactionId);
        return Result.success(local?.toEntity());
      }
    } catch (e) {
      return Result.error(APIError(message: e.toString()));
    }
  }

  @override
  Future<Result<int>> createTransaction(TransactionEntity transaction) async {
    try {
      var data = TransactionModel.fromEntity(transaction);
      if (ConnectivityService.isConnected) {
        var id = await transactionRemoteDatasource.createTransaction(data);
        return Result.success(id);
      } else {
        var id = await transactionLocalDatasource.createTransaction(data);
        await queuedActionLocalDatasource.createQueuedAction(
          QueuedActionModel(
            id: DateTime.now().millisecondsSinceEpoch,
            repository: 'TransactionRepositoryImpl',
            method: 'createTransaction',
            param: jsonEncode((data).toJson()),
            isCritical: true,
            createdAt: DateTime.now().toIso8601String(),
          ),
        );
        return Result.success(id);
      }
    } catch (e) {
      return Result.error(APIError(message: e.toString()));
    }
  }

  @override
  Future<Result<void>> deleteTransaction(int transactionId) async {
    try {
      await transactionLocalDatasource.deleteTransaction(transactionId);

      if (ConnectivityService.isConnected) {
        await transactionRemoteDatasource.deleteTransaction(transactionId);
      } else {
        await queuedActionLocalDatasource.createQueuedAction(
          QueuedActionModel(
            id: DateTime.now().millisecondsSinceEpoch,
            repository: 'TransactionRepositoryImpl',
            method: 'deleteTransaction',
            param: transactionId.toString(),
            isCritical: true,
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
  Future<Result<void>> updateTransaction(TransactionEntity transaction) async {
    try {
      var data = TransactionModel.fromEntity(transaction);

      await transactionLocalDatasource.updateTransaction(data);

      if (ConnectivityService.isConnected) {
        await transactionRemoteDatasource.updateTransaction(data);
      } else {
        await queuedActionLocalDatasource.createQueuedAction(
          QueuedActionModel(
            id: DateTime.now().millisecondsSinceEpoch,
            repository: 'TransactionRepositoryImpl',
            method: 'updateTransaction',
            param: jsonEncode(data.toJson()),
            isCritical: true,
            createdAt: DateTime.now().toIso8601String(),
          ),
        );
      }

      return Result.success(null);
    } catch (e) {
      return Result.error(APIError(message: e.toString()));
    }
  }
}
