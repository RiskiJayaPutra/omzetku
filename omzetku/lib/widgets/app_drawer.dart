import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:csv/csv.dart';
import 'package:intl/intl.dart';
import '../models/transaction_model.dart';
import '../services/api_service.dart';
import '../screens/login_screen.dart';
import '../screens/edit_profile_screen.dart';
import 'profile_avatar.dart';

class AppDrawer extends StatefulWidget {
  const AppDrawer({super.key});

  @override
  State<AppDrawer> createState() => _AppDrawerState();
}

class _AppDrawerState extends State<AppDrawer> {
  // Gunakan singleton jika ApiService support, atau dispose dengan benar
  late final ApiService _apiService;
  String _userName = '';
  String? _photoUrl;
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _apiService = ApiService();
    _loadUserData();
  }

  @override
  void dispose() {
    // Dispose ApiService jika memiliki resources yang perlu dibersihkan
    // _apiService.dispose(); // Uncomment jika ApiService punya method dispose
    super.dispose();
  }

  Future<void> _loadUserData() async {
    if (!mounted) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final userData = await _apiService.getUser();

      if (!mounted) return;

      if (userData['success'] == true && userData['data'] != null) {
        final photoUrl = userData['data']['photo_url'];
        debugPrint('📷 AppDrawer loaded photo_url: $photoUrl');
        setState(() {
          _userName = userData['data']['nama_lengkap'] ?? 'User';
          _photoUrl = photoUrl;
          _isLoading = false;
        });
      } else {
        setState(() {
          _userName = 'User';
          _isLoading = false;
          _errorMessage = 'Gagal memuat data user';
        });
      }
    } catch (e) {
      debugPrint('Error loading user data: $e');

      if (!mounted) return;

      setState(() {
        _userName = 'User';
        _isLoading = false;
        _errorMessage = 'Terjadi kesalahan';
      });
    }
  }

  void _navigateAndClosDrawer(String routeName) async {
    Navigator.pop(context);
    await Future.delayed(const Duration(milliseconds: 200));
    if (mounted) {
      Navigator.pushNamed(context, routeName);
    }
  }

  void _showSnackBarSafely(String message) {
    if (mounted) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(message)));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Drawer(
      child: Column(
        children: [
          // Header
          Container(
            width: double.infinity,
            padding: const EdgeInsets.fromLTRB(20, 60, 20, 20),
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [Color(0xFF2196F3), Color(0xFF1976D2)],
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Avatar dengan loading state
                _isLoading
                    ? const CircleAvatar(
                        radius: 35,
                        backgroundColor: Colors.white,
                        child: CircularProgressIndicator(
                          color: Color(0xFF2196F3),
                          strokeWidth: 2,
                        ),
                      )
                    : ProfileAvatar(
                        imageUrl: _photoUrl != null && _photoUrl!.isNotEmpty
                            ? '${ApiService.baseUrl.replaceAll('/api', '')}/$_photoUrl'
                            : null,
                        radius: 35,
                        userName: _userName,
                      ),
                const SizedBox(height: 16),
                // Username dengan loading state
                _isLoading
                    ? Container(
                        height: 20,
                        width: 120,
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.3),
                          borderRadius: BorderRadius.circular(4),
                        ),
                      )
                    : Text(
                        _userName,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                const SizedBox(height: 4),
                // Error message jika ada
                if (_errorMessage != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Text(
                      _errorMessage!,
                      style: TextStyle(color: Colors.red[100], fontSize: 11),
                    ),
                  ),
                const SizedBox(height: 8),
                // Edit Profile Button
                InkWell(
                  onTap: () async {
                    Navigator.pop(context);
                    await Future.delayed(const Duration(milliseconds: 200));
                    if (mounted) {
                      final result = await Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const EditProfileScreen(),
                        ),
                      );
                      // Reload user data setelah edit profile
                      if (result == true && mounted) {
                        _loadUserData();
                      }
                    }
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: Colors.white.withOpacity(0.3),
                        width: 1,
                      ),
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.edit, color: Colors.white, size: 14),
                        SizedBox(width: 6),
                        Text(
                          'Edit Profile',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Menu Items
          Expanded(
            child: ListView(
              padding: EdgeInsets.zero,
              children: [
                const Padding(
                  padding: EdgeInsets.fromLTRB(20, 20, 20, 10),
                  child: Text(
                    'Management',
                    style: TextStyle(
                      color: Colors.grey,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                _buildMenuItem(
                  icon: Icons.inventory_2_outlined,
                  title: 'Produk',
                  onTap: () => _navigateAndClosDrawer('/product-management'),
                ),
                _buildMenuItem(
                  icon: Icons.delete_outline,
                  title: 'Delete & reset',
                  onTap: () {
                    _showResetDialog();
                  },
                ),
                _buildMenuItem(
                  icon: Icons.backup,
                  title: 'Backup & Restore',
                  onTap: () {
                    _showBackupRestoreDialog();
                  },
                ),
                _buildMenuItem(
                  icon: Icons.file_download_outlined,
                  title: 'Export Record',
                  onTap: () {
                    _exportToCsv();
                  },
                ),
                const Divider(height: 32),
                const Padding(
                  padding: EdgeInsets.fromLTRB(20, 10, 20, 10),
                  child: Text(
                    'Application',
                    style: TextStyle(
                      color: Colors.grey,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                _buildMenuItem(
                  icon: Icons.thumb_up_outlined,
                  title: 'Like Duit Kampus',
                  onTap: () {
                    Navigator.pop(context);
                    _showSnackBarSafely('Terima kasih!');
                  },
                ),
                _buildMenuItem(
                  icon: Icons.help_outline,
                  title: 'Help',
                  onTap: () {
                    Navigator.pop(context);
                    _showSnackBarSafely('Fitur Help');
                  },
                ),
                _buildMenuItem(
                  icon: Icons.feedback_outlined,
                  title: 'Give Feedback',
                  onTap: () {
                    Navigator.pop(context);
                    _showSnackBarSafely('Fitur Give Feedback');
                  },
                ),
              ],
            ),
          ),

          // Logout Button
          Padding(
            padding: const EdgeInsets.all(20),
            child: SizedBox(
              width: double.infinity,
              child: OutlinedButton(
                onPressed: () async {
                  // Show loading dialog
                  showDialog(
                    context: context,
                    barrierDismissible: false,
                    builder: (context) =>
                        const Center(child: CircularProgressIndicator()),
                  );

                  try {
                    await _apiService.logout();

                    if (!mounted) return;

                    // Close loading dialog
                    Navigator.of(context).pop();

                    // Navigate to login
                    Navigator.of(context).pushAndRemoveUntil(
                      MaterialPageRoute(builder: (_) => const LoginScreen()),
                      (route) => false,
                    );
                  } catch (e) {
                    debugPrint('Logout error: $e');

                    if (!mounted) return;

                    // Close loading dialog
                    Navigator.of(context).pop();

                    // Show error message
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Gagal logout. Silakan coba lagi.'),
                        backgroundColor: Colors.red,
                      ),
                    );
                  }
                },
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  side: const BorderSide(color: Colors.red, width: 2),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text(
                  'Keluar',
                  style: TextStyle(
                    color: Colors.red,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMenuItem({
    required IconData icon,
    required String title,
    required VoidCallback onTap,
  }) {
    return ListTile(
      leading: Icon(icon, color: Colors.grey[700]),
      title: Text(title, style: const TextStyle(fontSize: 15)),
      onTap: onTap,
      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
    );
  }

  void _showResetDialog() {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Reset Data'),
        content: const Text(
          'Apakah Anda yakin ingin menghapus semua data transaksi? Tindakan ini tidak dapat dibatalkan.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Batal'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(dialogContext);

              // Save context before showing loading dialog
              final scaffoldContext = context;

              // Show loading
              showDialog(
                context: scaffoldContext,
                barrierDismissible: false,
                builder: (loadingContext) =>
                    const Center(child: CircularProgressIndicator()),
              );

              try {
                await _apiService.resetTransactions();

                if (scaffoldContext.mounted) {
                  Navigator.of(
                    scaffoldContext,
                    rootNavigator: true,
                  ).pop(); // Close loading
                  ScaffoldMessenger.of(scaffoldContext).showSnackBar(
                    const SnackBar(
                      content: Text('Semua data berhasil dihapus'),
                      backgroundColor: Colors.green,
                    ),
                  );
                }
              } catch (e) {
                if (scaffoldContext.mounted) {
                  Navigator.of(
                    scaffoldContext,
                    rootNavigator: true,
                  ).pop(); // Close loading
                  ScaffoldMessenger.of(scaffoldContext).showSnackBar(
                    SnackBar(
                      content: Text('Gagal reset data: $e'),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              }
            },
            child: const Text('Reset', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  void _showBackupRestoreDialog() {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Backup & Restore'),
        content: const Text(
          'Backup akan menyimpan data ke file JSON. Restore akan import data dari file JSON.',
        ),
        actions: [
          TextButton(
            onPressed: () async {
              Navigator.pop(dialogContext);
              await _backupData();
            },
            child: const Text('Backup (Export)'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(dialogContext);
              await _restoreData();
            },
            child: const Text('Restore (Import)'),
          ),
        ],
      ),
    );
  }

  Future<void> _backupData() async {
    // Show loading
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(child: CircularProgressIndicator()),
    );

    try {
      final transactions = await _apiService.getTransactions();
      final jsonString = jsonEncode(
        transactions.map((e) => e.toJson()).toList(),
      );

      final directory = await getApplicationDocumentsDirectory();
      final fileName =
          'backup_transaction_${DateFormat('yyyyMMdd_HHmmss').format(DateTime.now())}.json';
      final file = File('${directory.path}/$fileName');
      await file.writeAsString(jsonString);

      if (mounted) {
        Navigator.pop(context); // Close loading

        // Share/Save dialog
        await Share.shareXFiles([
          XFile(file.path),
        ], text: 'Backup Data Transaksi');
      }
    } catch (e) {
      if (mounted) {
        Navigator.pop(context); // Close loading
        _showSnackBarSafely('Gagal backup: $e');
      }
    }
  }

  Future<void> _restoreData() async {
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['json'],
      );

      if (result != null) {
        // Show loading
        if (!mounted) return;
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (context) =>
              const Center(child: CircularProgressIndicator()),
        );

        File file = File(result.files.single.path!);
        String jsonString = await file.readAsString();
        List<dynamic> jsonList = jsonDecode(jsonString);

        // Validation check for list
        List<Transaction> transactions = [];
        for (var item in jsonList) {
          transactions.add(Transaction.fromJson(item));
        }

        // Send to API
        final res = await _apiService.importTransactions(transactions);

        if (mounted) {
          Navigator.pop(context); // Close loading

          if (res['success'] == true) {
            _showSnackBarSafely('Restore berhasil: ${res['message']}');
          } else {
            _showSnackBarSafely('Gagal restore: ${res['message']}');
          }
        }
      }
    } catch (e) {
      if (mounted) {
        // Try popping loading if open (risky if not open, but safe context check helps)
        Navigator.of(context, rootNavigator: true).pop();
        _showSnackBarSafely('Gagal restore: $e');
      }
    }
  }

  Future<void> _exportToCsv() async {
    // Show loading
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(child: CircularProgressIndicator()),
    );

    try {
      final transactions = await _apiService.getTransactions();

      List<List<dynamic>> rows = [];
      // Header
      rows.add(['ID', 'Title', 'Type', 'Category', 'Amount', 'Date', 'Notes']);

      // Data
      for (var t in transactions) {
        rows.add([
          t.id,
          t.title,
          t.type,
          t.category,
          t.amount,
          DateFormat('yyyy-MM-dd HH:mm:ss').format(t.dateTime),
          t.notes,
        ]);
      }

      String csvData = const ListToCsvConverter().convert(rows);

      final directory = await getApplicationDocumentsDirectory();
      final fileName =
          'omzetku_export_${DateFormat('yyyyMMdd_HHmmss').format(DateTime.now())}.csv';
      final file = File('${directory.path}/$fileName');
      await file.writeAsString(csvData);

      if (mounted) {
        Navigator.pop(context); // Close loading
        await Share.shareXFiles([
          XFile(file.path),
        ], text: 'Export Data Transaksi CSV');
      }
    } catch (e) {
      if (mounted) {
        Navigator.pop(context); // Close loading
        _showSnackBarSafely('Gagal export CSV: $e');
      }
    }
  }
}
