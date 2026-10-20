// Modelos del catálogo: Product y Rating (mismos campos que la FakeStore API).

class Rating {
  const Rating({required this.rate, required this.count});

  const Rating.empty()
      : rate = 0,
        count = 0;

  factory Rating.fromJson(Map<String, dynamic> json) {
    return Rating(
      rate: _toDouble(json['rate']),
      count: _toInt(json['count']),
    );
  }

  final double rate;
  final int count;

  Map<String, dynamic> toJson() => {'rate': rate, 'count': count};
}

class Product {
  const Product({
    required this.id,
    required this.title,
    required this.price,
    required this.description,
    required this.category,
    required this.image,
    this.rating = const Rating.empty(),
    this.isLocal = false,
  });

  /// Convierte el JSON que regresa la API en un objeto Product.
  factory Product.fromJson(Map<String, dynamic> json) {
    final rating = json['rating'];
    return Product(
      id: _toInt(json['id']),
      title: (json['title'] ?? '').toString().trim(),
      price: _toDouble(json['price']),
      description: (json['description'] ?? '').toString().trim(),
      category: (json['category'] ?? '').toString().trim(),
      image: (json['image'] ?? '').toString().trim(),
      rating: rating is Map<String, dynamic>
          ? Rating.fromJson(rating)
          : const Rating.empty(),
      isLocal: json['isLocal'] == true,
    );
  }

  final int id;
  final String title;
  final double price;
  final String description;
  final String category;
  final String image;
  final Rating rating;

  /// `true` si el producto se creó desde la app (la API no lo guarda).
  final bool isLocal;

  bool get hasRating => rating.count > 0;

  String get formattedPrice => '\$${price.toStringAsFixed(2)}';

  /// Cuerpo que se envía a la API en POST y PUT.
  Map<String, dynamic> toApiJson() => {
        'title': title,
        'price': price,
        'description': description,
        'image': image,
        'category': category,
      };

  /// JSON completo para guardar el producto en el dispositivo.
  Map<String, dynamic> toJson() => {
        'id': id,
        ...toApiJson(),
        'rating': rating.toJson(),
        'isLocal': isLocal,
      };

  Product copyWith({
    int? id,
    String? title,
    double? price,
    String? description,
    String? category,
    String? image,
    Rating? rating,
    bool? isLocal,
  }) {
    return Product(
      id: id ?? this.id,
      title: title ?? this.title,
      price: price ?? this.price,
      description: description ?? this.description,
      category: category ?? this.category,
      image: image ?? this.image,
      rating: rating ?? this.rating,
      isLocal: isLocal ?? this.isLocal,
    );
  }
}

double _toDouble(Object? value) {
  if (value is num) return value.toDouble();
  if (value is String) return double.tryParse(value) ?? 0;
  return 0;
}

int _toInt(Object? value) {
  if (value is num) return value.toInt();
  if (value is String) return int.tryParse(value) ?? 0;
  return 0;
}
