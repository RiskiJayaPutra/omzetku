import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:fl_chart/fl_chart.dart';
import '../models/transaction_model.dart';
import '../services/api_service.dart';
import '../utils/currency_formatter.dart';

class GrafikPage extends StatefulWidget {
  const GrafikPage({super.key});

  @override
  State<GrafikPage> createState() => _GrafikPageState();
}

class _GrafikPageState extends State<GrafikPage> {
  final ApiService _apiService = ApiService();
  List<Transaction> _transactions = [];
  bool _isLoading = false;
  String _selectedTab = 'pengeluaran';
  DateTime _startDate = DateTime.now().subtract(const Duration(days: 30));
  DateTime _endDate = DateTime.now();
  bool _showLineChart = false;

  @override
  void initState() {
    super.initState();
    _loadTransactions();
  }

  @override
  void didUpdateWidget(GrafikPage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.key != widget.key) {
      _loadTransactions();
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
    }
  }

  Map<String, double> _getCategoryData() {
    final filteredTransactions = _transactions.where((t) {
      final isInRange =
          t.dateTime.isAfter(_startDate.subtract(const Duration(days: 1))) &&
          t.dateTime.isBefore(_endDate.add(const Duration(days: 1)));
      return isInRange &&
          (_selectedTab == 'pengeluaran' ? t.amount < 0 : t.amount > 0);
    }).toList();

    final Map<String, double> categoryData = {};
    for (var transaction in filteredTransactions) {
      final amount = transaction.amount.abs();
      categoryData[transaction.category] =
          (categoryData[transaction.category] ?? 0) + amount;
    }
    return categoryData;
  }

  @override
  Widget build(BuildContext context) {
    final categoryData = _getCategoryData();
    final total = categoryData.values.fold(0.0, (sum, value) => sum + value);
    final sortedEntries = categoryData.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    final pemasukan = _transactions
        .where((t) => t.amount > 0)
        .fold<double>(0.0, (sum, t) => sum + t.amount);
    final pengeluaran = _transactions
        .where((t) => t.amount < 0)
        .fold<double>(0.0, (sum, t) => sum + t.amount.abs());

    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        title: const Text('Grafik', style: TextStyle(color: Colors.white)),
        backgroundColor: const Color(0xFF2196F3),
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          IconButton(
            icon: const Icon(Icons.calendar_today),
            onPressed: () async {
              final picked = await showDateRangePicker(
                context: context,
                firstDate: DateTime(2020),
                lastDate: DateTime.now(),
                initialDateRange: DateTimeRange(
                  start: _startDate,
                  end: _endDate,
                ),
              );
              if (picked != null) {
                setState(() {
                  _startDate = picked.start;
                  _endDate = picked.end;
                });
              }
            },
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadTransactions,
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  // Date Range
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          '${DateFormat('d MMM yyyy').format(_startDate)} - ${DateFormat('d MMM yyyy').format(_endDate)}',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),

                  // UMKM Metrics Panel
                  _buildUMKMMetrics(pemasukan, pengeluaran),
                  const SizedBox(height: 16),

                  // Tab Selector
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: _buildTabButton(
                            'pengeluaran',
                            'Pengeluaran',
                            '-${CurrencyFormatter.formatWithPrefix(pengeluaran)}',
                          ),
                        ),
                        Expanded(
                          child: _buildTabButton(
                            'pemasukan',
                            'Pemasukan',
                            '+${CurrencyFormatter.formatWithPrefix(pemasukan)}',
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Chart Type Toggle
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        _buildChartTypeButton(
                          icon: Icons.pie_chart,
                          label: 'Pie Chart',
                          isSelected: !_showLineChart,
                          onTap: () => setState(() => _showLineChart = false),
                        ),
                        const SizedBox(width: 16),
                        _buildChartTypeButton(
                          icon: Icons.show_chart,
                          label: 'Line Chart',
                          isSelected: _showLineChart,
                          onTap: () => setState(() => _showLineChart = true),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Chart Display
                  if (categoryData.isNotEmpty)
                    _showLineChart
                        ? _buildLineChart()
                        : _buildPieChart(categoryData, total),
                  const SizedBox(height: 24),

                  // Category List
                  if (categoryData.isNotEmpty)
                    Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: ListView.separated(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: sortedEntries.length,
                        separatorBuilder: (context, index) =>
                            const Divider(height: 1),
                        itemBuilder: (context, index) {
                          final entry = sortedEntries[index];
                          final percentage = (entry.value / total * 100)
                              .toStringAsFixed(1);
                          final color = _getCategoryColor(index);

                          return ListTile(
                            leading: Container(
                              width: 40,
                              height: 40,
                              decoration: BoxDecoration(
                                color: color.withOpacity(0.2),
                                shape: BoxShape.circle,
                              ),
                              child: Icon(
                                _getCategoryIcon(entry.key),
                                color: color,
                                size: 20,
                              ),
                            ),
                            title: Text(
                              entry.key,
                              style: const TextStyle(
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            subtitle: Text('$percentage%'),
                            trailing: Text(
                              '${_selectedTab == 'pengeluaran' ? '-' : '+'}${CurrencyFormatter.formatWithPrefix(entry.value)}',
                              style: TextStyle(
                                color: _selectedTab == 'pengeluaran'
                                    ? Colors.red
                                    : Colors.green,
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),
                          );
                        },
                      ),
                    ),

                  if (categoryData.isEmpty)
                    Center(
                      child: Padding(
                        padding: const EdgeInsets.all(40),
                        child: Column(
                          children: [
                            Icon(
                              Icons.pie_chart_outline,
                              size: 64,
                              color: Colors.grey[400],
                            ),
                            const SizedBox(height: 16),
                            Text(
                              'Belum ada data untuk periode ini',
                              style: TextStyle(
                                fontSize: 16,
                                color: Colors.grey[600],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                ],
              ),
            ),
    );
  }

  Widget _buildTabButton(String value, String label, String amount) {
    final isSelected = _selectedTab == value;
    return GestureDetector(
      onTap: () => setState(() => _selectedTab = value),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF2196F3) : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          children: [
            Text(
              label,
              style: TextStyle(
                color: isSelected ? Colors.white : Colors.grey[600],
                fontSize: 14,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              amount,
              style: TextStyle(
                color: isSelected
                    ? Colors.white
                    : (value == 'pengeluaran' ? Colors.red : Colors.green),
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildUMKMMetrics(double pemasukan, double pengeluaran) {
    final profit = pemasukan - pengeluaran;
    final isProfit = profit >= 0;
    final profitMargin = pemasukan > 0 ? (profit / pemasukan * 100) : 0;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: isProfit
              ? [const Color(0xFF66BB6A), const Color(0xFF43A047)]
              : [const Color(0xFFEF5350), const Color(0xFFE53935)],
        ),
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: (isProfit ? Colors.green : Colors.red).withOpacity(0.3),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Status UMKM',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  children: [
                    Icon(
                      isProfit ? Icons.trending_up : Icons.trending_down,
                      color: Colors.white,
                      size: 16,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      isProfit ? 'UNTUNG' : 'RUGI',
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _buildMetricCard(
                  'Keuntungan',
                  profit,
                  Icons.account_balance_wallet,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildMetricCard(
                  'Margin',
                  profitMargin.toDouble(),
                  Icons.percent,
                  isPercentage: true,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMetricCard(
    String label,
    double value,
    IconData icon, {
    bool isPercentage = false,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.15),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: Colors.white70, size: 20),
          const SizedBox(height: 8),
          Text(
            label,
            style: const TextStyle(color: Colors.white70, fontSize: 12),
          ),
          const SizedBox(height: 4),
          Text(
            isPercentage
                ? '${value.toStringAsFixed(1)}%'
                : CurrencyFormatter.formatWithPrefix(value),
            style: const TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildChartTypeButton({
    required IconData icon,
    required String label,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF2196F3) : Colors.grey[200],
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          children: [
            Icon(
              icon,
              color: isSelected ? Colors.white : Colors.grey[600],
              size: 20,
            ),
            const SizedBox(width: 8),
            Text(
              label,
              style: TextStyle(
                color: isSelected ? Colors.white : Colors.grey[600],
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPieChart(Map<String, double> categoryData, double total) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          SizedBox(
            width: 200,
            height: 200,
            child: CustomPaint(
              painter: CategoryPieChartPainter(
                categoryData: categoryData,
                selectedTab: _selectedTab,
              ),
            ),
          ),
          const SizedBox(height: 24),
          Text(
            '${_selectedTab == 'pengeluaran' ? 'Pengeluaran' : 'Pemasukan'}: ${_selectedTab == 'pengeluaran' ? '-' : '+'}${CurrencyFormatter.formatWithPrefix(total)}',
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }

  Widget _buildLineChart() {
    final filteredTransactions = _transactions.where((t) {
      return t.dateTime.isAfter(_startDate.subtract(const Duration(days: 1))) &&
          t.dateTime.isBefore(_endDate.add(const Duration(days: 1)));
    }).toList()..sort((a, b) => a.dateTime.compareTo(b.dateTime));

    if (filteredTransactions.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(40),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Center(
          child: Text(
            'Tidak ada data untuk ditampilkan',
            style: TextStyle(color: Colors.grey[600]),
          ),
        ),
      );
    }

    final Map<DateTime, double> dailyData = {};
    for (var transaction in filteredTransactions) {
      final date = DateTime(
        transaction.dateTime.year,
        transaction.dateTime.month,
        transaction.dateTime.day,
      );
      final amount = _selectedTab == 'pengeluaran'
          ? (transaction.amount < 0 ? transaction.amount.abs() : 0)
          : (transaction.amount > 0 ? transaction.amount : 0);
      dailyData[date] = (dailyData[date] ?? 0) + amount;
    }

    final sortedDates = dailyData.keys.toList()..sort();
    final spots = <FlSpot>[];
    for (int i = 0; i < sortedDates.length; i++) {
      spots.add(FlSpot(i.toDouble(), dailyData[sortedDates[i]]!));
    }

    final maxY = dailyData.values.fold(
      0.0,
      (max, val) => val > max ? val : max,
    );

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Tren ${_selectedTab == 'pengeluaran' ? 'Pengeluaran' : 'Pemasukan'}',
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 24),
          SizedBox(
            height: 250,
            child: LineChart(
              LineChartData(
                gridData: FlGridData(
                  show: true,
                  drawVerticalLine: false,
                  horizontalInterval: maxY / 5,
                  getDrawingHorizontalLine: (value) {
                    return FlLine(color: Colors.grey[300], strokeWidth: 1);
                  },
                ),
                titlesData: FlTitlesData(
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 50,
                      getTitlesWidget: (value, meta) {
                        return Text(
                          NumberFormat.compact().format(value),
                          style: TextStyle(
                            color: Colors.grey[600],
                            fontSize: 10,
                          ),
                        );
                      },
                    ),
                  ),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 30,
                      getTitlesWidget: (value, meta) {
                        if (value.toInt() >= sortedDates.length) {
                          return const Text('');
                        }
                        final date = sortedDates[value.toInt()];
                        return Padding(
                          padding: const EdgeInsets.only(top: 8),
                          child: Text(
                            DateFormat('d/M').format(date),
                            style: TextStyle(
                              color: Colors.grey[600],
                              fontSize: 10,
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                  topTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  rightTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                ),
                borderData: FlBorderData(show: false),
                lineBarsData: [
                  LineChartBarData(
                    spots: spots,
                    isCurved: true,
                    color: _selectedTab == 'pengeluaran'
                        ? const Color(0xFFEF5350)
                        : const Color(0xFF66BB6A),
                    barWidth: 3,
                    isStrokeCapRound: true,
                    dotData: FlDotData(
                      show: true,
                      getDotPainter: (spot, percent, barData, index) {
                        return FlDotCirclePainter(
                          radius: 4,
                          color: Colors.white,
                          strokeWidth: 2,
                          strokeColor: barData.color ?? Colors.blue,
                        );
                      },
                    ),
                    belowBarData: BarAreaData(
                      show: true,
                      color:
                          (_selectedTab == 'pengeluaran'
                                  ? const Color(0xFFEF5350)
                                  : const Color(0xFF66BB6A))
                              .withOpacity(0.1),
                    ),
                  ),
                ],
                lineTouchData: LineTouchData(
                  touchTooltipData: LineTouchTooltipData(
                    getTooltipItems: (touchedSpots) {
                      return touchedSpots.map((spot) {
                        final date = sortedDates[spot.x.toInt()];
                        return LineTooltipItem(
                          '${DateFormat('d MMM').format(date)}\n${CurrencyFormatter.formatWithPrefix(spot.y)}',
                          const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        );
                      }).toList();
                    },
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Color _getCategoryColor(int index) {
    final colors = [
      const Color(0xFFFF6B6B),
      const Color(0xFFFFA726),
      const Color(0xFF66BB6A),
      const Color(0xFF42A5F5),
      const Color(0xFFAB47BC),
      const Color(0xFFFFEE58),
    ];
    return colors[index % colors.length];
  }

  IconData _getCategoryIcon(String category) {
    if (category.toLowerCase().contains('belanja') ||
        category.toLowerCase().contains('grocery')) {
      return Icons.shopping_cart;
    } else if (category.toLowerCase().contains('transport')) {
      return Icons.directions_car;
    } else if (category.toLowerCase().contains('makan') ||
        category.toLowerCase().contains('food')) {
      return Icons.restaurant;
    } else if (category.toLowerCase().contains('gaji') ||
        category.toLowerCase().contains('salary')) {
      return Icons.account_balance_wallet;
    } else if (category.toLowerCase().contains('freelance')) {
      return Icons.work;
    } else {
      return Icons.category;
    }
  }
}

class CategoryPieChartPainter extends CustomPainter {
  final Map<String, double> categoryData;
  final String selectedTab;

  CategoryPieChartPainter({
    required this.categoryData,
    required this.selectedTab,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final total = categoryData.values.fold(0.0, (sum, value) => sum + value);
    if (total == 0) return;

    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2;
    final paint = Paint()..style = PaintingStyle.fill;

    final colors = [
      const Color(0xFFFF6B6B),
      const Color(0xFFFFA726),
      const Color(0xFF66BB6A),
      const Color(0xFF42A5F5),
      const Color(0xFFAB47BC),
      const Color(0xFFFFEE58),
    ];

    double startAngle = -3.14159 / 2;
    int colorIndex = 0;

    for (var entry in categoryData.entries) {
      final sweepAngle = (entry.value / total) * 2 * 3.14159;
      paint.color = colors[colorIndex % colors.length];

      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        startAngle,
        sweepAngle,
        true,
        paint,
      );

      startAngle += sweepAngle;
      colorIndex++;
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
