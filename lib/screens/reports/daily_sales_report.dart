import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/transaction.dart';
import '../../providers/settings_provider.dart';
import '../../providers/transaction_provider.dart';
import '../../utils/helpers.dart';

class DailySalesReport extends StatelessWidget {
  final DateTime date;

  const DailySalesReport({super.key, required this.date});

  @override

  /// Builds the daily sales report view used inside the reports tab.
  Widget build(BuildContext context) {
    final transactionProvider = context.watch<TransactionProvider>();

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: FutureBuilder<List<SaleTransaction>>(
          future: transactionProvider.getTransactionsForDate(date),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }

            final transactions = snapshot.data ?? [];
            final total =
                transactions.fold<double>(0, (sum, tx) => sum + tx.totalAmount);
            final currencyCode = context.read<SettingsProvider>().currencyCode;

            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Daily Sales Report',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                Text('Date: ${Helpers.formatDate(date)}'),
                const SizedBox(height: 8),
                Text(
                    'Total Sales: ${Helpers.formatMoney(total, currencyCode)}'),
                const SizedBox(height: 12),
                if (transactions.isEmpty)
                  const Text('No transactions on this date.')
                else
                  ...transactions.map(
                    (tx) => Card(
                      child: ListTile(
                        leading: const Icon(Icons.receipt_long),
                        title: Text(
                            Helpers.formatMoney(tx.totalAmount, currencyCode)),
                        subtitle: Text(
                          '${Helpers.formatTime(DateTime.parse(tx.timestamp))} • ${tx.paymentMethod.toUpperCase()}',
                        ),
                      ),
                    ),
                  ),
              ],
            );
          },
        ),
      ),
    );
  }
}
