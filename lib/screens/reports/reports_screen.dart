import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../models/transaction.dart';
import '../../providers/product_provider.dart';
import '../../providers/settings_provider.dart';
import '../../providers/transaction_provider.dart';
import '../../utils/helpers.dart';
import '../shared/section_header.dart';

class ReportsScreen extends StatefulWidget {
  const ReportsScreen({super.key});

  @override
  State<ReportsScreen> createState() => _ReportsScreenState();
}

class _ReportsScreenState extends State<ReportsScreen> {
  late Future<_ReportsData> _reportsFuture;
  bool _recentExpanded = false;
  bool _lowStockExpanded = false;

  @override
  void initState() {
    super.initState();
    _reportsFuture = _loadReportsData();
  }

  /// Adjusts the reports layout for smaller screens.
  double _scale(double width) {
    if (width < 340) return 0.82;
    if (width < 390) return 0.92;
    if (width < 430) return 0.98;
    return 1.0;
  }

  /// Loads the summary data used by the reports dashboard cards and charts.
  Future<_ReportsData> _loadReportsData() async {
    final transactionProvider = context.read<TransactionProvider>();
    final today = DateUtils.dateOnly(DateTime.now());
    final weekStart = today.subtract(const Duration(days: 6));

    final totalsFuture = transactionProvider.getDailyTotalsInRange(
      startDate: weekStart,
      endDate: today,
    );
    final recentFuture = transactionProvider.getRecentTransactions(limit: 10);

    final totals = await totalsFuture;
    final recentTransactions = await recentFuture;

    final daySales = List<_DaySalesPoint>.generate(7, (index) {
      final date = weekStart.add(Duration(days: index));
      final key = DateFormat('yyyy-MM-dd').format(date);
      return _DaySalesPoint(date: date, amount: totals[key] ?? 0);
    });

    return _ReportsData(
      todaySales: daySales.last.amount,
      weekSales: daySales,
      recentTransactions: recentTransactions,
    );
  }

  /// Refreshes inventory and report data together for a consistent dashboard.
  Future<void> _refreshDashboard() async {
    await context.read<ProductProvider>().loadProducts();
    setState(() {
      _reportsFuture = _loadReportsData();
    });
    await _reportsFuture;
  }

  @override

