import 'package:flutter/material.dart';

/// Kategori Pengeluaran UMKM
class ExpenseCategory {
  final String id;
  final String name;
  final IconData icon;
  final Color color;
  final String? subcategory;

  const ExpenseCategory({
    required this.id,
    required this.name,
    required this.icon,
    required this.color,
    this.subcategory,
  });
}

/// Kategori Pemasukan UMKM
class IncomeCategory {
  final String id;
  final String name;
  final IconData icon;
  final Color color;

  const IncomeCategory({
    required this.id,
    required this.name,
    required this.icon,
    required this.color,
  });
}

/// Daftar Kategori Pengeluaran
class ExpenseCategories {
  static const modalBahan = ExpenseCategory(
    id: 'modal_bahan',
    name: 'Modal - Bahan',
    icon: Icons.inventory_2_outlined,
    color: Color(0xFFE8F5E9), // Light Green
    subcategory: 'bahan',
  );

  static const modalAlat = ExpenseCategory(
    id: 'modal_alat',
    name: 'Modal - Alat',
    icon: Icons.construction_outlined,
    color: Color(0xFFE3F2FD), // Light Blue
    subcategory: 'alat',
  );

  static const gajiKaryawan = ExpenseCategory(
    id: 'gaji_karyawan',
    name: 'Gaji Karyawan',
    icon: Icons.people_outline,
    color: Color(0xFFFFF3E0), // Light Orange
  );

  static const sewa = ExpenseCategory(
    id: 'sewa',
    name: 'Sewa',
    icon: Icons.store_outlined,
    color: Color(0xFFF3E5F5), // Light Purple
  );

  static const transportasi = ExpenseCategory(
    id: 'transportasi',
    name: 'Transportasi',
    icon: Icons.local_shipping_outlined,
    color: Color(0xFFE0F2F1), // Light Teal
  );

  static const jasa = ExpenseCategory(
    id: 'jasa',
    name: 'Jasa',
    icon: Icons.handyman_outlined,
    color: Color(0xFFFCE4EC), // Light Pink
  );

  static const piutang = ExpenseCategory(
    id: 'piutang',
    name: 'Piutang',
    icon: Icons.attach_money_outlined,
    color: Color(0xFFFFF9C4), // Light Yellow
  );

  static const operasional = ExpenseCategory(
    id: 'operasional',
    name: 'Operasional',
    icon: Icons.settings_outlined,
    color: Color(0xFFEFEBE9), // Light Brown
  );

  static const listrik = ExpenseCategory(
    id: 'listrik',
    name: 'Listrik & Air',
    icon: Icons.bolt_outlined,
    color: Color(0xFFFFECB3), // Light Amber
  );

  static const promosi = ExpenseCategory(
    id: 'promosi',
    name: 'Promosi & Marketing',
    icon: Icons.campaign_outlined,
    color: Color(0xFFE1BEE7), // Light Deep Purple
  );

  static const lainnya = ExpenseCategory(
    id: 'lainnya',
    name: 'Lainnya',
    icon: Icons.more_horiz,
    color: Color(0xFFECEFF1), // Light Blue Grey
  );

  static List<ExpenseCategory> get all => [
    modalBahan,
    modalAlat,
    gajiKaryawan,
    sewa,
    transportasi,
    jasa,
    piutang,
    operasional,
    listrik,
    promosi,
    lainnya,
  ];

  static ExpenseCategory? getById(String id) {
    try {
      return all.firstWhere((cat) => cat.id == id);
    } catch (e) {
      return null;
    }
  }

  static Color getColorById(String id) {
    final category = getById(id);
    return category?.color ?? const Color(0xFFECEFF1);
  }

  static IconData getIconById(String id) {
    final category = getById(id);
    return category?.icon ?? Icons.more_horiz;
  }
}

/// Daftar Kategori Pemasukan
class IncomeCategories {
  static const penjualanProduk = IncomeCategory(
    id: 'penjualan_produk',
    name: 'Penjualan Produk',
    icon: Icons.shopping_bag_outlined,
    color: Color(0xFFC8E6C9), // Green 100
  );

  static const penjualanJasa = IncomeCategory(
    id: 'penjualan_jasa',
    name: 'Penjualan Jasa',
    icon: Icons.work_outline,
    color: Color(0xFFBBDEFB), // Blue 100
  );

  static const pembayaranPiutang = IncomeCategory(
    id: 'pembayaran_piutang',
    name: 'Pembayaran Piutang',
    icon: Icons.account_balance_wallet_outlined,
    color: Color(0xFFFFF9C4), // Yellow 100
  );

  static const pendapatanLain = IncomeCategory(
    id: 'pendapatan_lain',
    name: 'Pendapatan Lain',
    icon: Icons.add_circle_outline,
    color: Color(0xFFD1C4E9), // Deep Purple 100
  );

  static List<IncomeCategory> get all => [
    penjualanProduk,
    penjualanJasa,
    pembayaranPiutang,
    pendapatanLain,
  ];

  static IncomeCategory? getById(String id) {
    try {
      return all.firstWhere((cat) => cat.id == id);
    } catch (e) {
      return null;
    }
  }

  static Color getColorById(String id) {
    final category = getById(id);
    return category?.color ?? const Color(0xFFE0E0E0);
  }

  static IconData getIconById(String id) {
    final category = getById(id);
    return category?.icon ?? Icons.attach_money;
  }
}
