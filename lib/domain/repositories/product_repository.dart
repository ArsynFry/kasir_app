import '../../core/usecase/usecase.dart';
import '../entities/product_entity.dart';

// Interface repository untuk produk.
// Mendefinisikan kontrak CRUD dan sinkronisasi produk.
abstract class ProductRepository {
  Future<Result<int>> syncAllUserProducts(String userId);

  Future<Result<ProductEntity>> getProduct(int productId);

  Future<Result<int>> createProduct(ProductEntity product);

  Future<Result<void>> updateProduct(ProductEntity product);

  Future<Result<void>> deleteProduct(int productId);

  Future<Result<List<ProductEntity>>> getUserProducts(
    String userId, {
    String orderBy,
    String sortBy,
    int limit,
    int? offset,
    String? contains,
  });
}
