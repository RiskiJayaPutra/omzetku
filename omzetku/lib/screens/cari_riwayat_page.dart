import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../models/transaction_model.dart';
import '../utils/currency_formatter.dart';

class CariRiwayatPage extends StatefulWidget {
  const CariRiwayatPage({super.key});

  @override
  State<CariRiwayatPage> createState() => _CariRiwayatPageState();
}

class _CariRiwayatPageState extends State<CariRiwayatPage> {
  final ApiService _apiService = ApiService();
  final TextEditingController _searchController = TextEditingController();
  final TextEditingController _minPriceController = TextEditingController();
  final TextEditingController _maxPriceController = TextEditingController();

  List<Transaction> _allTransactions = [];
  List<Transaction> _filteredTransactions = [];
  bool _isLoading = false;
  String _errorMessage = '';

  // Filter states
  String? _selectedType; // 'Pemasukan' or 'Pengeluaran'
  String? _selectedCategory;
  DateTimeRange? _selectedDateRange;
  double? _minPrice;
  double? _maxPrice;

  List<String> get _availableCategories {
    final categories = _allTransactions.map((t) => t.category).toSet().toList()
      ..sort();
    return categories;
  }

  @override
  void initState() {
    super.initState();
    _loadAllTransactions();
  }

  @override
  void dispose() {
    _searchController.dispose();
    _minPriceController.dispose();
    _maxPriceController.dispose();
    super.dispose();
  }

