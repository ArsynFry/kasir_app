import 'package:supabase_flutter/supabase_flutter.dart';

import '../../models/user_model.dart';
import '../interfaces/user_datasource.dart';

class UserRemoteDatasourceImpl extends UserDatasource {
  final SupabaseClient _supabase;

  UserRemoteDatasourceImpl(this._supabase);

  @override
  Future<String> createUser(UserModel user) async {
    try {
      await _supabase.from('User').insert(user.toJson());
      return user.id;
    } catch (e) {
      throw Exception(e.toString());
    }
  }

  @override
  Future<void> updateUser(UserModel user) async {
    try {
      await _supabase.from('User').update(user.toJson()).eq('id', user.id);
    } catch (e) {
      throw Exception(e.toString());
    }
  }

  @override
  Future<void> deleteUser(String id) async {
    try {
      await _supabase.from('User').delete().eq('id', id);
    } catch (e) {
      throw Exception(e.toString());
    }
  }

  @override
  Future<UserModel?> getUser(String id) async {
    try {
      final data = await _supabase.from('User').select().eq('id', id).maybeSingle();
      if (data == null) return null;
      return UserModel.fromJson(data);
    } catch (e) {
      throw Exception(e.toString());
    }
  }
}
