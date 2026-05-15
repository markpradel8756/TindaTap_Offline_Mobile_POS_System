import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/product.dart';
import '../../providers/product_provider.dart';
import '../../providers/settings_provider.dart';
import '../../utils/helpers.dart';
import '../shared/section_header.dart';
import 'add_edit_product_screen.dart';

class InventoryListScreen extends StatefulWidget {
  const InventoryListScreen({super.key});

  @override
  State<InventoryListScreen> createState() => _InventoryListScreenState();
}

class _InventoryListScreenState extends State<InventoryListScreen> {
  final TextEditingController _searchController = TextEditingController();
  List<ProductModel> _visibleProducts = [];
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _refresh(''));
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  /// Reloads the visible product list using the current search query.
  Future<void> _refresh(String query) async {
    setState(() => _loading = true);
    try {
      final provider = context.read<ProductProvider>();
      _visibleProducts = query.trim().isEmpty
          ? provider.products
          : await provider.searchProducts(query);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  /// Opens the product editor and refreshes the inventory after it closes.
  Future<void> _openEditor({ProductModel? product}) async {
    await Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => AddEditProductScreen(product: product)),
    );
    if (mounted) {
      await _refresh(_searchController.text);
    }
  }

  /// Confirms deletion and removes the selected product from storage.
  Future<void> _deleteProduct(ProductModel product) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete product?'),
        content: Text('Delete ${product.name}? This cannot be undone.'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancel')),
          FilledButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Delete')),
        ],
      ),
    );

    if (confirm != true) return;

    try {
      await context.read<ProductProvider>().deleteProduct(product);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Product deleted.')),
        );
      }
      await _refresh(_searchController.text);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString().replaceFirst('Exception: ', ''))),
        );
      }
    }
  }

  @override

  /// Builds the inventory list, search bar, and stock warning states.
  Widget build(BuildContext context) {
    final productProvider = context.watch<ProductProvider>();
    final settings = context.watch<SettingsProvider>();
    final threshold = settings.lowStockThreshold;
    final query = _searchController.text.trim();
    final visibleProducts =
        query.isEmpty ? productProvider.products : _visibleProducts;

    return Scaffold(
      body: Column(
        children: [
          SectionHeader(storeName: settings.storeName),
          // Content area
          Expanded(
            child: Container(
              width: double.infinity,
              color: const Color(0xFFF8FAFC),
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Title row with Add button
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Inventory',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFF0B1B3B),
                          ),
                        ),
                        FilledButton.icon(
                          onPressed: () => _openEditor(),
                          icon: const Icon(Icons.add, size: 16),
                          label: const Text('Add'),
                          style: FilledButton.styleFrom(
                            backgroundColor: const Color(0xFF12B981),
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(
                                horizontal: 12, vertical: 8),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(20),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),

                    // Search field
                    TextField(
                      controller: _searchController,
                      style: const TextStyle(
                        color: Color(0xFF0B1B3B),
                        fontWeight: FontWeight.w600,
                      ),
                      cursorColor: const Color(0xFF0B1B3B),
                      decoration: InputDecoration(
                        hintText: 'Search by name or code...',
                        prefixIcon:
                            const Icon(Icons.search, color: Color(0xFF98A2B3)),
                        filled: true,
                        fillColor: Colors.white,
                        contentPadding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 14),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14),
                          borderSide: BorderSide.none,
                        ),
                      ),
                      onChanged: _refresh,
                    ),
                    const SizedBox(height: 12),

                    // List / Empty state
                    Expanded(
                      child: _loading
                          ? const Center(child: CircularProgressIndicator())
                          : visibleProducts.isEmpty
                              ? const Center(
                                  child: Text(
                                      'No products yet. Add your first item.'),
                                )
                              : RefreshIndicator(
                                  onRefresh: () =>
                                      _refresh(_searchController.text),
                                  child: ListView.separated(
                                    padding: const EdgeInsets.only(top: 8),
                                    itemCount: visibleProducts.length,
                                    separatorBuilder: (_, __) =>
                                        const SizedBox(height: 12),
                                    itemBuilder: (context, index) {
                                      final product = visibleProducts[index];
                                      final lowStock =
                                          product.quantity <= threshold;
                                      return GestureDetector(
                                        onTap: () =>
                                            _openEditor(product: product),
                                        child: Container(
                                          width: double.infinity,
                                          padding: const EdgeInsets.all(14),
                                          decoration: BoxDecoration(
                                            color: Colors.white,
                                            borderRadius:
                                                BorderRadius.circular(14),
                                            boxShadow: const [
                                              BoxShadow(
                                                color: Color(0x12000000),
                                                blurRadius: 8,
                                                offset: Offset(0, 2),
                                              ),
                                            ],
                                          ),
                                          child: Row(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              // Left column: name/code/price
                                              Expanded(
                                                child: Column(
                                                  crossAxisAlignment:
                                                      CrossAxisAlignment.start,
                                                  children: [
                                                    Text(
                                                      product.name,
                                                      style: const TextStyle(
                                                        fontSize: 16,
                                                        fontWeight:
                                                            FontWeight.w700,
                                                        color:
                                                            Color(0xFF0B1B3B),
                                                      ),
                                                    ),
                                                    const SizedBox(height: 6),
                                                    Text(
                                                      product.productCode,
                                                      style: const TextStyle(
                                                        color:
                                                            Color(0xFF667085),
                                                      ),
                                                    ),
                                                    const SizedBox(height: 12),
                                                    Text(
                                                      Helpers.formatMoney(
                                                          product.price,
                                                          settings
                                                              .currencyCode),
                                                      style: const TextStyle(
                                                        color:
                                                            Color(0xFF12B981),
                                                        fontWeight:
                                                            FontWeight.w700,
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              ),

                                              // Right column: stock and actions
                                              Column(
                                                crossAxisAlignment:
                                                    CrossAxisAlignment.end,
                                                children: [
                                                  PopupMenuButton<String>(
                                                    onSelected: (value) {
                                                      if (value == 'edit') {
                                                        _openEditor(
                                                            product: product);
                                                      } else if (value ==
                                                          'delete') {
                                                        _deleteProduct(product);
                                                      }
                                                    },
                                                    itemBuilder: (_) => const [
                                                      PopupMenuItem(
                                                          value: 'edit',
                                                          child: Text('Edit')),
                                                      PopupMenuItem(
                                                          value: 'delete',
                                                          child:
                                                              Text('Delete')),
                                                    ],
                                                    child: const Icon(
                                                      Icons.more_vert,
                                                      color: Color(0xFF98A2B3),
                                                    ),
                                                  ),
                                                  const SizedBox(height: 8),
                                                  Text(
                                                    'Stock',
                                                    style: const TextStyle(
                                                      color: Color(0xFF667085),
                                                    ),
                                                  ),
                                                  const SizedBox(height: 6),
                                                  Row(
                                                    mainAxisSize:
                                                        MainAxisSize.min,
                                                    children: [
                                                      Text(
                                                        product.quantity
                                                            .toStringAsFixed(0),
                                                        style: TextStyle(
                                                          fontWeight: lowStock
                                                              ? FontWeight.w800
                                                              : FontWeight.w600,
                                                          color: lowStock
                                                              ? Colors.red
                                                              : const Color(
                                                                  0xFF0B1B3B),
                                                        ),
                                                      ),
                                                      if (lowStock) ...[
                                                        const SizedBox(
                                                            width: 6),
                                                        Container(
                                                          padding:
                                                              const EdgeInsets
                                                                  .symmetric(
                                                                  horizontal: 6,
                                                                  vertical: 3),
                                                          decoration:
                                                              BoxDecoration(
                                                            color: const Color(
                                                                0xFFFFEDD5),
                                                            borderRadius:
                                                                BorderRadius
                                                                    .circular(
                                                                        8),
                                                          ),
                                                          child: const Text(
                                                            'LOW',
                                                            style: TextStyle(
                                                              color: Color(
                                                                  0xFFFF6B00),
                                                              fontWeight:
                                                                  FontWeight
                                                                      .w700,
                                                              fontSize: 12,
                                                            ),
                                                          ),
                                                        ),
                                                      ]
                                                    ],
                                                  ),
                                                ],
                                              ),
                                            ],
                                          ),
                                        ),
                                      );
                                    },
                                  ),
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
}
