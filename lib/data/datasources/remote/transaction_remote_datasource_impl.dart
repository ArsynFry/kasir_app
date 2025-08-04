import 'package:supabase_flutter/supabase_flutter.dart';

import '../../models/ordered_product_model.dart';
import '../../models/product_model.dart';
import '../../models/transaction_model.dart';
import '../../models/user_model.dart';
import '../interfaces/transaction_datasource.dart';

class TransactionRemoteDatasourceImpl extends TransactionDatasource {
  final SupabaseClient _supabase;

  TransactionRemoteDatasourceImpl(this._supabase);

  @override
  Future<int> createTransaction(TransactionModel transaction) async {
    // Insert transaction
    try {
      await _supabase
          .from('Transaction')
          .insert(
            transaction.toJson()
              ..remove('orderedProducts')
              ..remove('createdBy'),
          );
      // Insert ordered products
      if (transaction.orderedProducts?.isNotEmpty ?? false) {
        for (var orderedProduct in transaction.orderedProducts!) {
          orderedProduct.transactionId = transaction.id;
          // Cek stok terbaru dari database
          final productData = await _supabase.from('Product').select().eq('id', orderedProduct.productId).maybeSingle();
          if (productData == null) continue;
          var product = ProductModel.fromJson(productData);
          if (product.stock < orderedProduct.quantity) {
            throw Exception('Stok produk ${product.name} tidak cukup!');
          }
          await _supabase.from('OrderedProduct').insert(orderedProduct.toJson());
          int stock = product.stock - orderedProduct.quantity;
          int sold = product.sold + orderedProduct.quantity;
          await _supabase.from('Product').update({'stock': stock, 'sold': sold}).eq('id', product.id);
        }
      }
      return transaction.id;
    } catch (e) {
      throw Exception(e.toString());
    }
  }

  @override
  Future<void> updateTransaction(TransactionModel transaction) async {
    // Update transaction
    try {
      await _supabase
          .from('Transaction')
          .update(
            transaction.toJson()
              ..remove('orderedProducts')
              ..remove('createdBy'),
          )
          .eq('id', transaction.id);
      // Update ordered products
      if (transaction.orderedProducts?.isNotEmpty ?? false) {
        for (var orderedProduct in transaction.orderedProducts!) {
          await _supabase.from('OrderedProduct').update(orderedProduct.toJson()).eq('id', orderedProduct.id);
          // Update product stock and sold
          final productData = await _supabase.from('Product').select().eq('id', orderedProduct.productId).maybeSingle();
          if (productData == null) continue;
          var product = ProductModel.fromJson(productData);
          int stock = product.stock - orderedProduct.quantity;
          int sold = product.sold + orderedProduct.quantity;
          await _supabase.from('Product').update({'stock': stock, 'sold': sold}).eq('id', product.id);
        }
      }
    } catch (e) {
      throw Exception(e.toString());
    }
  }