  Future<void> _loadAllTransactions() async {
    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });

    try {
      final transactions = await _apiService.getTransactions();
      setState(() {
        _allTransactions = transactions;
        _applyFilters();
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'Gagal memuat data: $e';
        _isLoading = false;
      });
    }
  }

  void _applyFilters() {
    List<Transaction> filtered = List.from(_allTransactions);

    // Search filter
    if (_searchController.text.isNotEmpty) {
      final query = _searchController.text.toLowerCase();
      filtered = filtered
          .where(
            (t) =>
                t.title.toLowerCase().contains(query) ||
                t.category.toLowerCase().contains(query) ||
                t.notes.toLowerCase().contains(query),
          )
          .toList();
    }

    // Type filter
    if (_selectedType != null) {
      filtered = filtered.where((t) => t.type == _selectedType).toList();
    }

    // Category filter
    if (_selectedCategory != null) {
      filtered = filtered
          .where((t) => t.category == _selectedCategory)
          .toList();
    }

    // Price range filter
    if (_minPrice != null) {
      filtered = filtered.where((t) => t.amount.abs() >= _minPrice!).toList();
    }
    if (_maxPrice != null) {
      filtered = filtered.where((t) => t.amount.abs() <= _maxPrice!).toList();
    }

    // Date range filter
    if (_selectedDateRange != null) {
      filtered = filtered.where((t) {
        final date = DateTime(
          t.dateTime.year,
          t.dateTime.month,
          t.dateTime.day,
        );
        final start = DateTime(
          _selectedDateRange!.start.year,
          _selectedDateRange!.start.month,
          _selectedDateRange!.start.day,
        );
        final end = DateTime(
          _selectedDateRange!.end.year,
          _selectedDateRange!.end.month,
          _selectedDateRange!.end.day,
        );
        return (date.isAfter(start) || date.isAtSameMomentAs(start)) &&
            (date.isBefore(end) || date.isAtSameMomentAs(end));
      }).toList();
    }

    setState(() {
      _filteredTransactions = filtered;
    });
  }

  Future<void> _searchTransactions(String query) async {
    _applyFilters();
  }

  void _clearFilters() {
    setState(() {
      _selectedType = null;
      _selectedCategory = null;
      _selectedDateRange = null;
      _minPrice = null;
      _maxPrice = null;
      _minPriceController.clear();
      _maxPriceController.clear();
      _searchController.clear();
      _applyFilters();
    });
  }

  bool _hasActiveFilters() {
    return _selectedType != null ||
        _selectedCategory != null ||
        _selectedDateRange != null ||
        _minPrice != null ||
        _maxPrice != null;
  }

  int _countActiveFilters() {
    int count = 0;
    if (_selectedType != null) count++;
    if (_selectedCategory != null) count++;
    if (_selectedDateRange != null) count++;
    if (_minPrice != null || _maxPrice != null) count++;
    return count;
  }

  Future<void> _showFilterDialog() async {
    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) {
          return Container(
            height: MediaQuery.of(context).size.height * 0.75,
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
            ),
            child: Column(
              children: [
                // Header
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.grey[50],
                    borderRadius: const BorderRadius.vertical(
                      top: Radius.circular(20),
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Filter Transaksi',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close),
                        onPressed: () => Navigator.pop(context),
                      ),
                    ],
                  ),
                ),

                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Type Filter
                        const Text(
                          'Tipe',
                          style: TextStyle(fontWeight: FontWeight.w600),
                        ),
                        const SizedBox(height: 8),
                        Wrap(
                          spacing: 8,
                          children: [
                            ChoiceChip(
                              label: const Text('Semua'),
                              selected: _selectedType == null,
                              onSelected: (selected) {
                                setModalState(() => _selectedType = null);
                              },
                            ),
                            ChoiceChip(
                              label: const Text('Pemasukan'),
                              selected: _selectedType == 'Pemasukan',
                              onSelected: (selected) {
                                setModalState(
                                  () => _selectedType = selected
                                      ? 'Pemasukan'
                                      : null,
                                );
                              },
                            ),
                            ChoiceChip(
                              label: const Text('Pengeluaran'),
                              selected: _selectedType == 'Pengeluaran',
                              onSelected: (selected) {
                                setModalState(
                                  () => _selectedType = selected
                                      ? 'Pengeluaran'
                                      : null,
                                );
                              },
                            ),
                          ],
                        ),

                        const SizedBox(height: 20),

                        // Category Filter
                        const Text(
                          'Kategori',
                          style: TextStyle(fontWeight: FontWeight.w600),
                        ),
                        const SizedBox(height: 8),
                        DropdownButtonFormField<String>(
                          value: _selectedCategory,
                          decoration: InputDecoration(
                            hintText: 'Pilih kategori',
                            filled: true,
                            fillColor: Colors.grey[50],
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                              borderSide: BorderSide.none,
                            ),
                          ),
                          items: [
                            const DropdownMenuItem(
                              value: null,
                              child: Text('Semua'),
                            ),
                            ..._availableCategories.map(
                              (cat) => DropdownMenuItem(
                                value: cat,
                                child: Text(cat),
                              ),
                            ),
                          ],
                          onChanged: (value) {
                            setModalState(() => _selectedCategory = value);
                          },
                        ),

                        const SizedBox(height: 20),

                        // Price Range
                        const Text(
                          'Range Harga',
                          style: TextStyle(fontWeight: FontWeight.w600),
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            Expanded(
                              child: TextField(
                                controller: _minPriceController,
                                keyboardType: TextInputType.number,
                                decoration: InputDecoration(
                                  labelText: 'Min',
                                  prefix: const Text('Rp '),
                                  filled: true,
                                  fillColor: Colors.grey[50],
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(8),
                                    borderSide: BorderSide.none,
                                  ),
                                ),
                                onChanged: (value) {
                                  setModalState(() {
                                    _minPrice = double.tryParse(value);
                                  });
                                },
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: TextField(
                                controller: _maxPriceController,
                                keyboardType: TextInputType.number,
                                decoration: InputDecoration(
                                  labelText: 'Max',
                                  prefix: const Text('Rp '),
                                  filled: true,
                                  fillColor: Colors.grey[50],
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(8),
                                    borderSide: BorderSide.none,
                                  ),
                                ),
                                onChanged: (value) {
                                  setModalState(() {
                                    _maxPrice = double.tryParse(value);
                                  });
                                },
                              ),
                            ),
                          ],
                        ),

                        const SizedBox(height: 20),

                        // Date Range
                        const Text(
                          'Range Tanggal',
                          style: TextStyle(fontWeight: FontWeight.w600),
                        ),
                        const SizedBox(height: 8),
                        OutlinedButton.icon(
                          onPressed: () async {
                            final picked = await showDateRangePicker(
                              context: context,
                              firstDate: DateTime(2020),
                              lastDate: DateTime.now(),
                              initialDateRange: _selectedDateRange,
                            );
                            if (picked != null) {
                              setModalState(() => _selectedDateRange = picked);
                            }
                          },
                          icon: const Icon(Icons.calendar_today),
                          label: Text(
                            _selectedDateRange == null
                                ? 'Pilih tanggal'
                                : '${_selectedDateRange!.start.day}/${_selectedDateRange!.start.month}/${_selectedDateRange!.start.year} - ${_selectedDateRange!.end.day}/${_selectedDateRange!.end.month}/${_selectedDateRange!.end.year}',
                          ),
                          style: OutlinedButton.styleFrom(
                            minimumSize: const Size(double.infinity, 48),
                          ),
                        ),
                        if (_selectedDateRange != null)
                          TextButton(
                            onPressed: () {
                              setModalState(() => _selectedDateRange = null);
                            },
                            child: const Text('Hapus tanggal'),
                          ),
                      ],
                    ),
                  ),
                ),

                // Apply Button
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.grey.withOpacity(0.2),
                        spreadRadius: 1,
                        blurRadius: 5,
                        offset: const Offset(0, -2),
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () {
                            _clearFilters();
                            Navigator.pop(context);
                          },
                          child: const Text('Reset'),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        flex: 2,
                        child: ElevatedButton(
                          onPressed: () {
                            setState(() => _applyFilters());
                            Navigator.pop(context);
                          },
                          child: const Text('Terapkan Filter'),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  IconData _getIconForCategory(String category) {
    final lowerCategory = category.toLowerCase();
    if (lowerCategory.contains('belanja')) {
      return Icons.shopping_cart_outlined;
    } else if (lowerCategory.contains('transportasi') ||
        lowerCategory.contains('bensin')) {
      return Icons.directions_car_outlined;
    } else if (lowerCategory.contains('makan')) {
      return Icons.restaurant_outlined;
    } else if (lowerCategory.contains('hiburan')) {
      return Icons.movie_outlined;
    } else if (lowerCategory.contains('gaji')) {
      return Icons.account_balance_wallet_outlined;
    } else {
      return Icons.attach_money_outlined;
    }
  }

  Color _getColorForType(String type) {
    return type == 'Pemasukan'
        ? const Color(0xFF4CAF50)
        : const Color(0xFFFF6F6F);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      appBar: AppBar(
        backgroundColor: const Color(0xFF2196F3),
        centerTitle: true,
        elevation: 0,
        title: const Text(
          "Cari Riwayat",
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Stack(
        children: [
          Column(
            children: [
              // Search bar
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: TextField(
                  controller: _searchController,
                  onChanged: (value) {
                    _searchTransactions(value);
                  },
                  decoration: InputDecoration(
                    hintText: "Cari transaksi...",
                    hintStyle: const TextStyle(color: Colors.grey),
                    filled: true,
                    fillColor: Colors.white,
                    prefixIcon: const Icon(Icons.search, color: Colors.grey),
                    suffixIcon: _searchController.text.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear, color: Colors.grey),
                            onPressed: () {
                              _searchController.clear();
                              _applyFilters();
                            },
                          )
                        : null,
                    contentPadding: const EdgeInsets.symmetric(
                      vertical: 12,
                      horizontal: 8,
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide.none,
                    ),
                  ),
                ),
              ),

              // Filter Button
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                child: Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () => _showFilterDialog(),
                        icon: const Icon(Icons.filter_list),
                        label: Text(
                          _hasActiveFilters()
                              ? 'Filter Aktif (${_countActiveFilters()})'
                              : 'Filter',
                        ),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: _hasActiveFilters()
                              ? Colors.blue
                              : Colors.grey[700],
                          side: BorderSide(
                            color: _hasActiveFilters()
                                ? Colors.blue
                                : Colors.grey[300]!,
                          ),
                        ),
                      ),
                    ),
                    if (_hasActiveFilters()) ...[
                      const SizedBox(width: 8),
                      TextButton(
                        onPressed: _clearFilters,
                        child: const Text('Reset'),
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: 8),

              // Content
              Expanded(
                child: _isLoading
                    ? const Center(child: CircularProgressIndicator())
                    : _errorMessage.isNotEmpty
                    ? Center(
                        child: Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(
                                Icons.error_outline,
                                size: 64,
                                color: Colors.red,
                              ),
                              const SizedBox(height: 16),
                              Text(
                                _errorMessage,
                                textAlign: TextAlign.center,
                                style: const TextStyle(color: Colors.red),
                              ),
                              const SizedBox(height: 16),
                              ElevatedButton(
                                onPressed: _loadAllTransactions,
                                child: const Text('Coba Lagi'),
                              ),
                            ],
                          ),
                        ),
                      )
                    : _filteredTransactions.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(
                              Icons.search_off,
                              size: 64,
                              color: Colors.grey,
                            ),
                            const SizedBox(height: 16),
                            Text(
                              _searchController.text.isEmpty
                                  ? 'Belum ada transaksi'
                                  : 'Tidak ada hasil pencarian',
                              style: const TextStyle(
                                fontSize: 16,
                                color: Colors.grey,
                              ),
                            ),
                          ],
                        ),
                      )
                    : RefreshIndicator(
                        onRefresh: _loadAllTransactions,
                        child: ListView.builder(
                          itemCount: _filteredTransactions.length,
                          itemBuilder: (context, index) {
                            final transaction = _filteredTransactions[index];
                            return Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 6,
                              ),
                              child: Container(
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: ListTile(
                                  leading: CircleAvatar(
                                    backgroundColor: _getColorForType(
                                      transaction.type,
                                    ),
                                    child: Icon(
                                      _getIconForCategory(transaction.category),
                                      color: Colors.white,
                                    ),
                                  ),
                                  title: Text(
                                    transaction.title,
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w600,
                                      fontSize: 15,
                                    ),
                                  ),
                                  subtitle: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        transaction.category,
                                        style: const TextStyle(
                                          fontSize: 13,
                                          color: Colors.grey,
                                        ),
                                      ),
                                      Text(
                                        '${transaction.dateTime.day}/${transaction.dateTime.month}/${transaction.dateTime.year}',
                                        style: const TextStyle(
                                          fontSize: 12,
                                          color: Colors.grey,
                                        ),
                                      ),
                                    ],
                                  ),
                                  trailing: Text(
                                    '${transaction.amount >= 0 ? '+' : ''}Rp ${CurrencyFormatter.format(transaction.amount)}',
                                    style: TextStyle(
                                      color: transaction.amount >= 0
                                          ? Colors.green
                                          : Colors.red,
                                      fontWeight: FontWeight.w600,
                                      fontSize: 14,
                                    ),
                                  ),
                                  onTap: () {
                                    // Navigate to detail
                                  },
                                ),
                              ),
                            );
                          },
                        ),
                      ),
              ),
            ],
          ),

          // Logo watermark
          if (_filteredTransactions.isEmpty && !_isLoading)
            Center(
              child: Opacity(
                opacity: 0.15,
                child: Image.asset(
                  'assets/images/omzetku.png',
                  width: 200,
                  height: 200,
                  errorBuilder: (context, error, stackTrace) {
                    return const Icon(
                      Icons.image_not_supported,
                      size: 200,
                      color: Colors.grey,
                    );
                  },
                ),
              ),
            ),
        ],
      ),
    );
  }
}
