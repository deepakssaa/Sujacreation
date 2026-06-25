class Product {
  final int id;
  final String name;
  final String price; // Effective price
  final String regularPrice; // Actual price before discount
  final String description;
  final List<String> images;
  final List<Map<String, dynamic>> categories;
  final List<Map<String, dynamic>> attributes;
  final String sku;
  final String type; // simple, variable, etc.
  final String stockStatus; // instock, outofstock
  final int parentId;
  final List<int> variationIds;

  Product({
    required this.id,
    required this.name,
    required this.price,
    required this.regularPrice,
    required this.description,
    required this.images,
    required this.categories,
    required this.attributes,
    required this.sku,
    required this.type,
    required this.stockStatus,
    this.parentId = 0,
    this.variationIds = const [],
  });

  String get imageUrl => images.isNotEmpty ? images[0] : '';
  bool get isOnSale => regularPrice.isNotEmpty && regularPrice != price;
  bool get isVariable => type == 'variable';

  factory Product.fromJson(Map<String, dynamic> json) {
    // Parse images list
    final List<dynamic> imageList = json['images'] ?? [];
    final List<String> parsedImages =
        imageList.map((img) => (img['src'] ?? '').toString()).toList();

    // Parse categories
    final List<dynamic> catList = json['categories'] ?? [];
    final List<Map<String, dynamic>> parsedCategories = catList
        .map((cat) => {
              'id': cat['id'],
              'name': cat['name'],
            })
        .toList();

    // Parse attributes
    final List<dynamic> attrList = json['attributes'] ?? [];
    final List<Map<String, dynamic>> parsedAttributes = attrList
        .map((attr) => {
              'id': attr['id'],
              'name': attr['name'],
              'options': (attr['options'] as List?) ?? [],
            })
        .toList();

    return Product(
      id: json['id'] ?? 0,
      name: json['name'] ?? '',
      price: (json['price'] ?? '').toString(),
      regularPrice: (json['regular_price'] ?? '').toString(),
      description: json['description'] ?? '',
      images: parsedImages,
      categories: parsedCategories,
      attributes: parsedAttributes,
      sku: (json['sku'] ?? '').toString(),
      type: json['type'] ?? 'simple',
      stockStatus: json['stock_status'] ?? 'instock',
      parentId: json['parent_id'] ?? 0,
      variationIds: List<int>.from(json['variations'] ?? []),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'price': price,
      'regular_price': regularPrice,
      'description': description,
      'images': images.map((src) => {'src': src}).toList(),
      'categories': categories,
      'attributes': attributes,
      'sku': sku,
      'type': type,
      'stock_status': stockStatus,
      'parent_id': parentId,
      'variations': variationIds,
    };
  }
}

class ProductVariation {
  final int id;
  final String price;
  final String regularPrice;
  final String sku;
  final String stockStatus;
  final Map<String, String> attributes;
  final String? image;

  ProductVariation({
    required this.id,
    required this.price,
    required this.regularPrice,
    required this.sku,
    required this.stockStatus,
    required this.attributes,
    this.image,
  });

  factory ProductVariation.fromJson(Map<String, dynamic> json) {
    final Map<String, String> attrs = {};
    if (json['attributes'] != null) {
      for (var attr in json['attributes']) {
        attrs[attr['name']] = attr['option'] ?? '';
      }
    }

    return ProductVariation(
      id: json['id'] ?? 0,
      price: (json['price'] ?? '').toString(),
      regularPrice: (json['regular_price'] ?? '').toString(),
      sku: (json['sku'] ?? '').toString(),
      stockStatus: json['stock_status'] ?? 'instock',
      attributes: attrs,
      image: json['image'] != null ? json['image']['src'] : null,
    );
  }
}
