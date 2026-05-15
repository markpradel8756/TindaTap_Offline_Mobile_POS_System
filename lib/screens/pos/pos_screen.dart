import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../providers/cart_provider.dart';
import '../../providers/product_provider.dart';
import '../../providers/settings_provider.dart';
import '../../providers/transaction_provider.dart';
import '../../models/product.dart';
import '../../utils/helpers.dart';
import '../shared/section_header.dart';
import 'payment_dialog.dart';

class PosScreen extends StatefulWidget {
  const PosScreen({super.key});

  @override
  State<PosScreen> createState() => _PosScreenState();
}

class _PosScreenState extends State<PosScreen> {
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ProductProvider>().loadProducts();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  /// Searches the product list and adds the best match to the cart.
  Future<void> _searchAndAddFirstMatch() async {
    final query = _searchController.text.trim();
    if (query.isEmpty) return;

    final provider = context.read<ProductProvider>();
    final results = _filterProducts(provider.products, query);
    if (!mounted) return;

    if (results.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No matching product found.')),
      );
      return;
    }

    context.read<CartProvider>().addProduct(results.first);
    _searchController.clear();
  }

  /// Filters and ranks products locally so search results feel responsive.
  List<ProductModel> _filterProducts(
      List<ProductModel> products, String query) {
    final needle = query.trim().toLowerCase();
    if (needle.isEmpty) return products;

    final matched = <ProductModel>[];
    for (final product in products) {
      final name = product.name.toLowerCase();
      final code = product.productCode.toLowerCase();
      final contains = name.contains(needle) || code.contains(needle);
      if (contains) matched.add(product);
    }

    matched.sort((a, b) {
      final aName = a.name.toLowerCase();
      final bName = b.name.toLowerCase();
      final aCode = a.productCode.toLowerCase();
      final bCode = b.productCode.toLowerCase();

      final aStarts = aName.startsWith(needle) || aCode.startsWith(needle);
      final bStarts = bName.startsWith(needle) || bCode.startsWith(needle);
      if (aStarts != bStarts) return aStarts ? -1 : 1;

      return aName.compareTo(bName);
    });
    return matched;
  }

  /// Opens payment selection, finalizes the transaction, and clears the cart.
  Future<void> _checkout() async {
    final cart = context.read<CartProvider>();
    final settings = context.read<SettingsProvider>();
    final transactionProvider = context.read<TransactionProvider>();

    if (cart.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Cart is empty.')),
      );
      return;
    }

    final payment = await showPaymentDialog(context, total: cart.total);
    if (payment == null) return;

    try {
      await transactionProvider.completeSale(
        cartItems: cart.items,
        paymentMethod: payment.paymentMethod,
        cashReceived: payment.cashReceived,
        qrLabel: payment.qrLabel,
        storeName: settings.storeName,
      );
      await context.read<ProductProvider>().loadProducts();
      cart.clear();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Transaction saved successfully.')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString().replaceFirst('Exception: ', ''))),
        );
      }
    }
  }

  @override

  /// Builds the POS screen with search, cart, and checkout controls.
  Widget build(BuildContext context) {
    final cart = context.watch<CartProvider>();
    final settings = context.watch<SettingsProvider>();
    final productProvider = context.watch<ProductProvider>();
    final screenWidth = MediaQuery.of(context).size.width;
    final scale = screenWidth < 360 ? 0.90 : 1.0;
    final query = _searchController.text.trim();
    final filteredProducts = _filterProducts(productProvider.products, query);

    return Scaffold(
      backgroundColor: const Color(0xFFF1F3F6),
      body: Column(
        children: [
          SectionHeader(storeName: settings.storeName),
          Padding(
            padding: EdgeInsets.fromLTRB(
                16 * scale, 10 * scale, 16 * scale, 10 * scale),
            child: Column(
              children: [
                Row(
                  children: [
                    IconButton(
                      visualDensity: VisualDensity.compact,
                      onPressed: () {
                        if (Navigator.of(context).canPop()) {
                          Navigator.of(context).maybePop();
                        }
                      },
                      icon: const Icon(Icons.arrow_back),
                    ),
                    SizedBox(width: 4 * scale),
                    Text(
                      'New Sale',
                      style: TextStyle(
                        fontSize: 18 * scale,
                        fontWeight: FontWeight.w700,
                        color: const Color(0xFF0B1B3B),
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 6 * scale),
                TextField(
                  controller: _searchController,
                  onChanged: (_) => setState(() {}),
                  textInputAction: TextInputAction.search,
                  onSubmitted: (_) => _searchAndAddFirstMatch(),
                  style: const TextStyle(
                    color: Color(0xFF0B1B3B),
                    fontWeight: FontWeight.w600,
                  ),
                  cursorColor: const Color(0xFF0B1B3B),
                  decoration: InputDecoration(
                    hintText: 'Search by product name or code...',
                    hintStyle: const TextStyle(
                      color: Color(0xFF667085),
                      fontWeight: FontWeight.w500,
                    ),
                    prefixIcon:
                        const Icon(Icons.search, color: Color(0xFF98A2B3)),
                    filled: true,
                    fillColor: const Color(0xFFF7F8FA),
                    contentPadding: EdgeInsets.symmetric(
                        horizontal: 12 * scale, vertical: 10 * scale),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: const BorderSide(color: Color(0xFFD0D5DD)),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: const BorderSide(color: Color(0xFFD0D5DD)),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          Expanded(
            child: ListView(
              padding: EdgeInsets.fromLTRB(
                  16 * scale, 12 * scale, 16 * scale, 12 * scale),
              children: [
                Text(
                  query.isEmpty ? 'Cart' : 'Results',
                  style: TextStyle(
                    fontSize: 15 * scale,
                    fontWeight: FontWeight.w700,
                    color: const Color(0xFF344054),
                  ),
                ),
                SizedBox(height: 8 * scale),
                if (query.isNotEmpty) ...[
                  if (filteredProducts.isEmpty)
                    Container(
                      width: double.infinity,
                      padding: EdgeInsets.all(14 * scale),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Text(
                        'No matching products found.',
                        style: TextStyle(fontSize: 13 * scale),
                      ),
                    )
                  else
                    ...filteredProducts.map(
                      (product) => Padding(
                        padding: EdgeInsets.only(bottom: 8 * scale),
                        child: _SearchResultTile(
                          product: product,
                          scale: scale,
                          currencyCode: settings.currencyCode,
                          onTap: () =>
                              context.read<CartProvider>().addProduct(product),
                        ),
                      ),
                    ),
                  SizedBox(height: 12 * scale),
                  Text(
                    'Cart',
                    style: TextStyle(
                      fontSize: 15 * scale,
                      fontWeight: FontWeight.w700,
                      color: const Color(0xFF344054),
                    ),
                  ),
                  SizedBox(height: 8 * scale),
                ],
                if (cart.items.isEmpty)
                  Container(
                    width: double.infinity,
                    padding: EdgeInsets.all(14 * scale),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(14),
                      boxShadow: const [
                        BoxShadow(
                          color: Color(0x12000000),
                          blurRadius: 8,
                          offset: Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Text(
                      'No items added yet. Search and tap a product to add it.',
                      style: TextStyle(fontSize: 13 * scale),
                    ),
                  )
                else
                  ...cart.items.map(
                    (item) => Padding(
                      padding: EdgeInsets.only(bottom: 8 * scale),
                      child: _CartItemTile(
                        item: item,
                        scale: scale,
                        currencyCode: settings.currencyCode,
                        onIncrease: () => context
                            .read<CartProvider>()
                            .increment(item.productCode),
                        onDecrease: () => context
                            .read<CartProvider>()
                            .decrement(item.productCode),
                        onDelete: () => context
                            .read<CartProvider>()
                            .remove(item.productCode),
                      ),
                    ),
                  ),
                SizedBox(height: 72 * scale),
              ],
            ),
          ),
          Container(
            width: double.infinity,
            color: Colors.white,
            padding: EdgeInsets.fromLTRB(
                20 * scale, 12 * scale, 20 * scale, 12 * scale),
            child: SafeArea(
              top: false,
              child: Column(
                children: [
                  Row(
                    children: [
                      Text(
                        'Total Amount',
                        style: TextStyle(
                          fontSize: 13 * scale,
                          color: const Color(0xFF344054),
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const Spacer(),
                      Text(
                        Helpers.formatMoney(cart.total, settings.currencyCode),
                        style: TextStyle(
                          fontSize: 22 * scale,
                          color: const Color(0xFF0B1B3B),
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 12 * scale),
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton(
                      onPressed: cart.isEmpty ? null : _checkout,
                      style: FilledButton.styleFrom(
                        backgroundColor: const Color(0xFF10B981),
                        disabledBackgroundColor: const Color(0xFFB8DCCE),
                        padding: EdgeInsets.symmetric(vertical: 12 * scale),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                      child: Text(
                        'Proceed to Payment',
                        style: TextStyle(
                          fontSize: 16 * scale,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SearchResultTile extends StatelessWidget {
  final ProductModel product;
  final double scale;
  final String currencyCode;
  final VoidCallback onTap;

  const _SearchResultTile({
    required this.product,
    required this.scale,
    required this.currencyCode,
    required this.onTap,
  });

  @override

  /// Builds one product tile used inside the live search results list.
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: onTap,
        child: Padding(
          padding: EdgeInsets.all(12 * scale),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      product.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 15 * scale,
                        fontWeight: FontWeight.w700,
                        color: const Color(0xFF0B1B3B),
                      ),
                    ),
                    SizedBox(height: 2 * scale),
                    Text(
                      product.productCode,
                      style: TextStyle(
                        fontSize: 12 * scale,
                        color: const Color(0xFF667085),
                      ),
                    ),
                  ],
                ),
              ),
              Text(
                Helpers.formatMoney(product.price, currencyCode),
                style: TextStyle(
                  fontSize: 14 * scale,
                  fontWeight: FontWeight.w700,
                  color: const Color(0xFF12B981),
                ),
              ),
              SizedBox(width: 8 * scale),
              const Icon(Icons.add_circle_outline, color: Color(0xFF12B981)),
            ],
          ),
        ),
      ),
    );
  }
}

class _CartItemTile extends StatelessWidget {
  final CartItem item;
  final double scale;
  final String currencyCode;
  final VoidCallback onIncrease;
  final VoidCallback onDecrease;
  final VoidCallback onDelete;

  const _CartItemTile({
    required this.item,
    required this.scale,
    required this.currencyCode,
    required this.onIncrease,
    required this.onDecrease,
    required this.onDelete,
  });

  @override

  /// Builds one cart line item with quantity controls and pricing details.
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(14 * scale),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: const [
          BoxShadow(
            color: Color(0x12000000),
            blurRadius: 8,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  item.productName,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 15 * scale,
                    fontWeight: FontWeight.w700,
                    color: const Color(0xFF0B1B3B),
                  ),
                ),
              ),
              IconButton(
                visualDensity: VisualDensity.compact,
                onPressed: onDelete,
                icon:
                    const Icon(Icons.delete_outline, color: Color(0xFFFF4D4F)),
              ),
            ],
          ),
          Text(
            item.productCode,
            style: TextStyle(
              fontSize: 12 * scale,
              color: const Color(0xFF667085),
            ),
          ),
          SizedBox(height: 4 * scale),
          Text(
            Helpers.formatMoney(item.unitPrice, currencyCode),
            style: TextStyle(
              fontSize: 13 * scale,
              color: const Color(0xFF12B981),
              fontWeight: FontWeight.w700,
            ),
          ),
          SizedBox(height: 8 * scale),
          Row(
            children: [
              Container(
                decoration: BoxDecoration(
                  color: const Color(0xFFF2F4F7),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      visualDensity: VisualDensity.compact,
                      onPressed: onDecrease,
                      icon: const Icon(Icons.remove, color: Color(0xFF344054)),
                    ),
                    SizedBox(
                      width: 24 * scale,
                      child: Text(
                        item.quantity.toStringAsFixed(0),
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 15 * scale,
                          fontWeight: FontWeight.w700,
                          color: const Color(0xFF0B1B3B),
                        ),
                      ),
                    ),
                    IconButton(
                      visualDensity: VisualDensity.compact,
                      onPressed: onIncrease,
                      icon: const Icon(Icons.add, color: Color(0xFF344054)),
                    ),
                  ],
                ),
              ),
              const Spacer(),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    'Subtotal',
                    style: TextStyle(
                      fontSize: 12 * scale,
                      color: const Color(0xFF667085),
                    ),
                  ),
                  SizedBox(height: 2 * scale),
                  Text(
                    Helpers.formatMoney(item.subtotal, currencyCode),
                    style: TextStyle(
                      fontSize: 15 * scale,
                      fontWeight: FontWeight.w800,
                      color: const Color(0xFF0B1B3B),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }
}
