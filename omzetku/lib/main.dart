import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';
import 'package:intl/intl.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'models/transaction_model.dart';
import 'models/product_model.dart';
import 'services/api_service.dart';
import 'screens/cari_riwayat_page.dart';
import 'screens/login_screen.dart';
import 'screens/grafik_page.dart';
import 'screens/anggaran_page.dart';
import 'screens/product_management_page.dart';
import 'widgets/app_drawer.dart';
import 'utils/categories.dart';
import 'utils/currency_formatter.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  await initializeDateFormatting('id_ID', null);
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'OmzetKu',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        visualDensity: VisualDensity.adaptivePlatformDensity,
        useMaterial3: false,
      ),
      home: const SplashScreen(),
      debugShowCheckedModeBanner: false,
    );
  }
}

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _checkLoginStatus();
  }

  Future<void> _checkLoginStatus() async {
    await Future.delayed(const Duration(seconds: 1));

    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('auth_token');

    if (mounted) {
      if (token != null && token.isNotEmpty) {
        // Token exists, auto login
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const FinanceApp()),
        );
      } else {
        // No token, go to login
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const LoginScreen()),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF2196F3), Color(0xFF1976D2), Color(0xFF0D47A1)],
          ),
        ),
        child: const Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.account_balance_wallet, size: 80, color: Colors.white),
              SizedBox(height: 20),
              Text(
                'OmzetKu',
                style: TextStyle(
                  fontSize: 36,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              SizedBox(height: 10),
              Text(
                'Kelola Keuangan UMKM Anda',
                style: TextStyle(fontSize: 16, color: Colors.white70),
              ),
              SizedBox(height: 40),
              CircularProgressIndicator(color: Colors.white),
            ],
          ),
        ),
      ),
    );
  }
}

class FinanceApp extends StatelessWidget {
  const FinanceApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'OmzetKu',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        visualDensity: VisualDensity.adaptivePlatformDensity,
        useMaterial3: false,
      ),
      home: const FinanceScreen(),
      routes: {
        '/product-management': (context) => const ProductManagementPage(),
      },
      debugShowCheckedModeBanner: false,
    );
  }
}

class FinanceScreen extends StatefulWidget {
  const FinanceScreen({super.key});

  @override
  State<FinanceScreen> createState() => _FinanceScreenState();
}

class _FinanceScreenState extends State<FinanceScreen> {
  final ApiService _apiService = ApiService();
  List<Transaction> _transactions = [];
  bool _isLoading = false;
  String _userName = '';
  String? _photoUrl;
  int _currentIndex = 0;
  double _anggaranBulanan = 500000.0;

  @override
  void initState() {
    super.initState();
    _loadUserData();
    _loadTransactions();
    _loadAnggaran();
  }

