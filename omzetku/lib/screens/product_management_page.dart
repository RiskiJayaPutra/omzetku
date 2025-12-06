import 'package:flutter/material.dart';
import '../models/product_model.dart';
import '../services/api_service.dart';
import '../widgets/toast_notification.dart';
import '../utils/currency_formatter.dart';

class ProductManagementPage extends StatefulWidget {
  const ProductManagementPage({super.key});

  @override
  State<ProductManagementPage> createState() => _ProductManagementPageState();
}

class _ProductManagementPageState extends State<ProductManagementPage> {
  final ApiService _apiService = ApiService();
  List<Product> _products = [];
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadProducts();
  }

  Future<void> _loadProducts() async {
    setState(() => _isLoading = true);
    try {
      final products = await _apiService.getProducts();
      setState(() {
        _products = products;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ToastNotification.showError(context, 'Gagal memuat produk: $e');
      }
    }
  }

  void _showAddProductDialog() {
    final nameController = TextEditingController();
    final priceController = TextEditingController();
    final descController = TextEditingController();
    String selectedType = 'fisik';

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('Tambah Produk'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: nameController,
                  decoration: const InputDecoration(labelText: 'Nama Produk'),
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<String>(
                  value: selectedType,
                  decoration: const InputDecoration(labelText: 'Tipe'),
                  items: const [
                    DropdownMenuItem(
                      value: 'fisik',
                      child: Text('Produk Fisik'),
                    ),
                    DropdownMenuItem(value: 'jasa', child: Text('Jasa')),
                  ],
                  onChanged: (value) =>
                      setDialogState(() => selectedType = value!),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: priceController,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(labelText: 'Harga'),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: descController,
                  maxLines: 3,
                  decoration: const InputDecoration(
                    labelText: 'Deskripsi (Opsional)',
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Batal'),
            ),
            ElevatedButton(
              onPressed: () async {
                if (nameController.text.isEmpty ||
                    priceController.text.isEmpty) {
                  ToastNotification.showError(
                    context,
                    'Nama produk dan harga harus diisi',
                  );
                  return;
                }

                try {
                  // Clean price format (remove dots for thousands separator)
                  final cleanPrice = priceController.text
                      .replaceAll('.', '')
                      .replaceAll(',', '.');
                  final priceValue = double.parse(cleanPrice);

                  final product = Product(
                    id: '',
                    name: nameController.text,
                    type: selectedType,
                    price: priceValue,
                    description: descController.text.isEmpty
                        ? null
                        : descController.text,
                    createdAt: DateTime.now(),
                  );

                  // Close dialog first
                  if (context.mounted) Navigator.pop(context);

                  // Show loading
                  if (mounted) setState(() => _isLoading = true);

                  // Save to API
                  await _apiService.addProduct(product);

                  // Reload products
                  await _loadProducts();

                  // Show success message
                  if (mounted) {
                    ToastNotification.showSuccess(
                      context,
                      'Produk berhasil ditambahkan',
                    );
                  }
                } catch (e) {
                  if (mounted) {
                    setState(() => _isLoading = false);
                    ToastNotification.showError(
                      context,
                      'Gagal menambah produk: $e',
                    );
                  }
                }
              },
              child: const Text('Simpan'),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Manajemen Produk'),
        backgroundColor: const Color(0xFF2196F3),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _products.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.inventory_2_outlined,
                    size: 80,
                    color: Colors.grey[400],
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Belum ada produk',
                    style: TextStyle(fontSize: 18, color: Colors.grey[600]),
                  ),
                  const SizedBox(height: 24),
                  ElevatedButton.icon(
                    onPressed: _showAddProductDialog,
                    icon: const Icon(Icons.add),
                    label: const Text('Tambah Produk'),
                  ),
                ],
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: _products.length,
              itemBuilder: (context, index) {
                final product = _products[index];
                return Card(
                  margin: const EdgeInsets.only(bottom: 12),
                  child: ListTile(
                    leading: CircleAvatar(
                      backgroundColor: product.type == 'fisik'
                          ? Colors.blue.shade100
                          : Colors.green.shade100,
                      child: Icon(
                        product.type == 'fisik'
                            ? Icons.inventory_2
                            : Icons.work,
                        color: product.type == 'fisik'
                            ? Colors.blue
                            : Colors.green,
                      ),
                    ),
                    title: Text(
                      product.name,
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    subtitle: Text(
                      'Rp ${CurrencyFormatter.format(product.price)}',
                    ),
                    trailing: IconButton(
                      icon: const Icon(Icons.delete, color: Colors.red),
                      onPressed: () async {
                        final confirm = await showDialog<bool>(
                          context: context,
                          builder: (context) => AlertDialog(
                            title: const Text('Konfirmasi'),
                            content: const Text('Hapus produk ini?'),
                            actions: [
                              TextButton(
                                onPressed: () => Navigator.pop(context, false),
                                child: const Text('Batal'),
                              ),
                              TextButton(
                                onPressed: () => Navigator.pop(context, true),
                                child: const Text(
                                  'Hapus',
                                  style: TextStyle(color: Colors.red),
                                ),
                              ),
                            ],
                          ),
                        );

                        if (confirm == true && mounted) {
                          setState(() => _isLoading = true);
                          try {
                            await _apiService.deleteProduct(product.id);
                            await _loadProducts();
                            if (mounted) {
                              ToastNotification.showSuccess(
                                context,
                                'Produk berhasil dihapus',
                              );
                            }
                          } catch (e) {
                            setState(() => _isLoading = false);
                            if (mounted) {
                              ToastNotification.showError(
                                context,
                                'Gagal menghapus produk: $e',
                              );
                            }
                          }
                        }
                      },
                    ),
                  ),
                );
              },
            ),
      floatingActionButton: _products.isNotEmpty
          ? FloatingActionButton(
              onPressed: _showAddProductDialog,
              backgroundColor: const Color(0xFF2196F3),
              child: const Icon(Icons.add),
            )
          : null,
    );
  }
}
