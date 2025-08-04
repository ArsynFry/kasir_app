import 'dart:io';

import 'package:supabase_flutter/supabase_flutter.dart';

class SupabaseStorageService {
  final SupabaseClient supabase;

  SupabaseStorageService({SupabaseClient? supabaseClient}) : supabase = supabaseClient ?? Supabase.instance.client;

  Future<String> uploadUserPhoto(String imgPath) async {
    final fileName = 'UserImage_${DateTime.now().millisecondsSinceEpoch}.jpg';
    final file = File(imgPath);
    final response = await supabase.storage.from('user_photos').upload(fileName, file);
    if (response.isEmpty) {
      throw Exception('Failed to upload user photo');
    }
    final publicUrl = supabase.storage.from('user_photos').getPublicUrl(fileName);
    return publicUrl;
  }

  Future<String> uploadProductImage(String imgPath) async {
    final fileName = 'ProductImage_${DateTime.now().millisecondsSinceEpoch}.jpg';
    final file = File(imgPath);
    final response = await supabase.storage.from('products').upload(fileName, file);
    if (response.isEmpty) {
      throw Exception('Failed to upload product image');
    }
    final publicUrl = supabase.storage.from('products').getPublicUrl(fileName);
    return publicUrl;
  }
}
