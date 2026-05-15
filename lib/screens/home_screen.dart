import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/product_provider.dart';
import '../providers/settings_provider.dart';
import '../providers/transaction_provider.dart';
import '../utils/helpers.dart';
import 'inventory/inventory_list_screen.dart';
import 'pos/pos_screen.dart';
import 'reports/reports_screen.dart';
import 'settings/settings_screen.dart';
import 'shared/section_header.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _currentIndex = 0;

  late final List<Widget> _screens;

  @override
  void initState() {
    super.initState();
    _screens = [
      _HomeSectionPlaceholder(
        onNewSaleTap: () => _goToTab(1),
        onAddProductTap: () => _goToTab(2),
        onViewInventoryTap: () => _goToTab(2),
      ),
      const PosScreen(),
      const InventoryListScreen(),
      const ReportsScreen(),
      const SettingsScreen(),
    ];
  }

  /// Switches to the requested bottom-navigation tab when needed.
  void _goToTab(int index) {
    if (!mounted || _currentIndex == index) return;
    setState(() => _currentIndex = index);
  }

  @override

  /// Builds the main shell with tab navigation and the current section.
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(index: _currentIndex, children: _screens),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _currentIndex,
        onDestinationSelected: (index) => setState(() => _currentIndex = index),
        destinations: const [
          NavigationDestination(icon: Icon(Icons.home_outlined), label: 'Home'),
          NavigationDestination(
              icon: Icon(Icons.point_of_sale), label: 'Sales'),
          NavigationDestination(
              icon: Icon(Icons.inventory_2), label: 'Inventory'),
          NavigationDestination(icon: Icon(Icons.bar_chart), label: 'Reports'),
          NavigationDestination(icon: Icon(Icons.settings), label: 'Settings'),
        ],
      ),
    );
  }
}

class _HomeSectionPlaceholder extends StatelessWidget {
  final VoidCallback onNewSaleTap;
  final VoidCallback onAddProductTap;
  final VoidCallback onViewInventoryTap;

  const _HomeSectionPlaceholder({
    required this.onNewSaleTap,
    required this.onAddProductTap,
    required this.onViewInventoryTap,
  });

  /// Calculates a compact scale factor for very small screens.
  double _scale(double width) {
    if (width < 340) return 0.78;
    if (width < 380) return 0.88;
    if (width < 420) return 0.95;
    return 1.0;
  }

  @override

  /// Builds the home dashboard summary and quick actions.
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    final s = _scale(width);
    final settings = context.watch<SettingsProvider>();
    final productProvider = context.watch<ProductProvider>();
    final transactionProvider = context.watch<TransactionProvider>();
    final storeName =
        settings.storeName.trim().isEmpty ? 'Store' : settings.storeName.trim();
    final lowStockCount = productProvider.products
        .where((product) => product.quantity <= settings.lowStockThreshold)
        .length;

