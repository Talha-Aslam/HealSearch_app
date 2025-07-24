class CartItem {
  final String id;
  final String name;
  final String description;
  final double price;
  final String pharmacyName;
  final String category;
  int quantity;
  final String? expireDate;

  CartItem({
    required this.id,
    required this.name,
    required this.description,
    required this.price,
    required this.pharmacyName,
    required this.category,
    this.quantity = 1,
    this.expireDate,
  });

  factory CartItem.fromMap(Map<String, dynamic> map) {
    return CartItem(
      id: map['id'] ?? '',
      name: map['Name'] ?? '',
      description: map['Description'] ?? '',
      price: double.tryParse(
              map['Price'].toString().replaceAll(RegExp(r'[^0-9.]'), '')) ??
          0.0,
      pharmacyName: map['StoreName'] ?? '',
      category: map['Category'] ?? '',
      quantity: map['quantity'] ?? 1,
      expireDate: map['Expire'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'Name': name,
      'Description': description,
      'Price': 'Rs. $price',
      'StoreName': pharmacyName,
      'Category': category,
      'quantity': quantity,
      'Expire': expireDate,
    };
  }

  double get totalPrice => price * quantity;

  CartItem copyWith({
    String? id,
    String? name,
    String? description,
    double? price,
    String? pharmacyName,
    String? category,
    int? quantity,
    String? expireDate,
  }) {
    return CartItem(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      price: price ?? this.price,
      pharmacyName: pharmacyName ?? this.pharmacyName,
      category: category ?? this.category,
      quantity: quantity ?? this.quantity,
      expireDate: expireDate ?? this.expireDate,
    );
  }
}