  Future<void> _loadAnggaran() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _anggaranBulanan = prefs.getDouble('anggaran_bulanan') ?? 500000.0;
    });
  }

  Future<void> _loadUserData() async {
    try {
      final userData = await _apiService.getUser();
      if (userData['success'] == true && userData['data'] != null) {
        final photoUrl = userData['data']['photo_url'];
        print('📷 Dashboard loaded photo_url: $photoUrl');
        setState(() {
          _userName = userData['data']['nama_lengkap'] ?? 'User';
          _photoUrl = photoUrl;
        });
      }
    } catch (e) {
      print('Error loading user data: $e');
    }
  }

  Future<void> _loadTransactions() async {
    setState(() => _isLoading = true);

    try {
      final transactions = await _apiService.getTransactions();
      setState(() {
        _transactions = transactions;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Gagal memuat transaksi: $e')));
      }
    }
  }

  void _addTransaction(Transaction newTransaction) async {
    try {
      final transaction = await _apiService.addTransaction(newTransaction);
      setState(() {
        _transactions.add(transaction);
        _transactions.sort((a, b) => b.dateTime.compareTo(a.dateTime));
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Transaksi berhasil ditambahkan')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Gagal menambah transaksi: $e')));
      }
    }
  }

  void _deleteTransaction(String id) async {
    try {
      await _apiService.deleteTransaction(id);
      setState(() {
        _transactions.removeWhere((t) => t.id == id);
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Transaksi berhasil dihapus')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Gagal menghapus transaksi: $e')),
        );
      }
    }
  }

  void _updateTransaction(Transaction updatedTransaction) async {
    try {
      final transaction = await _apiService.updateTransaction(
        updatedTransaction,
      );
      setState(() {
        final index = _transactions.indexWhere((t) => t.id == transaction.id);
        if (index != -1) {
          _transactions[index] = transaction;
          _transactions.sort((a, b) => b.dateTime.compareTo(a.dateTime));
        }
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Transaksi berhasil diperbarui')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Gagal memperbarui transaksi: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    const Color primaryColor = Color(0xFF1E88E5);

    final pemasukan = _transactions
        .where((t) => t.amount > 0)
        .fold<double>(0.0, (double sum, Transaction t) => sum + t.amount);

    final pengeluaran = _transactions
        .where((t) => t.amount < 0)
        .fold<double>(0.0, (double sum, Transaction t) => sum + t.amount.abs());

    final saldo = pemasukan - pengeluaran;

    final now = DateTime.now();
    final todayTransactions = _transactions
        .where(
          (t) =>
              t.dateTime.day == now.day &&
              t.dateTime.month == now.month &&
              t.dateTime.year == now.year,
        )
        .toList();

    // Group past transactions by date
    final pastTransactions = _transactions
        .where(
          (t) => t.dateTime.isBefore(DateTime(now.year, now.month, now.day)),
        )
        .toList();

    final groupedPastTransactions = <DateTime, List<Transaction>>{};
    for (var transaction in pastTransactions) {
      final date = DateTime(
        transaction.dateTime.year,
        transaction.dateTime.month,
        transaction.dateTime.day,
      );
      groupedPastTransactions.putIfAbsent(date, () => []).add(transaction);
    }

    final sortedDates = groupedPastTransactions.keys.toList()
      ..sort((a, b) => b.compareTo(a)); // Most recent first

    // Budget calculations
    final uangBulanan = _anggaranBulanan;
    final sisaUangBulanan = uangBulanan - pengeluaran;

    return Scaffold(
      backgroundColor: Colors.grey[100],
      endDrawer: AppDrawer(key: ValueKey(_userName + (_photoUrl ?? ''))),
      onEndDrawerChanged: (isOpened) {
        // Reload user data when drawer is opened
        if (isOpened) {
          _loadUserData();
        }
      },
      body: IndexedStack(
        index: _currentIndex,
        children: [
          _buildHomeTab(
            primaryColor,
            saldo,
            pemasukan,
            pengeluaran,
            uangBulanan,
            sisaUangBulanan,
            now,
            todayTransactions,
            groupedPastTransactions,
            sortedDates,
          ),
          GrafikPage(key: ValueKey(_currentIndex)),
          const AnggaranPage(),
          const CariRiwayatPage(),
        ],
      ),
      bottomNavigationBar: _buildBottomNavBar(primaryColor),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) =>
                  AddTransactionScreen(onAddTransaction: _addTransaction),
            ),
          );
        },
        backgroundColor: primaryColor,
        shape: const CircleBorder(),
        child: const Icon(Icons.add, color: Colors.white, size: 30),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
    );
  }

  Widget _buildHomeTab(
    Color primaryColor,
    double saldo,
    double pemasukan,
    double pengeluaran,
    double uangBulanan,
    double sisaUangBulanan,
    DateTime now,
    List<Transaction> todayTransactions,
    Map<DateTime, List<Transaction>> groupedPastTransactions,
    List<DateTime> sortedDates,
  ) {
    return RefreshIndicator(
      onRefresh: _loadTransactions,
      child: CustomScrollView(
        slivers: <Widget>[
          SliverAppBar(
            expandedHeight: 380.0,
            floating: false,
            pinned: true,
            backgroundColor: primaryColor,
            actions: [
              Builder(
                builder: (context) => IconButton(
                  icon: const Icon(Icons.menu),
                  onPressed: () => Scaffold.of(context).openEndDrawer(),
                ),
              ),
            ],
            flexibleSpace: FlexibleSpaceBar(
              background: Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [Color(0xFF2196F3), Color(0xFF1976D2)],
                  ),
                ),
                child: SafeArea(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            CircleAvatar(
                              radius: 20,
                              backgroundColor: Colors.white,
                              backgroundImage:
                                  _photoUrl != null && _photoUrl!.isNotEmpty
                                  ? NetworkImage(
                                          '${ApiService.baseUrl.replaceAll('/api', '')}/$_photoUrl',
                                        )
                                        as ImageProvider
                                  : null,
                              child: _photoUrl == null || _photoUrl!.isEmpty
                                  ? Text(
                                      _userName.isNotEmpty
                                          ? _userName[0].toUpperCase()
                                          : 'U',
                                      style: const TextStyle(
                                        color: Color(0xFF2196F3),
                                        fontWeight: FontWeight.bold,
                                        fontSize: 20,
                                      ),
                                    )
                                  : null,
                            ),
                            const SizedBox(width: 12),
                            Text(
                              'Halo, $_userName',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 18,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 24),
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    CurrencyFormatter.formatWithSign(saldo),
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 32,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  const SizedBox(height: 12),
                                  Row(
                                    children: [
                                      Container(
                                        width: 8,
                                        height: 8,
                                        decoration: const BoxDecoration(
                                          color: Color(0xFFFF6B6B),
                                          shape: BoxShape.circle,
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      Text(
                                        'Pemasukan: +${CurrencyFormatter.formatWithPrefix(pemasukan)}',
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontSize: 14,
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 8),
                                  Row(
                                    children: [
                                      Container(
                                        width: 8,
                                        height: 8,
                                        decoration: const BoxDecoration(
                                          color: Color(0xFFFFA726),
                                          shape: BoxShape.circle,
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      Text(
                                        'Pengeluaran: -${CurrencyFormatter.formatWithPrefix(pengeluaran)}',
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontSize: 14,
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 16),
                            Container(
                              width: 100,
                              height: 100,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: Colors.white24,
                                  width: 2,
                                ),
                              ),
                              child: Stack(
                                children: [
                                  if (pemasukan > 0 || pengeluaran > 0)
                                    CustomPaint(
                                      size: const Size(100, 100),
                                      painter: PieChartPainter(
                                        pemasukan: pemasukan,
                                        pengeluaran: pengeluaran,
                                      ),
                                    ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 24),
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.15),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Column(
                            children: [
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  const Text(
                                    'Uang Bulanan:',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 14,
                                    ),
                                  ),
                                  Text(
                                    CurrencyFormatter.formatWithPrefix(
                                      uangBulanan,
                                    ),
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 14,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              ClipRRect(
                                borderRadius: BorderRadius.circular(8),
                                child: LinearProgressIndicator(
                                  value: uangBulanan > 0
                                      ? (uangBulanan - pengeluaran) /
                                            uangBulanan
                                      : 0,
                                  backgroundColor: Colors.white24,
                                  valueColor:
                                      const AlwaysStoppedAnimation<Color>(
                                        Colors.white,
                                      ),
                                  minHeight: 8,
                                ),
                              ),
                              const SizedBox(height: 16),
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  const Text(
                                    'Sisa uang Bulanan:',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 14,
                                    ),
                                  ),
                                  Text(
                                    CurrencyFormatter.formatWithPrefix(
                                      sisaUangBulanan,
                                    ),
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 14,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: Container(
              color: Colors.grey[200],
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
              child: Text(
                DateFormat('dd MMMM yyyy', 'id_ID').format(now),
                style: const TextStyle(
                  fontSize: 14,
                  color: Colors.black54,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ),
          _isLoading
              ? const SliverToBoxAdapter(
                  child: Center(
                    child: Padding(
                      padding: EdgeInsets.all(20.0),
                      child: CircularProgressIndicator(),
                    ),
                  ),
                )
              : todayTransactions.isEmpty && groupedPastTransactions.isEmpty
              ? SliverToBoxAdapter(
                  child: Center(
                    child: Padding(
                      padding: const EdgeInsets.all(40.0),
                      child: Column(
                        children: [
                          Icon(
                            Icons.receipt_long,
                            size: 64,
                            color: Colors.grey[400],
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'Belum ada transaksi',
                            style: TextStyle(
                              fontSize: 16,
                              color: Colors.grey[600],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                )
              : SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (context, index) {
                      // Hitung total items
                      final totalToday = todayTransactions.length;

                      // Jika masih di bagian transaksi hari ini
                      if (index < totalToday) {
                        return _buildTransactionItem(
                          context: context,
                          transaction: todayTransactions[index],
                          onDelete: () =>
                              _deleteTransaction(todayTransactions[index].id),
                        );
                      }

                      // Jika sudah melewati transaksi hari ini, tampilkan past transactions
                      final pastIndex = index - totalToday;

                      // Hitung berapa header yang sudah ditampilkan
                      var currentOffset = 0;
                      for (
                        var dateIndex = 0;
                        dateIndex < sortedDates.length;
                        dateIndex++
                      ) {
                        final date = sortedDates[dateIndex];
                        final transactions = groupedPastTransactions[date]!;

                        // Header untuk tanggal
                        if (pastIndex == currentOffset) {
                          return Container(
                            color: Colors.grey[200],
                            padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
                            child: Text(
                              DateFormat('dd MMMM yyyy', 'id_ID').format(date),
                              style: const TextStyle(
                                fontSize: 14,
                                color: Colors.black54,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          );
                        }
                        currentOffset++;

                        // Transaksi untuk tanggal tersebut
                        if (pastIndex < currentOffset + transactions.length) {
                          final transIndex = pastIndex - currentOffset;
                          return _buildTransactionItem(
                            context: context,
                            transaction: transactions[transIndex],
                            onDelete: () =>
                                _deleteTransaction(transactions[transIndex].id),
                          );
                        }
                        currentOffset += transactions.length;
                      }

                      return const SizedBox.shrink();
                    },
                    childCount:
                        todayTransactions.length +
                        sortedDates.fold(
                          0,
                          (sum, date) =>
                              sum + 1 + groupedPastTransactions[date]!.length,
                        ),
                  ),
                ),
        ],
      ),
    );
  }

  Widget _buildTransactionItem({
    required BuildContext context,
    required Transaction transaction,
    required VoidCallback onDelete,
  }) {
    final bool isExpense = transaction.amount < 0;
    final Color amountColor = isExpense ? Colors.red : Colors.green;

    IconData iconData;
    Color iconColor;
    if (transaction.category.toLowerCase().contains('belanja')) {
      iconData = Icons.shopping_cart;
      iconColor = Colors.red;
    } else if (transaction.category.toLowerCase().contains('transportasi')) {
      iconData = Icons.directions_bike;
      iconColor = Colors.orange;
    } else if (transaction.type == 'Pemasukan') {
      iconData = Icons.account_balance_wallet;
      iconColor = Colors.green;
    } else {
      iconData = Icons.attach_money;
      iconColor = Colors.blueGrey;
    }

    return InkWell(
      onTap: () async {
        final result = await Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => TransactionDetailScreen(
              transaction: transaction,
              onDelete: onDelete,
            ),
          ),
        );

        // If transaction was updated or deleted, refresh the list
        if (result == 'deleted') {
          _loadTransactions();
        } else if (result is Transaction) {
          _updateTransaction(result);
        }
      },
      child: Card(
        margin: const EdgeInsets.symmetric(horizontal: 10.0, vertical: 4.0),
        elevation: 2,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12.0),
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 10.0),
          child: Row(
            children: [
              CircleAvatar(
                backgroundColor: iconColor.withOpacity(0.2),
                child: Icon(iconData, color: iconColor, size: 24),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      transaction.title,
                      style: const TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 15,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      transaction.category,
                      style: const TextStyle(fontSize: 13, color: Colors.grey),
                    ),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    '${isExpense ? '-' : '+'}Rp ${CurrencyFormatter.format(transaction.amount)}',
                    style: TextStyle(
                      color: amountColor,
                      fontWeight: FontWeight.w600,
                      fontSize: 15,
                    ),
                  ),
                  const SizedBox(height: 4),
                  IconButton(
                    icon: const Icon(Icons.edit, size: 18),
                    color: Colors.blue,
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                    onPressed: () async {
                      final result = await Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => EditTransactionScreen(
                            transaction: transaction,
                            onUpdate: (updatedTransaction) {
                              _updateTransaction(updatedTransaction);
                              Navigator.pop(context);
                            },
                          ),
                        ),
                      );
                      // Refresh if transaction was deleted or updated
                      if (result == 'deleted') {
                        _loadTransactions();
                      } else if (result is Transaction) {
                        _updateTransaction(result);
                      }
                    },
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBottomNavBar(Color primaryColor) {
    return BottomAppBar(
      color: Colors.white,
      shape: const CircularNotchedRectangle(),
      notchMargin: 6.0,
      elevation: 9.0,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: <Widget>[
          _buildNavItem(
            Icons.home,
            'Home',
            primaryColor,
            _currentIndex == 0,
            () {
              setState(() => _currentIndex = 0);
              _loadAnggaran();
            },
          ),
          _buildNavItem(
            Icons.pie_chart,
            'Grafik',
            primaryColor,
            _currentIndex == 1,
            () {
              setState(() => _currentIndex = 1);
            },
          ),
          const SizedBox(width: 48),
          _buildNavItem(
            Icons.account_balance_wallet,
            'Anggaran',
            primaryColor,
            _currentIndex == 2,
            () {
              setState(() => _currentIndex = 2);
            },
          ),
          _buildNavItem(
            Icons.search,
            'Riwayat',
            primaryColor,
            _currentIndex == 3,
            () {
              setState(() => _currentIndex = 3);
            },
          ),
        ],
      ),
    );
  }

  Widget _buildNavItem(
    IconData icon,
    String label,
    Color activeColor,
    bool isActive,
    VoidCallback onTap,
  ) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Icon(icon, color: isActive ? activeColor : Colors.grey, size: 28),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                color: isActive ? activeColor : Colors.grey,
                fontSize: 12,
                fontWeight: isActive ? FontWeight.w600 : FontWeight.normal,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class AddTransactionScreen extends StatefulWidget {
  final Function(Transaction) onAddTransaction;
  const AddTransactionScreen({super.key, required this.onAddTransaction});

  @override
  State<AddTransactionScreen> createState() => _AddTransactionScreenState();
}

class _AddTransactionScreenState extends State<AddTransactionScreen> {
  final ApiService _apiService = ApiService();
  String selectedType = 'Pengeluaran';
  double amount = 0;
  String category = '';
  String notes = '';
  String? selectedProductId;
  List<Product> _products = [];
  int quantity = 1;
  bool useManualInput = true;
  bool _isSaving = false;

  final TextEditingController _amountController = TextEditingController();
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _notesController = TextEditingController();
  final TextEditingController _quantityController = TextEditingController(
    text: '1',
  );

  List<String> get categories {
    if (selectedType == 'Pemasukan') {
      return IncomeCategories.all.map((cat) => cat.name).toList();
    } else {
      return ExpenseCategories.all.map((cat) => cat.name).toList();
    }
  }

  @override
  void initState() {
    super.initState();
    _amountController.addListener(_updateAmount);
    // Inisialisasi kategori dengan kategori pertama dari type saat ini
    if (categories.isNotEmpty) {
      category = categories.first;
    }
    _loadProducts();
  }

  Future<void> _loadProducts() async {
    try {
      final products = await _apiService.getProducts();
      setState(() {
        _products = products;
      });
    } catch (e) {
      // Error loading products - silently fail
    }
  }

  List<Product> get filteredProducts {
    if (category == 'Penjualan Produk') {
      return _products.where((p) => p.type == 'fisik').toList();
    } else if (category == 'Penjualan Jasa') {
      return _products.where((p) => p.type == 'jasa').toList();
    }
    return [];
  }

  void _updateQuantity() {
    setState(() {
      quantity = int.tryParse(_quantityController.text) ?? 1;
      if (quantity < 1) quantity = 1;
      _calculateAmount();
    });
  }

  void _calculateAmount() {
    if (!useManualInput && selectedProductId != null) {
      final product = _products.firstWhere((p) => p.id == selectedProductId);
      final calculatedAmount = product.price * quantity;
      _amountController.text = calculatedAmount.toStringAsFixed(0);
      amount = calculatedAmount;
    }
  }

  void _onProductChanged(String? productId) {
    setState(() {
      selectedProductId = productId;
      if (productId != null) {
        useManualInput = false;
        _calculateAmount();
        // Auto-fill title with product name
        final product = _products.firstWhere((p) => p.id == productId);
        _titleController.text = product.name;
      } else {
        useManualInput = true;
        quantity = 1;
        _quantityController.text = '1';
      }
    });
  }

  @override
  void dispose() {
    _amountController.dispose();
    _titleController.dispose();
    _notesController.dispose();
    _quantityController.dispose();
    super.dispose();
  }

  void _updateAmount() {
    String text = _amountController.text;

    // Hapus leading zeros kecuali jika hanya '0' atau kosong
    if (text.isNotEmpty && text != '0') {
      // Hapus semua karakter non-digit
      text = text.replaceAll(RegExp(r'[^0-9]'), '');

      // Hapus leading zeros
      text = text.replaceFirst(RegExp(r'^0+'), '');

      // Jika string kosong setelah dihapus, set ke kosong
      if (text.isEmpty) {
        text = '';
      }

      // Update controller jika ada perubahan
      if (text != _amountController.text) {
        final cursorPosition = text.length;
        _amountController.value = TextEditingValue(
          text: text,
          selection: TextSelection.collapsed(offset: cursorPosition),
        );
      }
    }

    setState(() {
      amount = double.tryParse(_amountController.text) ?? 0;
    });
  }

  void _saveTransaction() async {
    if (amount <= 0 || _titleController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Nominal dan Nama harus diisi.')),
      );
      return;
    }

    setState(() => _isSaving = true);

    final newTransaction = Transaction(
      id: const Uuid().v4(),
      title: _titleController.text,
      type: selectedType,
      category: category,
      amount: selectedType == 'Pengeluaran' ? -amount : amount,
      dateTime: DateTime.now(),
      notes: _notesController.text,
      productId: selectedProductId,
      quantity: selectedProductId != null ? quantity : null,
    );

    widget.onAddTransaction(newTransaction);

    // Tunggu sebentar agar callback selesai
    await Future.delayed(const Duration(milliseconds: 300));

    if (mounted) {
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    const Color primaryColor = Color(0xFF1E88E5);

    final String titleLabel = selectedType == 'Pemasukan'
        ? 'Nama Pemasukan'
        : 'Nama Pengeluaran';

    return Scaffold(
      backgroundColor: Colors.grey[200],
      appBar: AppBar(
        backgroundColor: primaryColor,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        elevation: 0,
      ),
      body: Column(
        children: [
          Container(
            color: primaryColor,
            padding: const EdgeInsets.only(bottom: 20),
            child: Column(
              children: [
                Row(
                  children: [
                    _buildTab('Pengeluaran', 'Pengeluaran', primaryColor),
                    _buildTab('Pemasukan', 'Pemasukan', primaryColor),
                  ],
                ),
                const SizedBox(height: 20),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Nominal',
                        style: TextStyle(color: Colors.white70, fontSize: 14),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          const Text(
                            'Rp ',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 32,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Expanded(
                            child: TextField(
                              controller: _amountController,
                              keyboardType: TextInputType.number,
                              enabled: useManualInput,
                              style: TextStyle(
                                color: useManualInput
                                    ? Colors.white
                                    : Colors.white70,
                                fontSize: 32,
                                fontWeight: FontWeight.bold,
                              ),
                              decoration: InputDecoration(
                                border: InputBorder.none,
                                hintText: useManualInput ? '0' : 'Otomatis',
                                hintStyle: const TextStyle(
                                  color: Colors.white54,
                                  fontSize: 32,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: Container(
              padding: const EdgeInsets.all(20.0),
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Nama Field
                    Text(
                      titleLabel,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: Colors.grey[700],
                      ),
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      key: const ValueKey('title_field'),
                      controller: _titleController,
                      textInputAction: TextInputAction.next,
                      decoration: InputDecoration(
                        hintText: 'Masukkan nama',
                        filled: true,
                        fillColor: Colors.white,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide.none,
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide.none,
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(
                            color: Color(0xFF1E88E5),
                            width: 2,
                          ),
                        ),
                        prefixIcon: const Icon(
                          Icons.description,
                          color: Color(0xFF1E88E5),
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 16,
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),

                    // Kategori Field
                    Text(
                      'Kategori',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: Colors.grey[700],
                      ),
                    ),
                    const SizedBox(height: 8),
                    DropdownButtonFormField<String>(
                      key: ValueKey('category_$selectedType'),
                      value: categories.contains(category)
                          ? category
                          : categories.first,
                      isExpanded: true,
                      decoration: InputDecoration(
                        hintText: 'Pilih kategori',
                        filled: true,
                        fillColor: Colors.white,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide.none,
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide.none,
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(
                            color: Color(0xFF1E88E5),
                            width: 2,
                          ),
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 12,
                        ),
                      ),
                      icon: const Icon(
                        Icons.keyboard_arrow_down,
                        color: Color(0xFF1E88E5),
                      ),
                      items: categories
                          .map(
                            (cat) => DropdownMenuItem(
                              value: cat,
                              child: Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(8),
                                    decoration: BoxDecoration(
                                      color:
                                          (selectedType == 'Pemasukan'
                                                  ? IncomeCategories.getColorById(
                                                      cat,
                                                    )
                                                  : ExpenseCategories.getColorById(
                                                      cat,
                                                    ))
                                              .withOpacity(0.15),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Icon(
                                      selectedType == 'Pemasukan'
                                          ? IncomeCategories.getIconById(cat)
                                          : ExpenseCategories.getIconById(cat),
                                      size: 20,
                                      color: selectedType == 'Pemasukan'
                                          ? IncomeCategories.getColorById(cat)
                                          : ExpenseCategories.getColorById(cat),
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Text(
                                    cat,
                                    style: const TextStyle(
                                      fontSize: 15,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          )
                          .toList(),
                      onChanged: (value) {
                        if (value != null) {
                          setState(() {
                            category = value;
                            // Reset produk ketika kategori berubah
                            selectedProductId = null;
                            useManualInput = true;
                            quantity = 1;
                            _quantityController.text = '1';
                          });
                        }
                      },
                    ),

                    // Produk Field (jika kategori Penjualan Produk atau Penjualan Jasa)
                    if (selectedType == 'Pemasukan' &&
                        (category == 'Penjualan Produk' ||
                            category == 'Penjualan Jasa')) ...[
                      const SizedBox(height: 20),
                      Text(
                        category == 'Penjualan Produk' ? 'Produk' : 'Jasa',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: Colors.grey[700],
                        ),
                      ),
                      const SizedBox(height: 8),
                      DropdownButtonFormField<String?>(
                        key: const ValueKey('product_dropdown'),
                        value: selectedProductId,
                        isExpanded: true,
                        decoration: InputDecoration(
                          hintText: 'Pilih produk',
                          filled: true,
                          fillColor: Colors.white,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide.none,
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide.none,
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: const BorderSide(
                              color: Color(0xFF1E88E5),
                              width: 2,
                            ),
                          ),
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 12,
                          ),
                        ),
                        icon: const Icon(
                          Icons.keyboard_arrow_down,
                          color: Color(0xFF1E88E5),
                        ),
                        items: [
                          const DropdownMenuItem<String?>(
                            value: null,
                            child: Text('Pilih item'),
                          ),
                          ...filteredProducts.map(
                            (product) => DropdownMenuItem<String?>(
                              value: product.id,
                              child: Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(6),
                                    decoration: BoxDecoration(
                                      color:
                                          (product.type == 'fisik'
                                                  ? Colors.blue
                                                  : Colors.green)
                                              .withOpacity(0.15),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Icon(
                                      product.type == 'fisik'
                                          ? Icons.inventory_2
                                          : Icons.work,
                                      size: 18,
                                      color: product.type == 'fisik'
                                          ? Colors.blue
                                          : Colors.green,
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Text(
                                      '${product.name} (Rp ${CurrencyFormatter.format(product.price)})',
                                      overflow: TextOverflow.ellipsis,
                                      style: const TextStyle(
                                        fontSize: 15,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                        onChanged: (value) {
                          _onProductChanged(value);
                        },
                      ),

                      // Quantity field (jika produk dipilih)
                      if (selectedProductId != null) ...[
                        const SizedBox(height: 20),
                        Text(
                          'Jumlah',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: Colors.grey[700],
                          ),
                        ),
                        const SizedBox(height: 8),
                        TextField(
                          key: const ValueKey('quantity_field'),
                          controller: _quantityController,
                          keyboardType: TextInputType.number,
                          textInputAction: TextInputAction.next,
                          onChanged: (value) => _updateQuantity(),
                          decoration: InputDecoration(
                            hintText: 'Masukkan jumlah',
                            filled: true,
                            fillColor: Colors.white,
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide.none,
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide.none,
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: const BorderSide(
                                color: Color(0xFF1E88E5),
                                width: 2,
                              ),
                            ),
                            prefixIcon: const Icon(
                              Icons.shopping_cart,
                              color: Color(0xFF1E88E5),
                            ),
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 16,
                            ),
                          ),
                        ),
                      ],
                    ],

                    // Notes Field
                    const SizedBox(height: 20),
                    Text(
                      'Catatan (Opsional)',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: Colors.grey[700],
                      ),
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: _notesController,
                      maxLines: 4,
                      decoration: InputDecoration(
                        hintText: 'Tambahkan catatan...',
                        filled: true,
                        fillColor: Colors.white,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide.none,
                        ),
                        contentPadding: const EdgeInsets.all(16),
                      ),
                    ),

                    const SizedBox(height: 24),

                    // Save Button
                    SizedBox(
                      width: double.infinity,
                      height: 54,
                      child: ElevatedButton(
                        onPressed: _isSaving ? null : _saveTransaction,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: primaryColor,
                          elevation: 2,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: _isSaving
                            ? const SizedBox(
                                height: 20,
                                width: 20,
                                child: CircularProgressIndicator(
                                  color: Colors.white,
                                  strokeWidth: 2,
                                ),
                              )
                            : const Text(
                                'Simpan Transaksi',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                  letterSpacing: 0.5,
                                ),
                              ),
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTab(String text, String type, Color primaryColor) {
    final isActive = selectedType == type;
    return Expanded(
      child: InkWell(
        onTap: () {
          setState(() {
            selectedType = type;
            category = categories.first;
          });
        },
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            border: Border(
              bottom: BorderSide(
                color: isActive ? Colors.white : Colors.transparent,
                width: 3,
              ),
            ),
          ),
          child: Text(
            text,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: isActive ? Colors.white : Colors.white60,
              fontSize: 16,
              fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
            ),
          ),
        ),
      ),
    );
  }
}

// Pie Chart Painter for dashboard
class PieChartPainter extends CustomPainter {
  final double pemasukan;
  final double pengeluaran;

  PieChartPainter({required this.pemasukan, required this.pengeluaran});

  @override
  void paint(Canvas canvas, Size size) {
    final total = pemasukan + pengeluaran;
    if (total == 0) return;

    final paint = Paint()..style = PaintingStyle.fill;
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2;

    // Draw pengeluaran (orange)
    paint.color = const Color(0xFFFFA726);
    final pengeluaranAngle = (pengeluaran / total) * 2 * 3.14159;
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      -3.14159 / 2,
      pengeluaranAngle,
      true,
      paint,
    );

    // Draw pemasukan (red)
    paint.color = const Color(0xFFFF6B6B);
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      -3.14159 / 2 + pengeluaranAngle,
      (pemasukan / total) * 2 * 3.14159,
      true,
      paint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}

class TransactionDetailScreen extends StatelessWidget {
  final Transaction transaction;
  final VoidCallback onDelete;

  const TransactionDetailScreen({
    super.key,
    required this.transaction,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    const Color primaryColor = Color(0xFF1E88E5);

    final Color iconColor = transaction.type == 'Pemasukan'
        ? Colors.green
        : Colors.red;
    final String amountText = CurrencyFormatter.format(transaction.amount);
    final String time = DateFormat('HH:mm').format(transaction.dateTime);
    final String date = DateFormat(
      'dd MMMM yyyy',
      'id_ID',
    ).format(transaction.dateTime);

    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        backgroundColor: primaryColor,
        title: const Text(
          'Detail Transaksi',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit, color: Colors.white),
            tooltip: 'Edit',
            onPressed: () async {
              final result = await Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => EditTransactionScreen(
                    transaction: transaction,
                    onUpdate: (updatedTransaction) {
                      // Pop edit screen
                      Navigator.pop(context);
                      // Pop detail screen with result
                      Navigator.pop(context, updatedTransaction);
                    },
                  ),
                ),
              );
              // Handle delete result
              if (result == 'deleted') {
                // Pop detail screen and return deleted flag
                Navigator.pop(context, 'deleted');
              }
            },
          ),
          IconButton(
            icon: const Icon(Icons.delete, color: Colors.white),
            tooltip: 'Hapus',
            onPressed: () {
              showDialog(
                context: context,
                builder: (dialogContext) => AlertDialog(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  title: Row(
                    children: [
                      Icon(
                        Icons.warning_amber_rounded,
                        color: Colors.orange[700],
                        size: 28,
                      ),
                      const SizedBox(width: 12),
                      const Text('Hapus Transaksi'),
                    ],
                  ),
                  content: const Text(
                    'Apakah Anda yakin ingin menghapus transaksi ini? Tindakan ini tidak dapat dibatalkan.',
                  ),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(dialogContext),
                      child: Text(
                        'Batal',
                        style: TextStyle(color: Colors.grey[600]),
                      ),
                    ),
                    ElevatedButton(
                      onPressed: () {
                        // Close dialog
                        Navigator.pop(dialogContext);
                        // Execute delete
                        onDelete();
                        // Close detail screen and return to dashboard
                        Navigator.pop(context);
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: const Text(
                        'Hapus',
                        style: TextStyle(color: Colors.white),
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ],
        elevation: 0,
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // Amount Card Header
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(32),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [iconColor, iconColor.withOpacity(0.7)],
                ),
              ),
              child: Column(
                children: [
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      transaction.type == 'Pemasukan'
                          ? Icons.arrow_downward_rounded
                          : Icons.arrow_upward_rounded,
                      size: 48,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    transaction.type,
                    style: const TextStyle(
                      fontSize: 16,
                      color: Colors.white,
                      fontWeight: FontWeight.w500,
                      letterSpacing: 0.5,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Rp $amountText',
                    style: const TextStyle(
                      fontSize: 40,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
            ),

            // Details Card
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Card(
                elevation: 2,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(20.0),
                  child: Column(
                    children: [
                      _buildDetailRow(
                        icon: Icons.title_rounded,
                        iconColor: Colors.blue,
                        label: 'Nama Transaksi',
                        value: transaction.title,
                      ),
                      const Divider(height: 32),
                      _buildDetailRow(
                        icon: Icons.category_rounded,
                        iconColor: Colors.purple,
                        label: 'Kategori',
                        value: transaction.category,
                      ),
                      const Divider(height: 32),
                      _buildDetailRow(
                        icon: Icons.calendar_today_rounded,
                        iconColor: Colors.orange,
                        label: 'Tanggal',
                        value: date,
                      ),
                      const Divider(height: 32),
                      _buildDetailRow(
                        icon: Icons.access_time_rounded,
                        iconColor: Colors.teal,
                        label: 'Waktu',
                        value: '$time WIB',
                      ),
                      if (transaction.notes.isNotEmpty) ...[
                        const Divider(height: 32),
                        _buildDetailRow(
                          icon: Icons.note_rounded,
                          iconColor: Colors.amber,
                          label: 'Catatan',
                          value: transaction.notes,
                          isMultiline: true,
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailRow({
    required IconData icon,
    required Color iconColor,
    required String label,
    required String value,
    bool isMultiline = false,
  }) {
    return Row(
      crossAxisAlignment: isMultiline
          ? CrossAxisAlignment.start
          : CrossAxisAlignment.center,
      children: [
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: iconColor.withOpacity(0.1),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, color: iconColor, size: 24),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: 13,
                  color: Colors.grey[600],
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                value,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Colors.black87,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

// Edit Transaction Screen
class EditTransactionScreen extends StatefulWidget {
  final Transaction transaction;
  final Function(Transaction) onUpdate;

  const EditTransactionScreen({
    super.key,
    required this.transaction,
    required this.onUpdate,
  });

  @override
  State<EditTransactionScreen> createState() => _EditTransactionScreenState();
}

class _EditTransactionScreenState extends State<EditTransactionScreen> {
  final ApiService _apiService = ApiService();
  late String selectedType;
  late double amount;
  late String category;
  late String notes;
  String? selectedProductId;
  List<Product> _products = [];
  int quantity = 1;
  bool useManualInput = true;

  late final TextEditingController _amountController;
  late final TextEditingController _titleController;
  late final TextEditingController _notesController;
  late final TextEditingController _quantityController;
  bool _isSaving = false;

  List<String> get categories {
    if (selectedType == 'Pemasukan') {
      return IncomeCategories.all.map((cat) => cat.name).toList();
    } else {
      return ExpenseCategories.all.map((cat) => cat.name).toList();
    }
  }

  @override
  void initState() {
    super.initState();
    // Initialize with existing transaction data
    selectedType = widget.transaction.type;
    amount = widget.transaction.amount.abs();
    category = widget.transaction.category;
    notes = widget.transaction.notes;

    _amountController = TextEditingController(text: amount.toStringAsFixed(0));
    _titleController = TextEditingController(text: widget.transaction.title);
    _notesController = TextEditingController(text: notes);
    _quantityController = TextEditingController(text: '1');

    // Load existing product if any
    selectedProductId = widget.transaction.productId;

    _amountController.addListener(_updateAmount);
    _loadProducts().then((_) {
      print('🔍 Products loaded: ${_products.length}');
      print('🔍 Transaction productId: ${widget.transaction.productId}');
      print('🔍 Transaction quantity: ${widget.transaction.quantity}');

      // Setelah produk di-load, gunakan quantity dari database jika ada
      if (selectedProductId != null && _products.isNotEmpty) {
        try {
          final product = _products.firstWhere(
            (p) => p.id == selectedProductId,
          );
          print('✅ Product found: ${product.name}');

          // Gunakan quantity dari database jika ada, kalau tidak hitung dari amount
          if (widget.transaction.quantity != null &&
              widget.transaction.quantity! > 0) {
            quantity = widget.transaction.quantity!;
            print('✅ Using quantity from DB: $quantity');
          } else if (product.price > 0) {
            // Hitung quantity dari amount yang tersimpan (fallback)
            quantity = (amount / product.price).round();
            if (quantity < 1) quantity = 1;
            print('⚠️ Calculated quantity from amount: $quantity');
          }
          setState(() {
            _quantityController.text = quantity.toString();
            useManualInput = false;
          });
        } catch (e) {
          print('❌ Product not found: $e');
          // Produk tidak ditemukan, gunakan manual input
          setState(() {
            selectedProductId = null;
            useManualInput = true;
          });
        }
      } else {
        print('ℹ️ No product selected or products empty');
      }
    });
  }

  Future<void> _loadProducts() async {
    try {
      final products = await _apiService.getProducts();
      setState(() {
        _products = products;
      });
    } catch (e) {
      // Error loading products - silently fail
    }
  }

  List<Product> get filteredProducts {
    if (category == 'Penjualan Produk') {
      return _products.where((p) => p.type == 'fisik').toList();
    } else if (category == 'Penjualan Jasa') {
      return _products.where((p) => p.type == 'jasa').toList();
    }
    return [];
  }

  void _updateQuantity() {
    setState(() {
      quantity = int.tryParse(_quantityController.text) ?? 1;
      if (quantity < 1) quantity = 1;
      _calculateAmount();
    });
  }

  void _calculateAmount() {
    if (!useManualInput && selectedProductId != null) {
      final product = _products.firstWhere((p) => p.id == selectedProductId);
      final calculatedAmount = product.price * quantity;
      _amountController.text = calculatedAmount.toStringAsFixed(0);
      amount = calculatedAmount;
    }
  }

  void _onProductChanged(String? productId) {
    setState(() {
      selectedProductId = productId;
      if (productId != null) {
        useManualInput = false;
        _calculateAmount();
        // Auto-fill title with product name
        final product = _products.firstWhere((p) => p.id == productId);
        _titleController.text = product.name;
      } else {
        useManualInput = true;
        quantity = 1;
        _quantityController.text = '1';
      }
    });
  }

  @override
  void dispose() {
    _amountController.dispose();
    _titleController.dispose();
    _notesController.dispose();
    _quantityController.dispose();
    super.dispose();
  }

  void _updateAmount() {
    String text = _amountController.text;

    // Hapus leading zeros kecuali jika hanya '0' atau kosong
    if (text.isNotEmpty && text != '0') {
      // Hapus semua karakter non-digit
      text = text.replaceAll(RegExp(r'[^0-9]'), '');

      // Hapus leading zeros
      text = text.replaceFirst(RegExp(r'^0+'), '');

      // Jika string kosong setelah dihapus, set ke kosong
      if (text.isEmpty) {
        text = '';
      }

      // Update controller jika ada perubahan
      if (text != _amountController.text) {
        final cursorPosition = text.length;
        _amountController.value = TextEditingValue(
          text: text,
          selection: TextSelection.collapsed(offset: cursorPosition),
        );
      }
    }

    setState(() {
      amount = double.tryParse(_amountController.text) ?? 0;
    });
  }

  Future<void> _saveTransaction() async {
    if (amount <= 0 || _titleController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Nominal dan Nama harus diisi.')),
      );
      return;
    }

    setState(() => _isSaving = true);

    try {
      final updatedTransaction = Transaction(
        id: widget.transaction.id,
        title: _titleController.text,
        type: selectedType,
        category: category,
        amount: selectedType == 'Pengeluaran' ? -amount : amount,
        dateTime: widget.transaction.dateTime,
        notes: _notesController.text,
        productId: selectedProductId,
        quantity: selectedProductId != null ? quantity : null,
      );

      final result = await _apiService.updateTransaction(updatedTransaction);

      if (mounted) {
        widget.onUpdate(result);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Transaksi berhasil diperbarui')),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isSaving = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Gagal memperbarui transaksi: $e')),
        );
      }
    }
  }

  void _resetForm() {
    setState(() {
      // Reset ke data transaksi awal
      selectedType = widget.transaction.type;
      amount = widget.transaction.amount.abs();
      category = widget.transaction.category;
      notes = widget.transaction.notes;
      selectedProductId = widget.transaction.productId;

      _amountController.text = amount.toStringAsFixed(0);
      _titleController.text = widget.transaction.title;
      _notesController.text = notes;

      // Reset quantity
      if (widget.transaction.quantity != null &&
          widget.transaction.quantity! > 0) {
        quantity = widget.transaction.quantity!;
        _quantityController.text = quantity.toString();
        useManualInput = false;
      } else {
        quantity = 1;
        _quantityController.text = '1';
        useManualInput = selectedProductId == null;
      }
    });

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Form telah direset ke data awal')),
    );
  }

  Future<void> _showDeleteConfirmation() async {
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Hapus Transaksi'),
        content: const Text(
          'Apakah Anda yakin ingin menghapus transaksi ini? Tindakan ini tidak dapat dibatalkan.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Batal'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Hapus'),
          ),
        ],
      ),
    );

    if (result == true && mounted) {
      await _deleteTransaction();
    }
  }

  Future<void> _deleteTransaction() async {
    setState(() => _isSaving = true);

    try {
      await _apiService.deleteTransaction(widget.transaction.id);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Transaksi berhasil dihapus')),
        );
        Navigator.pop(context, 'deleted');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Gagal menghapus transaksi: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    const Color primaryColor = Color(0xFF1E88E5);
    if (!categories.contains(category)) {
      category = categories.first;
    }

    final String titleLabel = selectedType == 'Pemasukan'
        ? 'Nama Pemasukan'
        : 'Nama Pengeluaran';

    return Scaffold(
      backgroundColor: Colors.grey[200],
      appBar: AppBar(
        backgroundColor: primaryColor,
        title: const Text(
          'Edit Transaksi',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
        ),
        leading: IconButton(
          icon: const Icon(Icons.close, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        elevation: 0,
      ),
      body: Column(
        children: [
          Container(
            color: primaryColor,
            padding: const EdgeInsets.only(bottom: 20),
            child: Column(
              children: [
                Row(
                  children: [
                    _buildTab('Pengeluaran', 'Pengeluaran', primaryColor),
                    _buildTab('Pemasukan', 'Pemasukan', primaryColor),
                  ],
                ),
                const SizedBox(height: 20),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Nominal',
                        style: TextStyle(color: Colors.white70, fontSize: 14),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          const Text(
                            'Rp ',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 32,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Expanded(
                            child: TextField(
                              controller: _amountController,
                              keyboardType: TextInputType.number,
                              enabled: useManualInput,
                              style: TextStyle(
                                color: useManualInput
                                    ? Colors.white
                                    : Colors.white70,
                                fontSize: 32,
                                fontWeight: FontWeight.bold,
                              ),
                              decoration: InputDecoration(
                                border: InputBorder.none,
                                hintText: useManualInput ? '0' : 'Otomatis',
                                hintStyle: const TextStyle(
                                  color: Colors.white54,
                                  fontSize: 32,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: Container(
              padding: const EdgeInsets.all(20.0),
              child: SingleChildScrollView(
                physics: const ClampingScrollPhysics(),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      titleLabel,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: Colors.grey[700],
                      ),
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: _titleController,
                      decoration: InputDecoration(
                        hintText: 'Masukkan nama',
                        filled: true,
                        fillColor: Colors.white,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide.none,
                        ),
                        prefixIcon: const Icon(
                          Icons.description,
                          color: Color(0xFF1E88E5),
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 16,
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                    Text(
                      'Kategori',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: Colors.grey[700],
                      ),
                    ),
                    const SizedBox(height: 8),
                    DropdownButtonFormField<String>(
                      value: category,
                      decoration: InputDecoration(
                        hintText: 'Pilih kategori',
                        filled: true,
                        fillColor: Colors.white,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide.none,
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 12,
                        ),
                      ),
                      icon: const Icon(
                        Icons.keyboard_arrow_down,
                        color: Color(0xFF1E88E5),
                      ),
                      items: categories
                          .map(
                            (cat) => DropdownMenuItem(
                              value: cat,
                              child: Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(8),
                                    decoration: BoxDecoration(
                                      color:
                                          (selectedType == 'Pemasukan'
                                                  ? IncomeCategories.getColorById(
                                                      cat,
                                                    )
                                                  : ExpenseCategories.getColorById(
                                                      cat,
                                                    ))
                                              .withOpacity(0.15),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Icon(
                                      selectedType == 'Pemasukan'
                                          ? IncomeCategories.getIconById(cat)
                                          : ExpenseCategories.getIconById(cat),
                                      size: 20,
                                      color: selectedType == 'Pemasukan'
                                          ? IncomeCategories.getColorById(cat)
                                          : ExpenseCategories.getColorById(cat),
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Text(
                                    cat,
                                    style: const TextStyle(
                                      fontSize: 15,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          )
                          .toList(),
                      onChanged: (value) {
                        if (value != null) {
                          setState(() {
                            category = value;
                            // Reset produk ketika kategori berubah
                            selectedProductId = null;
                            useManualInput = true;
                            quantity = 1;
                            _quantityController.text = '1';
                          });
                        }
                      },
                    ),

                    // Produk Field (jika kategori Penjualan Produk atau Penjualan Jasa)
                    if (selectedType == 'Pemasukan' &&
                        (category == 'Penjualan Produk' ||
                            category == 'Penjualan Jasa')) ...[
                      const SizedBox(height: 20),
                      Text(
                        category == 'Penjualan Produk' ? 'Produk' : 'Jasa',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: Colors.grey[700],
                        ),
                      ),
                      const SizedBox(height: 8),
                      DropdownButtonFormField<String?>(
                        key: const ValueKey('product_dropdown_edit'),
                        value:
                            (selectedProductId != null &&
                                filteredProducts.any(
                                  (p) => p.id == selectedProductId,
                                ))
                            ? selectedProductId
                            : null,
                        isExpanded: true,
                        decoration: InputDecoration(
                          hintText: 'Pilih item',
                          filled: true,
                          fillColor: Colors.white,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide.none,
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide.none,
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: const BorderSide(
                              color: Color(0xFF1E88E5),
                              width: 2,
                            ),
                          ),
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 12,
                          ),
                        ),
                        icon: const Icon(
                          Icons.keyboard_arrow_down,
                          color: Color(0xFF1E88E5),
                        ),
                        items: [
                          const DropdownMenuItem<String?>(
                            value: null,
                            child: Text('Pilih item'),
                          ),
                          ...filteredProducts.map(
                            (product) => DropdownMenuItem<String?>(
                              value: product.id,
                              child: Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(6),
                                    decoration: BoxDecoration(
                                      color:
                                          (product.type == 'fisik'
                                                  ? Colors.blue
                                                  : Colors.green)
                                              .withOpacity(0.15),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Icon(
                                      product.type == 'fisik'
                                          ? Icons.inventory_2
                                          : Icons.work,
                                      size: 18,
                                      color: product.type == 'fisik'
                                          ? Colors.blue
                                          : Colors.green,
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Text(
                                      '${product.name} (Rp ${CurrencyFormatter.format(product.price)})',
                                      overflow: TextOverflow.ellipsis,
                                      style: const TextStyle(
                                        fontSize: 15,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                        onChanged: (value) {
                          _onProductChanged(value);
                        },
                      ),

                      // Quantity field (jika produk dipilih)
                      if (selectedProductId != null) ...[
                        const SizedBox(height: 20),
                        Text(
                          'Jumlah',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: Colors.grey[700],
                          ),
                        ),
                        const SizedBox(height: 8),
                        TextField(
                          key: const ValueKey('quantity_field_edit'),
                          controller: _quantityController,
                          keyboardType: TextInputType.number,
                          textInputAction: TextInputAction.next,
                          onChanged: (value) => _updateQuantity(),
                          decoration: InputDecoration(
                            hintText: 'Masukkan jumlah',
                            filled: true,
                            fillColor: Colors.white,
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide.none,
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide.none,
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: const BorderSide(
                                color: Color(0xFF1E88E5),
                                width: 2,
                              ),
                            ),
                            prefixIcon: const Icon(
                              Icons.shopping_cart,
                              color: Color(0xFF1E88E5),
                            ),
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 16,
                            ),
                          ),
                        ),
                      ],
                    ],

                    const SizedBox(height: 20),
                    Text(
                      'Catatan (Opsional)',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: Colors.grey[700],
                      ),
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: _notesController,
                      maxLines: 4,
                      decoration: InputDecoration(
                        hintText: 'Tambahkan catatan...',
                        filled: true,
                        fillColor: Colors.white,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide.none,
                        ),
                        contentPadding: const EdgeInsets.all(16),
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Tombol Save
                    SizedBox(
                      width: double.infinity,
                      height: 54,
                      child: ElevatedButton(
                        onPressed: _isSaving ? null : _saveTransaction,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: primaryColor,
                          elevation: 2,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: _isSaving
                            ? const SizedBox(
                                height: 20,
                                width: 20,
                                child: CircularProgressIndicator(
                                  color: Colors.white,
                                  strokeWidth: 2,
                                ),
                              )
                            : const Text(
                                'Perbarui Transaksi',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                  letterSpacing: 0.5,
                                ),
                              ),
                      ),
                    ),
                    const SizedBox(height: 12),

                    // Tombol Reset
                    SizedBox(
                      width: double.infinity,
                      height: 54,
                      child: ElevatedButton(
                        onPressed: _isSaving ? null : _resetForm,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.white,
                          foregroundColor: const Color(0xFF1E88E5),
                          elevation: 0,
                          side: const BorderSide(
                            color: Color(0xFF1E88E5),
                            width: 2,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: const Text(
                          'Reset Form',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),

                    // Tombol Delete
                    SizedBox(
                      width: double.infinity,
                      height: 54,
                      child: ElevatedButton(
                        onPressed: _isSaving ? null : _showDeleteConfirmation,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.white,
                          foregroundColor: Colors.red,
                          elevation: 0,
                          side: const BorderSide(color: Colors.red, width: 2),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: const Text(
                          'Hapus Transaksi',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTab(String text, String type, Color primaryColor) {
    final isActive = selectedType == type;
    return Expanded(
      child: InkWell(
        onTap: () {
          setState(() {
            selectedType = type;
            category = categories.first;
          });
        },
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            border: Border(
              bottom: BorderSide(
                color: isActive ? Colors.white : Colors.transparent,
                width: 3,
              ),
            ),
          ),
          child: Text(
            text,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: isActive ? Colors.white : Colors.white60,
              fontSize: 16,
              fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
            ),
          ),
        ),
      ),
    );
  }
}
