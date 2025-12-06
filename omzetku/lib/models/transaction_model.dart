class Transaction {
  final String id;
  final String title;
  final String type; // 'Pemasukan' atau 'Pengeluaran'
  final String category;
  final double amount;
  final DateTime dateTime;
  final String notes;
  final String? productId; // ID produk jika transaksi terkait produk
  final String? productName; // Nama produk untuk display
  final int? quantity; // Jumlah produk yang terjual
  final String? subcategory; // Subkategori (untuk modal: bahan/alat)
  final String? customCategory; // Kategori custom untuk pendapatan lain

  Transaction({
    required this.id,
    required this.title,
    required this.type,
    required this.category,
    required this.amount,
    required this.dateTime,
    this.notes = '',
    this.productId,
    this.productName,
    this.quantity,
    this.subcategory,
    this.customCategory,
  });

  // Convert from JSON
  factory Transaction.fromJson(Map<String, dynamic> json) {
    return Transaction(
      id: json['id'].toString(),
      title: json['title'] ?? '',
      type: json['type'] ?? '',
      category: json['category'] ?? '',
      amount: (json['amount'] is String)
          ? double.tryParse(json['amount']) ?? 0.0
          : (json['amount'] ?? 0.0).toDouble(),
      dateTime: json['date_time'] != null
          ? DateTime.parse(json['date_time'])
          : DateTime.now(),
      notes: json['notes'] ?? '',
      productId: json['product_id']?.toString(),
      productName: json['product_name'],
      quantity: json['quantity'] != null
          ? int.tryParse(json['quantity'].toString())
          : null,
      subcategory: json['subcategory'],
      customCategory: json['custom_category'],
    );
  }

  // Convert to JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'type': type,
      'category': category,
      'amount': amount,
      'date_time': dateTime.toIso8601String(),
      'notes': notes,
      if (productId != null) 'product_id': productId,
      if (productName != null) 'product_name': productName,
      if (quantity != null) 'quantity': quantity,
      if (subcategory != null) 'subcategory': subcategory,
      if (customCategory != null) 'custom_category': customCategory,
    };
  }
}
