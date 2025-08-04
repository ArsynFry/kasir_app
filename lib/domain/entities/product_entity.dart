import 'package:equatable/equatable.dart';

class ProductEntity extends Equatable {
  final int? id;
  final String createdById;
  final String name;
  final String imageUrl;
  final int stock;
  final int? sold;
  final int price;
  // Removed unit field
  final String? description;
  final String? createdAt;
  final String? updatedAt;

  const ProductEntity({
    this.id,
    required this.createdById,
    required this.name,
    required this.imageUrl,
    required this.stock,
    this.sold,
    required this.price,
    // Removed unit from constructor
    this.description,
    this.createdAt,
    this.updatedAt,
  });

  ProductEntity copyWith({
    int? id,
    String? createdById,
    String? name,
    String? imageUrl,
    int? stock,
    int? sold,
    int? price,
    // Removed unit from copyWith
    String? description,
    String? createdAt,
    String? updatedAt,
  }) {
    return ProductEntity(
      id: id ?? this.id,
      createdById: createdById ?? this.createdById,
      name: name ?? this.name,
      imageUrl: imageUrl ?? this.imageUrl,
      stock: stock ?? this.stock,
      sold: sold ?? this.sold,
      price: price ?? this.price,
      // Removed unit from copyWith
      description: description ?? this.description,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  List<Object?> get props => [
    id,
    createdById,
    name,
    imageUrl,
    stock,
    sold,
    price,
    // Removed unit from props
    description,
    createdAt,
    updatedAt,
  ];
}
