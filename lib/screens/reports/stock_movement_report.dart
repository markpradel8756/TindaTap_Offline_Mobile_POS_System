import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../providers/transaction_provider.dart';
import '../../utils/helpers.dart';

class StockMovementReport extends StatelessWidget {
  final int threshold;

  const StockMovementReport({super.key, required this.threshold});

  @override

  /// Builds the stock movement report view used inside the reports tab.
  Widget build(BuildContext context) {
    final transactionProvider = context.watch<TransactionProvider>();

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: FutureBuilder<List<Map<String, dynamic>>>(
          future: transactionProvider.getStockMovementRows(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }

            final rows = snapshot.data ?? [];
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Stock Movement',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 12),
                if (rows.isEmpty)
                  const Text('No inventory items yet.')
                else
                  ...rows.map((row) {
                    final qty = (row['quantity'] as num?)?.toDouble() ?? 0;
                    final totalSold =
                        (row['total_sold'] as num?)?.toDouble() ?? 0;
                    final updatedAt =
                        Helpers.tryParseDateTime(row['updated_at'] as String?);
                    final lastSoldAt = Helpers.tryParseDateTime(
                        row['last_sold_at'] as String?);
                    final note = lastSoldAt == null
                        ? 'No sales yet.'
                        : 'Sold ${totalSold.toStringAsFixed(0)} units total.';
                    final adjustedAfterSale = updatedAt != null &&
                        lastSoldAt != null &&
                        updatedAt.isAfter(lastSoldAt);

                    return Card(
                      color: qty <= threshold ? Colors.red.shade50 : null,
                      child: ListTile(
                        leading: Icon(
                          qty <= threshold
                              ? Icons.warning_amber
                              : Icons.inventory,
                          color: qty <= threshold ? Colors.red : null,
                        ),
                        title: Text((row['name'] ?? '') as String),
                        subtitle: Text(
                          '${row['product_code'] ?? ''} • Qty: ${qty.toStringAsFixed(0)}\n'
                          'Updated: ${updatedAt == null ? '-' : Helpers.formatDateTime(updatedAt)}\n'
                          '$note${adjustedAfterSale ? ' • Adjusted after last sale' : ''}',
                        ),
                        isThreeLine: true,
                      ),
                    );
                  }),
              ],
            );
          },
        ),
      ),
    );
  }
}
