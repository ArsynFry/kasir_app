import 'dart:convert';
import '../../app/services/connectivity/connectivity_service.dart';
import '../../core/errors/errors.dart';
import '../../core/usecase/usecase.dart';
import '../../domain/entities/product_entity.dart';
import '../../domain/repositories/product_repository.dart';
import '../datasources/local/product_local_datasource_impl.dart';
import '../datasources/local/queued_action_local_datasource_impl.dart';
import '../datasources/remote/product_remote_datasource_impl.dart';
import '../models/product_model.dart';
import '../models/queued_action_model.dart';

class ProductRepositoryImpl extends ProductRepository {
  final ProductLocalDatasourceImpl productLocalDatasource;
  final ProductRemoteDatasourceImpl productRemoteDatasource;
  final QueuedActionLocalDatasourceImpl queuedActionLocalDatasource;

  ProductRepositoryImpl({
    required this.productLocalDatasource,
    required this.productRemoteDatasource,
    required this.queuedActionLocalDatasource,
  });

  @override
  Future<Result<int>> syncAllUserProducts(String userId) async {
    try {
      if (ConnectivityService.isConnected) {
        // Removed unused local and remote variables

        // Sync logic removed
        return Result.success(0);
      }

      return Result.success(0);
    } catch (e) {
      return Result.error(APIError(message: e.toString()));
    }
  }

  @override
  Future<Result<List<ProductEntity>>> getUserProducts(
    String userId, {
    String orderBy = 'createdAt',
    String sortBy = 'DESC',
    int limit = 10,
    int? offset,
    String? contains,
  }) async {
    try {
      var local = await productLocalDatasource.getUserProducts(
        userId,
        orderBy: orderBy,
        sortBy: sortBy,
        limit: limit,
        offset: offset,
        contains: contains,
      );

      if (ConnectivityService.isConnected) {
        var remote = await productRemoteDatasource.getUserProducts(
          userId,
          orderBy: orderBy,
          sortBy: sortBy,
          limit: limit,
          offset: offset,
          contains: contains,
        );

        // Sync logic removed
        return Result.success(remote.map((e) => e.toEntity()).toList());
      }

      return Result.success(local.map((e) => e.toEntity()).toList());
    } catch (e) {
      return Result.error(APIError(message: e.toString()));
    }
  }

  @override
  Future<Result<ProductEntity>> getProduct(int productId) async {
    try {
      var local = await productLocalDatasource.getProduct(productId);

      if (ConnectivityService.isConnected) {
        var remote = await productRemoteDatasource.getProduct(productId);

        // Sync logic removed
        return Result.success(remote?.toEntity());
      }

      return Result.success(local?.toEntity());
    } catch (e) {
      return Result.error(APIError(message: e.toString()));
    }
  }

  @override
  Future<Result<int>> createProduct(ProductEntity product) async {
    try {
      var data = ProductModel.fromEntity(product);

      var productId = await productLocalDatasource.createProduct(data);

      if (ConnectivityService.isConnected) {
        await productRemoteDatasource.createProduct(data);
      } else {
        await queuedActionLocalDatasource.createQueuedAction(
          QueuedActionModel(
            id: DateTime.now().millisecond,
            repository: 'ProductRepositoryImpl',
            method: 'createProduct',
            param: jsonEncode((data).toJson()),
            isCritical: true,
            createdAt: DateTime.now().toIso8601String(),
          ),
        );
      }

      return Result.success(productId);
    } catch (e) {
      return Result.error(APIError(message: e.toString()));
    }
  }

  @override
  Future<Result<void>> deleteProduct(int productId) async {
    try {
      await productLocalDatasource.deleteProduct(productId);

      if (ConnectivityService.isConnected) {
        await productRemoteDatasource.deleteProduct(productId);
      } else {
        await queuedActionLocalDatasource.createQueuedAction(
          QueuedActionModel(
            id: DateTime.now().millisecond,
            repository: 'ProductRepositoryImpl',
            method: 'deleteProduct',
            param: productId.toString(),
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
  Future<Result<void>> updateProduct(ProductEntity product) async {
    try {
      await productLocalDatasource.updateProduct(ProductModel.fromEntity(product));

      if (ConnectivityService.isConnected) {
        await productRemoteDatasource.updateProduct(ProductModel.fromEntity(product));
      } else {
        await queuedActionLocalDatasource.createQueuedAction(
          QueuedActionModel(
            id: DateTime.now().millisecond,
            repository: 'ProductRepositoryImpl',
            method: 'updateProduct',
            param: jsonEncode(ProductModel.fromEntity(product).toJson()),
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

  // syncProducts function fully removed as part of online/offline refactor.
}
