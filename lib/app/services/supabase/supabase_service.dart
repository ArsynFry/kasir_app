import 'dart:io';

import 'package:supabase_flutter/supabase_flutter.dart';

class SupabaseService {
  final SupabaseClient supabase;

  SupabaseService({SupabaseClient? supabaseClient}) : supabase = supabaseClient ?? Supabase.instance.client;

  Future<String> uploadUserPhoto(String imgPath) async {
    final userId = Supabase.instance.client.auth.currentUser?.id;
    if (userId == null) throw Exception('User not logged in');
    final fileName = '$userId/UserImage_${DateTime.now().millisecondsSinceEpoch}.jpg';
    final file = File(imgPath);
    final response = await supabase.storage.from('userphotos').upload(fileName, file);
    if (response.isEmpty) {
      throw Exception('Failed to upload user photo');
    }
    final publicUrl = supabase.storage.from('userphotos').getPublicUrl(fileName);
    return publicUrl;
  }

  Future<String> uploadProductImage(String imgPath) async {
    final userId = Supabase.instance.client.auth.currentUser?.id;
    if (userId == null) throw Exception('User not logged in');
    // Log userId untuk debug
    print('[uploadProductImage] userId: $userId');
    final fileName = '$userId/ProductImages/ProductImage_${DateTime.now().millisecondsSinceEpoch}.jpg';
    final file = File(imgPath);
    final response = await supabase.storage.from('products').upload(fileName, file);
    if (response.isEmpty) {
      throw Exception('Failed to upload product image');
    }
    final publicUrl = supabase.storage.from('products').getPublicUrl(fileName);
    return publicUrl;
  }
}