  /// Builds the reports dashboard with sales charts and expandable summaries.
  Widget build(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    final scale = _scale(width);
    final settings = context.watch<SettingsProvider>();
    final productProvider = context.watch<ProductProvider>();
    final lowStockProducts = productProvider.products
        .where((item) => item.quantity <= settings.lowStockThreshold)
        .toList();

    return Scaffold(
      body: Column(
        children: [
          SectionHeader(storeName: settings.storeName),
          Expanded(
            child: Container(
              width: double.infinity,
              color: const Color(0xFFF2F4F7),
              child: FutureBuilder<_ReportsData>(
                future: _reportsFuture,
                builder: (context, snapshot) {
                  return RefreshIndicator(
                    onRefresh: _refreshDashboard,
                    child: ListView(
                      physics: const AlwaysScrollableScrollPhysics(),
                      padding: EdgeInsets.fromLTRB(
                        16 * scale,
                        14 * scale,
                        16 * scale,
                        24 * scale,
                      ),
                      children: [
                        if (snapshot.connectionState == ConnectionState.waiting)
                          Padding(
                            padding: EdgeInsets.only(top: 36 * scale),
                            child: const Center(
                              child: CircularProgressIndicator(),
                            ),
                          )
                        else if (snapshot.hasError)
                          _StatusCard(
                            scale: scale,
                            child: Text(
                              'Unable to load reports. Pull down to retry.',
                              style: TextStyle(
                                fontSize: 14 * scale,
                                fontWeight: FontWeight.w600,
                                color: const Color(0xFF334155),
                              ),
                            ),
                          )
                        else ...[
                          _TodaySalesCard(
                            amount: snapshot.data?.todaySales ?? 0,
                            currencyCode: settings.currencyCode,
                            scale: scale,
                          ),
                          SizedBox(height: 12 * scale),
                          _WeeklySalesCard(
                            points: snapshot.data?.weekSales ?? const [],
                            currencyCode: settings.currencyCode,
                            scale: scale,
                          ),
                          SizedBox(height: 12 * scale),
                          _ExpandableCard(
                            icon: Icons.history,
                            iconColor: const Color(0xFF64748B),
                            title: 'Recent Transactions',
                            badgeValue:
                                '${snapshot.data?.recentTransactions.length ?? 0}',
                            expanded: _recentExpanded,
                            scale: scale,
                            onTap: () {
                              setState(() {
                                _recentExpanded = !_recentExpanded;
                              });
                            },
                            child: _RecentTransactionsContent(
                              transactions:
                                  snapshot.data?.recentTransactions ?? const [],
                              currencyCode: settings.currencyCode,
                              scale: scale,
                            ),
                          ),
                          SizedBox(height: 12 * scale),
                          _ExpandableCard(
                            icon: Icons.error_outline,
                            iconColor: const Color(0xFFFF6B00),
                            title: 'Low Stock Items',
                            badgeValue: '${lowStockProducts.length}',
                            expanded: _lowStockExpanded,
                            highlighted: true,
                            scale: scale,
                            onTap: () {
                              setState(() {
                                _lowStockExpanded = !_lowStockExpanded;
                              });
                            },
                            child: _LowStockContent(
                              productNamesAndQty: lowStockProducts
                                  .map((product) => _StockRow(
                                        name: product.name,
                                        quantity: product.quantity,
                                      ))
                                  .toList(),
                              scale: scale,
                            ),
                          ),
                        ],
                      ],
                    ),
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

class _ReportsData {
  final double todaySales;
  final List<_DaySalesPoint> weekSales;
  final List<SaleTransaction> recentTransactions;

  const _ReportsData({
    required this.todaySales,
    required this.weekSales,
    required this.recentTransactions,
  });
}

class _DaySalesPoint {
  final DateTime date;
  final double amount;

  const _DaySalesPoint({
    required this.date,
    required this.amount,
  });
}

class _StatusCard extends StatelessWidget {
  final Widget child;
  final double scale;

  const _StatusCard({
    required this.child,
    required this.scale,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(16 * scale),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: const [
          BoxShadow(
            color: Color(0x12000000),
            blurRadius: 8,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: child,
    );
  }
}

class _TodaySalesCard extends StatelessWidget {
  final double amount;
  final String currencyCode;
  final double scale;

  const _TodaySalesCard({
    required this.amount,
    required this.currencyCode,
    required this.scale,
  });

  @override
  Widget build(BuildContext context) {
    return _StatusCard(
      scale: scale,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 36 * scale,
                height: 36 * scale,
                decoration: BoxDecoration(
                  color: const Color(0xFFDDF4E9),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  Icons.trending_up,
                  color: const Color(0xFF10B981),
                  size: 18 * scale,
                ),
              ),
              SizedBox(width: 8 * scale),
              Text(
                'Today\'s Sales',
                style: TextStyle(
                  fontSize: 17 * scale,
                  fontWeight: FontWeight.w700,
                  color: const Color(0xFF2A3A52),
                ),
              ),
            ],
          ),
          SizedBox(height: 14 * scale),
          Text(
            Helpers.formatMoney(amount, currencyCode),
            style: TextStyle(
              fontSize: 42 * scale,
              fontWeight: FontWeight.w800,
              color: const Color(0xFF0B1B3B),
            ),
          ),
        ],
      ),
    );
  }
}

class _WeeklySalesCard extends StatelessWidget {
  final List<_DaySalesPoint> points;
  final String currencyCode;
  final double scale;

  const _WeeklySalesCard({
    required this.points,
    required this.currencyCode,
    required this.scale,
  });

  @override
  Widget build(BuildContext context) {
    final maxAmount = points.fold<double>(0, (maxValue, point) {
      return math.max(maxValue, point.amount);
    });

    return _StatusCard(
      scale: scale,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Last 7 Days',
            style: TextStyle(
              fontSize: 20 * scale,
              fontWeight: FontWeight.w600,
              color: const Color(0xFF0F172A),
            ),
          ),
          SizedBox(height: 12 * scale),
          ...points.map((point) {
            final isTopDay = maxAmount > 0 && point.amount == maxAmount;
            return Padding(
              padding: EdgeInsets.symmetric(vertical: 4 * scale),
              child: _WeekBarRow(
                point: point,
                maxAmount: maxAmount,
                currencyCode: currencyCode,
                showValueLabel: isTopDay,
                scale: scale,
              ),
            );
          }),
        ],
      ),
    );
  }
}

class _WeekBarRow extends StatelessWidget {
  final _DaySalesPoint point;
  final double maxAmount;
  final String currencyCode;
  final bool showValueLabel;
  final double scale;

  const _WeekBarRow({
    required this.point,
    required this.maxAmount,
    required this.currencyCode,
    required this.showValueLabel,
    required this.scale,
  });

  @override
  Widget build(BuildContext context) {
    final shortLabel = DateFormat('EEE').format(point.date);
    var fraction = maxAmount <= 0 ? 0.0 : (point.amount / maxAmount);
    if (point.amount > 0 && fraction < 0.09) {
      fraction = 0.09;
    }

    return Row(
      children: [
        SizedBox(
          width: 40 * scale,
          child: Text(
            shortLabel,
            style: TextStyle(
              fontSize: 14 * scale,
              color: const Color(0xFF64748B),
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
        SizedBox(width: 8 * scale),
        Expanded(
          child: LayoutBuilder(
            builder: (context, constraints) {
              final maxWidth = constraints.maxWidth;
              final barWidth = maxWidth * fraction.clamp(0.0, 1.0);
              return Container(
                height: 32 * scale,
                decoration: BoxDecoration(
                  color: const Color(0xFFE5E7EB),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: Container(
                    width: barWidth,
                    decoration: BoxDecoration(
                      color: const Color(0xFF12B981),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: showValueLabel && point.amount > 0
                        ? Align(
                            alignment: Alignment.centerRight,
                            child: Padding(
                              padding: EdgeInsets.only(right: 10 * scale),
                              child: Text(
                                Helpers.formatMoney(
                                  point.amount,
                                  currencyCode,
                                ),
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 14 * scale,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                          )
                        : null,
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}

class _ExpandableCard extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String title;
  final String badgeValue;
  final bool expanded;
  final bool highlighted;
  final double scale;
  final VoidCallback onTap;
  final Widget child;

  const _ExpandableCard({
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.badgeValue,
    required this.expanded,
    required this.scale,
    required this.onTap,
    required this.child,
    this.highlighted = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color:
              highlighted ? const Color(0xFFF7B267) : const Color(0xFFDDE3EA),
        ),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0F000000),
            blurRadius: 6,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          InkWell(
            borderRadius: BorderRadius.circular(16),
            onTap: onTap,
            child: Padding(
              padding: EdgeInsets.symmetric(
                horizontal: 16 * scale,
                vertical: 14 * scale,
              ),
              child: Row(
                children: [
                  Icon(icon, color: iconColor, size: 22 * scale),
                  SizedBox(width: 8 * scale),
                  Expanded(
                    child: Text(
                      title,
                      style: TextStyle(
                        fontSize: 17 * scale,
                        color: const Color(0xFF0B1B3B),
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  Container(
                    padding: EdgeInsets.symmetric(
                      horizontal: 8 * scale,
                      vertical: 3 * scale,
                    ),
                    decoration: BoxDecoration(
                      color: highlighted
                          ? const Color(0xFFFFEDD5)
                          : const Color(0xFFEFF1F5),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      badgeValue,
                      style: TextStyle(
                        color: highlighted
                            ? const Color(0xFFFF6B00)
                            : const Color(0xFF475569),
                        fontSize: 13 * scale,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  SizedBox(width: 10 * scale),
                  Icon(
                    expanded ? Icons.expand_less : Icons.expand_more,
                    color: highlighted
                        ? const Color(0xFFFF6B00)
                        : const Color(0xFF94A3B8),
                    size: 22 * scale,
                  ),
                ],
              ),
            ),
          ),
          if (expanded) ...[
            const Divider(height: 1, color: Color(0xFFE2E8F0)),
            Padding(
              padding: EdgeInsets.all(12 * scale),
              child: child,
            ),
          ],
        ],
      ),
    );
  }
}

class _RecentTransactionsContent extends StatelessWidget {
  final List<SaleTransaction> transactions;
  final String currencyCode;
  final double scale;

  const _RecentTransactionsContent({
    required this.transactions,
    required this.currencyCode,
    required this.scale,
  });

  @override
  Widget build(BuildContext context) {
    if (transactions.isEmpty) {
      return Text(
        'No transactions yet.',
        style: TextStyle(
          fontSize: 14 * scale,
          color: const Color(0xFF64748B),
          fontWeight: FontWeight.w500,
        ),
      );
    }

    final rows = transactions.take(5).toList();
    return Column(
      children: rows.map((transaction) {
        final date = Helpers.tryParseDateTime(transaction.timestamp);
        return Padding(
          padding: EdgeInsets.symmetric(vertical: 6 * scale),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      date == null
                          ? transaction.timestamp
                          : Helpers.formatDateTime(date),
                      style: TextStyle(
                        fontSize: 13 * scale,
                        color: const Color(0xFF334155),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    SizedBox(height: 2 * scale),
                    Text(
                      transaction.paymentMethod.toUpperCase(),
                      style: TextStyle(
                        fontSize: 12 * scale,
                        color: const Color(0xFF64748B),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
              Text(
                Helpers.formatMoney(transaction.totalAmount, currencyCode),
                style: TextStyle(
                  fontSize: 14 * scale,
                  color: const Color(0xFF0B1B3B),
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }
}

class _StockRow {
  final String name;
  final double quantity;

  const _StockRow({
    required this.name,
    required this.quantity,
  });
}

class _LowStockContent extends StatelessWidget {
  final List<_StockRow> productNamesAndQty;
  final double scale;

  const _LowStockContent({
    required this.productNamesAndQty,
    required this.scale,
  });

  @override
  Widget build(BuildContext context) {
    if (productNamesAndQty.isEmpty) {
      return Text(
        'All products are above the low stock threshold.',
        style: TextStyle(
          fontSize: 14 * scale,
          color: const Color(0xFF64748B),
          fontWeight: FontWeight.w500,
        ),
      );
    }

    return Column(
      children: productNamesAndQty.take(5).map((row) {
        return Padding(
          padding: EdgeInsets.symmetric(vertical: 6 * scale),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  row.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 14 * scale,
                    color: const Color(0xFF0B1B3B),
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              Text(
                row.quantity.toStringAsFixed(
                  row.quantity == row.quantity.roundToDouble() ? 0 : 2,
                ),
                style: TextStyle(
                  fontSize: 13 * scale,
                  color: const Color(0xFFFF6B00),
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }
}
