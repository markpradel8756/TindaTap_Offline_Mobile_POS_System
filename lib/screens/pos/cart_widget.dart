import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../providers/cart_provider.dart';
import '../../providers/settings_provider.dart';
import '../../utils/helpers.dart';

class CartWidget extends StatelessWidget {
  final VoidCallback onCheckout;

  const CartWidget({super.key, required this.onCheckout});

  @override

  /// Builds the cart panel that summarizes items during a sale.
  Widget build(BuildContext context) {
    final cart = context.watch<CartProvider>();
    final settings = context.watch<SettingsProvider>();

    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: Colors.black12)),
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Cart (${cart.items.length})',
                      style: const TextStyle(fontWeight: FontWeight.bold)),
                  Text(
                    Helpers.formatMoney(cart.total, settings.currencyCode),
                    style: const TextStyle(
                        fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              if (cart.items.isEmpty)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 16),
                  child: Text('Tap a product above to add it to the cart.'),
                )
              else
                ...cart.items.map(
                  (item) => Card(
                    child: Padding(
                      padding: const EdgeInsets.all(10),
                      child: Row(
                        children: [
                          Expanded(
                            flex: 3,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(item.productName,
                                    style: const TextStyle(
                                        fontWeight: FontWeight.w600)),
                                Text(item.productCode),
                                Text(
                                  Helpers.formatMoney(
                                      item.unitPrice, settings.currencyCode),
                                ),
                              ],
                            ),
                          ),
                          Row(
                            children: [
                              IconButton(
                                onPressed: () => context
                                    .read<CartProvider>()
                                    .decrement(item.productCode),
                                icon: const Icon(Icons.remove_circle_outline),
                              ),
                              SizedBox(
                                width: 56,
                                child: TextFormField(
                                  initialValue:
                                      item.quantity.toStringAsFixed(0),
                                  keyboardType:
                                      const TextInputType.numberWithOptions(
                                          decimal: true),
                                  textAlign: TextAlign.center,
                                  style: const TextStyle(
                                    color: Color(0xFF0B1B3B),
                                    fontWeight: FontWeight.w600,
                                  ),
                                  cursorColor: const Color(0xFF0B1B3B),
                                  decoration:
                                      const InputDecoration(isDense: true),
                                  onFieldSubmitted: (value) {
                                    final qty = double.tryParse(value) ?? 1;
                                    context.read<CartProvider>().updateQuantity(
                                          item.productCode,
                                          qty <= 0 ? 1 : qty,
                                        );
                                  },
                                ),
                              ),
                              IconButton(
                                onPressed: () => context
                                    .read<CartProvider>()
                                    .increment(item.productCode),
                                icon: const Icon(Icons.add_circle_outline),
                              ),
                              IconButton(
                                onPressed: () => context
                                    .read<CartProvider>()
                                    .remove(item.productCode),
                                icon: const Icon(Icons.delete_outline),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              const SizedBox(height: 8),
              FilledButton.icon(
                onPressed: cart.isEmpty ? null : onCheckout,
                icon: const Icon(Icons.payments_outlined),
                label: const Padding(
                  padding: EdgeInsets.symmetric(vertical: 12),
                  child: Text('Complete Sale'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