    return Scaffold(
      body: Column(
        children: [
          SectionHeader(storeName: storeName),
          Expanded(
            child: Container(
              width: double.infinity,
              color: const Color(0xFFF2F4F7),
              child: SingleChildScrollView(
                padding: EdgeInsets.fromLTRB(14 * s, 12 * s, 14 * s, 14 * s),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _cardContainer(
                      scale: s,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              _IconBadge(
                                icon: Icons.trending_up,
                                iconColor: const Color(0xFF10B981),
                                scale: s,
                              ),
                              SizedBox(width: 7 * s),
                              Text(
                                'Today\'s Sales',
                                style: TextStyle(
                                  fontSize: 17 * s,
                                  fontWeight: FontWeight.w700,
                                  color: const Color(0xFF2A3A52),
                                ),
                              ),
                            ],
                          ),
                          SizedBox(height: 14 * s),
                          FutureBuilder<double>(
                            future: transactionProvider
                                .getDailyTotal(DateTime.now()),
                            builder: (context, snapshot) {
                              final total = snapshot.data ?? 0;
                              return Text(
                                Helpers.formatMoney(
                                    total, settings.currencyCode),
                                style: TextStyle(
                                  fontSize: 28 * s,
                                  fontWeight: FontWeight.w800,
                                  color: const Color(0xFF0B1B3B),
                                ),
                              );
                            },
                          ),
                        ],
                      ),
                    ),
                    SizedBox(height: 12 * s),
                    Text(
                      'Quick Actions',
                      style: TextStyle(
                        fontSize: 17 * s,
                        fontWeight: FontWeight.w700,
                        color: const Color(0xFF1E2E4A),
                      ),
                    ),
                    SizedBox(height: 10 * s),
                    Row(
                      children: [
                        Expanded(
                          child: _ActionPlaceholderButton(
                            title: 'New Sale',
                            icon: Icons.shopping_bag_outlined,
                            filled: true,
                            onTap: onNewSaleTap,
                            scale: s,
                          ),
                        ),
                        SizedBox(width: 8 * s),
                        Expanded(
                          child: _ActionPlaceholderButton(
                            title: 'Add Product',
                            icon: Icons.add,
                            filled: false,
                            onTap: onAddProductTap,
                            scale: s,
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 8 * s),
                    _ActionPlaceholderButton(
                      title: 'View Inventory',
                      icon: Icons.inventory_2_outlined,
                      filled: false,
                      stretch: true,
                      onTap: onViewInventoryTap,
                      scale: s,
                    ),
                    SizedBox(height: 12 * s),
                    Container(
                      width: double.infinity,
                      padding:
                          EdgeInsets.fromLTRB(12 * s, 12 * s, 12 * s, 12 * s),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: const Color(0xFFF7B267)),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.error_outline,
                            color: const Color(0xFFFF6B00),
                            size: 20 * s,
                          ),
                          SizedBox(width: 8 * s),
                          Expanded(
                            child: Text(
                              'Low Stock Alert',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontSize: 16 * s,
                                fontWeight: FontWeight.w700,
                                color: const Color(0xFF0B1B3B),
                              ),
                            ),
                          ),
                          Container(
                            padding: EdgeInsets.symmetric(
                              horizontal: 8 * s,
                              vertical: 4 * s,
                            ),
                            decoration: BoxDecoration(
                              color: const Color(0xFFFFEDD5),
                              borderRadius: BorderRadius.circular(14),
                            ),
                            child: Text(
                              '$lowStockCount items',
                              style: TextStyle(
                                fontSize: 11 * s,
                                color: const Color(0xFFFF6B00),
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Wraps dashboard content in a reusable white card with subtle elevation.
  static Widget _cardContainer({required Widget child, required double scale}) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(12 * scale),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: const [
          BoxShadow(
            color: Color(0x14000000),
            blurRadius: 6,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: child,
    );
  }
}

class _IconBadge extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final double scale;

  const _IconBadge({
    required this.icon,
    required this.iconColor,
    required this.scale,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 30 * scale,
      height: 30 * scale,
      decoration: BoxDecoration(
        color: const Color(0xFFDDF4E9),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Icon(icon, color: iconColor, size: 15 * scale),
    );
  }
}

class _ActionPlaceholderButton extends StatelessWidget {
  final String title;
  final IconData icon;
  final bool filled;
  final bool stretch;
  final VoidCallback onTap;
  final double scale;

  const _ActionPlaceholderButton({
    required this.title,
    required this.icon,
    required this.filled,
    required this.onTap,
    required this.scale,
    this.stretch = false,
  });

  @override
  Widget build(BuildContext context) {
    final content = Container(
      width: stretch ? double.infinity : null,
      padding:
          EdgeInsets.symmetric(vertical: 11 * scale, horizontal: 10 * scale),
      decoration: BoxDecoration(
        color: filled ? const Color(0xFF12B981) : Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFF12B981)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x14000000),
            blurRadius: 4,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: 21 * scale,
            color: filled ? Colors.white : const Color(0xFF12B981),
          ),
          SizedBox(height: 6 * scale),
          Text(
            title,
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 14 * scale,
              fontWeight: FontWeight.w700,
              color: filled ? Colors.white : const Color(0xFF12B981),
            ),
          ),
        ],
      ),
    );

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: content,
    );
  }
}