  @override
  Future<void> deleteTransaction(int id) async {
    // Get ordered products to revert stock
    try {
      final orderedProductsData = await _supabase.from('OrderedProduct').select().eq('transactionId', id);
      final orderedProducts =
          (orderedProductsData as List?)
              ?.map((e) => OrderedProductModel.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [];
      // Revert stock for each ordered product
      for (var orderedProduct in orderedProducts) {
        final productData = await _supabase.from('Product').select().eq('id', orderedProduct.productId).maybeSingle();
        if (productData != null) {
          var product = ProductModel.fromJson(productData);
          int revertedStock = product.stock + orderedProduct.quantity;
          int revertedSold = product.sold - orderedProduct.quantity;
          await _supabase.from('Product').update({'stock': revertedStock, 'sold': revertedSold}).eq('id', product.id);
        }
        // Delete ordered product
        await _supabase.from('OrderedProduct').delete().eq('id', orderedProduct.id);
      }
      // Delete transaction
      await _supabase.from('Transaction').delete().eq('id', id);
    } catch (e) {
      throw Exception(e.toString());
    }
  }

  @override
  Future<TransactionModel?> getTransaction(int id) async {
    try {
      final trxData = await _supabase.from('Transaction').select().eq('id', id).maybeSingle();
      if (trxData == null) return null;
      var transaction = TransactionModel.fromJson(trxData);
      // Get transaction ordered products
      final opData = await _supabase.from('OrderedProduct').select().eq('transactionId', transaction.id);
      final orderedProducts =
          (opData as List?)?.map((e) => OrderedProductModel.fromJson(e as Map<String, dynamic>)).toList() ?? [];
      transaction.orderedProducts = orderedProducts;
      // Get created by
      final userData = await _supabase.from('User').select().eq('id', transaction.createdById).maybeSingle();
      if (userData != null) {
        transaction.createdBy = UserModel.fromJson(userData);
      }
      return transaction;
    } catch (e) {
      throw Exception(e.toString());
    }
  }

  @override
  Future<List<TransactionModel>> getAllUserTransactions(String userId) async {
    try {
      final trxData = await _supabase.from('Transaction').select().eq('createdById', userId);
      final transactions =
          (trxData as List?)?.map((e) => TransactionModel.fromJson(e as Map<String, dynamic>)).toList() ?? [];
      for (var transaction in transactions) {
        // Get transaction ordered products
        final opData = await _supabase.from('OrderedProduct').select().eq('transactionId', transaction.id);
        final orderedProducts =
            (opData as List?)?.map((e) => OrderedProductModel.fromJson(e as Map<String, dynamic>)).toList() ?? [];
        transaction.orderedProducts = orderedProducts;
        // Get created by
        final userData = await _supabase.from('User').select().eq('id', transaction.createdById).maybeSingle();
        if (userData != null) {
          transaction.createdBy = UserModel.fromJson(userData);
        }
      }
      return transactions;
    } catch (e) {
      throw Exception(e.toString());
    }
  }

  @override
  Future<List<TransactionModel>> getUserTransactions(
    String userId, {
    String orderBy = 'createdAt',
    String sortBy = 'DESC',
    int limit = 10,
    int? offset,
    String? contains,
  }) async {
    try {
      var query = _supabase.from('Transaction').select().eq('createdById', userId);
      if (contains != null && contains.isNotEmpty) {
        query = query.ilike('id', '%$contains%');
      }
      if (offset != null) {
        final trxData = await query
            .order(orderBy, ascending: sortBy != 'DESC')
            .limit(limit)
            .range(offset, offset + limit - 1);
        final transactions =
            (trxData as List?)?.map((e) => TransactionModel.fromJson(e as Map<String, dynamic>)).toList() ?? [];
        for (var transaction in transactions) {
          final opData = await _supabase.from('OrderedProduct').select().eq('transactionId', transaction.id);
          final orderedProducts =
              (opData as List?)?.map((e) => OrderedProductModel.fromJson(e as Map<String, dynamic>)).toList() ?? [];
          transaction.orderedProducts = orderedProducts;
          final userData = await _supabase.from('User').select().eq('id', transaction.createdById).maybeSingle();
          if (userData != null) {
            transaction.createdBy = UserModel.fromJson(userData);
          }
        }
        return transactions;
      } else {
        final trxData = await query.order(orderBy, ascending: sortBy != 'DESC').limit(limit);
        final transactions =
            (trxData as List?)?.map((e) => TransactionModel.fromJson(e as Map<String, dynamic>)).toList() ?? [];
        for (var transaction in transactions) {
          final opData = await _supabase.from('OrderedProduct').select().eq('transactionId', transaction.id);
          final orderedProducts =
              (opData as List?)?.map((e) => OrderedProductModel.fromJson(e as Map<String, dynamic>)).toList() ?? [];
          transaction.orderedProducts = orderedProducts;
          final userData = await _supabase.from('User').select().eq('id', transaction.createdById).maybeSingle();
          if (userData != null) {
            transaction.createdBy = UserModel.fromJson(userData);
          }
        }
        return transactions;
      }
    } catch (e) {
      throw Exception(e.toString());
    }
  }
}
