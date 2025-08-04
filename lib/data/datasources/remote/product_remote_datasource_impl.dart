import 'package:supabase_flutter/supabase_flutter.dart';

import '../../models/product_model.dart';
import '../interfaces/product_datasource.dart';

class ProductRemoteDatasourceImpl extends ProductDatasource {
  final SupabaseClient _supabase;

  ProductRemoteDatasourceImpl(this._supabase);

  @override
  Future<int> createProduct(ProductModel product) async {
    try {
      await _supabase.from('Product').insert(product.toJson());
      return product.id;
    } catch (e) {
      throw Exception(e.toString());
    }
  }

  @override
  Future<void> updateProduct(ProductModel product) async {
    try {
      await _supabase.from('Product').update(product.toJson()).eq('id', product.id);
    } catch (e) {
      throw Exception(e.toString());
    }
  }

  @override
  Future<void> deleteProduct(int id) async {
    try {
      await _supabase.from('Product').delete().eq('id', id);
    } catch (e) {
      throw Exception(e.toString());
    }
  }

  @override
  Future<ProductModel?> getProduct(int id) async {
    try {
      final data = await _supabase.from('Product').select().eq('id', id).maybeSingle();
      if (data == null) return null;
      return ProductModel.fromJson(data);
    } catch (e) {
      throw Exception(e.toString());
    }
  }

  @override
  Future<List<ProductModel>> getAllUserProducts(String userId) async {
    try {
      final data = await _supabase.from('Product').select().eq('createdById', userId);
      return (data as List).map((e) => ProductModel.fromJson(e)).toList();
    } catch (e) {
      throw Exception(e.toString());
    }
  }

  @override
  Future<List<ProductModel>> getUserProducts(
    String userId, {
    String orderBy = 'createdAt',
    String sortBy = 'DESC',
    int limit = 10,
    int? offset,
    String? contains,
  }) async {
    try {
      var query = _supabase.from('Product').select().eq('createdById', userId);
      if (contains != null && contains.isNotEmpty) {
        query = query.ilike('name', '%$contains%');
      }
      // chaining order, limit, range
      if (offset != null) {
        final data = await query
            .order(orderBy, ascending: sortBy != 'DESC')
            .limit(limit)
            .range(offset, offset + limit - 1);
        return (data as List).map((e) => ProductModel.fromJson(e as Map<String, dynamic>)).toList();
      } else {
        final data = await query.order(orderBy, ascending: sortBy != 'DESC').limit(limit);
        return (data as List).map((e) => ProductModel.fromJson(e as Map<String, dynamic>)).toList();
      }
    } catch (e) {
      throw Exception(e.toString());
    }
  }
}
