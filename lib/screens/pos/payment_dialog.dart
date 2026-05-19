import 'dart:io';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/qr_code.dart';
import '../../providers/settings_provider.dart';
import '../../utils/helpers.dart';
import '../shared/section_header.dart';

class PaymentSelectionResult {
  final String paymentMethod;
  final double? cashReceived;
  final String? qrLabel;

  const PaymentSelectionResult({
    required this.paymentMethod,
    this.cashReceived,
    this.qrLabel,
  });
}

/// Opens the payment selection flow and returns the chosen payment result.
Future<PaymentSelectionResult?> showPaymentDialog(
  BuildContext context, {
  required double total,
}) {
  return showDialog<PaymentSelectionResult>(
    context: context,
    barrierDismissible: false,
    builder: (_) => PaymentDialog(total: total),
  );
}

class PaymentDialog extends StatefulWidget {
  final double total;

  const PaymentDialog({super.key, required this.total});

  @override
  State<PaymentDialog> createState() => _PaymentDialogState();
}

class _PaymentDialogState extends State<PaymentDialog> {
  String _method = 'cash';
  final _cashController = TextEditingController();
  QrCodeEntry? _selectedQr;

  static const List<double> _presetCashAmounts = [50, 100, 200, 500, 1000];

  @override
  void dispose() {
    _cashController.dispose();
    super.dispose();
  }

  /// Shows the selected QR code at full size and waits for payment approval.
  Future<void> _completeQrPayment(List<QrCodeEntry> qrCodes) async {
    if (_selectedQr == null && qrCodes.isNotEmpty) {
      _selectedQr = qrCodes.first;
    }
    if (_selectedQr == null) return;

    final confirmed = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (context) => Dialog.fullscreen(
        child: SafeArea(
          child: Column(
            children: [
              AppBar(
                title: Text(_selectedQr!.label),
                leading: IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.pop(context, false),
                ),
              ),
              Expanded(
                child: Center(
                  child: InteractiveViewer(
                    minScale: 0.5,
                    maxScale: 4,
                    child: Image.file(File(_selectedQr!.imagePath)),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(16),
                child: FilledButton(
                  onPressed: () => Navigator.pop(context, true),
                  child: const Text('Mark as Paid'),
                ),
              ),
            ],
          ),
        ),
      ),
    );

    if (confirmed == true && mounted) {
      Navigator.of(context).pop(
        PaymentSelectionResult(
            paymentMethod: 'qr', qrLabel: _selectedQr!.label),
      );
    }
  }

  /// Fills the cash received field with one of the preset amounts.
  void _applyCashAmount(double amount) {
    final text = amount.toStringAsFixed(2);
    _cashController.value = TextEditingValue(
      text: text,
      selection: TextSelection.collapsed(offset: text.length),
    );
    setState(() {});
  }

  @override

  /// Builds the payment dialog with cash and QR payment options.
  Widget build(BuildContext context) {
    final settings = context.watch<SettingsProvider>();
    final qrCodes = settings.qrCodes;
    final change = double.tryParse(_cashController.text) != null
        ? double.parse(_cashController.text) - widget.total
        : 0.0;

    return Scaffold(
      backgroundColor: const Color(0xFFF1F3F6),
      body: Column(
        children: [
          SectionHeader(storeName: settings.storeName),
          Expanded(
            child: Container(
              width: double.infinity,
              color: const Color(0xFFF8FAFC),
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          IconButton(
                            onPressed: () => Navigator.pop(context),
                            icon: const Icon(Icons.arrow_back),
                            color: const Color(0xFF0B1B3B),
                          ),
                          const SizedBox(width: 4),
                          const Text(
                            'Payment',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w700,
                              color: Color(0xFF0B1B3B),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      _AmountCard(
                        amountText: Helpers.formatMoney(
                            widget.total, settings.currencyCode),
                      ),
                      const SizedBox(height: 16),
                      const Text(
                        'Select Payment Method',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF344054),
                        ),
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: _PaymentMethodCard(
                              selected: _method == 'cash',
                              icon: Icons.account_balance_wallet_outlined,
                              label: 'Cash',
                              onTap: () => setState(() => _method = 'cash'),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: _PaymentMethodCard(
                              selected: _method == 'qr',
                              icon: Icons.qr_code_2,
                              label: 'QR Payment',
                              onTap: () => setState(() => _method = 'qr'),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      if (_method == 'cash')
                        _CashPaymentSection(
                          controller: _cashController,
                          changeText: change > 0
                              ? Helpers.formatMoney(
                                  change, settings.currencyCode)
                              : '',
                          hasPositiveChange: change > 0,
                          onChanged: () => setState(() {}),
                          presetAmounts: _presetCashAmounts,
                          onPresetTap: _applyCashAmount,
                        )
                      else
                        _QrPaymentSection(
                          qrCodes: qrCodes,
                          selectedQr: _selectedQr,
                          onSelected: (value) =>
                              setState(() => _selectedQr = value),
                          onMarkPaid: () => _completeQrPayment(qrCodes),
                        ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton(
                              onPressed: () => Navigator.pop(context),
                              style: OutlinedButton.styleFrom(
                                padding:
                                    const EdgeInsets.symmetric(vertical: 14),
                                side:
                                    const BorderSide(color: Color(0xFFD0D5DD)),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(14),
                                ),
                              ),
                              child: const Text('Cancel'),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: FilledButton(
                              onPressed: () async {
                                if (_method == 'cash') {
                                  final received = double.tryParse(
                                      _cashController.text.trim());
                                  if (received == null ||
                                      received < widget.total) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(
                                        content: Text(
                                            'Cash received must be at least the total.'),
                                      ),
                                    );
                                    return;
                                  }
                                  Navigator.of(context).pop(
                                    PaymentSelectionResult(
                                      paymentMethod: 'cash',
                                      cashReceived: received,
                                    ),
                                  );
                                } else {
                                  if (qrCodes.isEmpty) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(
                                        content: Text(
                                            'Add a QR code in Settings first.'),
                                      ),
                                    );
                                    return;
                                  }
                                  await _completeQrPayment(qrCodes);
                                }
                              },
                              style: FilledButton.styleFrom(
                                backgroundColor: const Color(0xFF12B981),
                                padding:
                                    const EdgeInsets.symmetric(vertical: 14),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(14),
                                ),
                              ),
                              child: const Text('Continue'),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _AmountCard extends StatelessWidget {
  final String amountText;

  const _AmountCard({required this.amountText});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: const [
          BoxShadow(
            color: Color(0x12000000),
            blurRadius: 14,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Total Amount',
            style: TextStyle(
              fontSize: 14,
              color: Color(0xFF667085),
            ),
          ),
          const SizedBox(height: 10),
          Text(
            amountText,
            style: const TextStyle(
              fontSize: 30,
              fontWeight: FontWeight.w800,
              color: Color(0xFF0B1B3B),
            ),
          ),
        ],
      ),
    );
  }
}

class _PaymentMethodCard extends StatelessWidget {
  final bool selected;
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _PaymentMethodCard({
    required this.selected,
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 18),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color:
                  selected ? const Color(0xFF12B981) : const Color(0xFFE4E7EC),
              width: selected ? 1.4 : 1,
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: const Color(0xFFF2F4F7),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: const Color(0xFF667085)),
              ),
              const SizedBox(height: 14),
              Text(
                label,
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF0B1B3B),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _CashPaymentSection extends StatelessWidget {
  final TextEditingController controller;
  final String changeText;
  final bool hasPositiveChange;
  final VoidCallback onChanged;
  final List<double> presetAmounts;
  final ValueChanged<double> onPresetTap;

  const _CashPaymentSection({
    required this.controller,
    required this.changeText,
    required this.hasPositiveChange,
    required this.onChanged,
    required this.presetAmounts,
    required this.onPresetTap,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TextFormField(
          controller: controller,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          style: const TextStyle(
            color: Color(0xFF0B1B3B),
            fontWeight: FontWeight.w600,
          ),
          cursorColor: const Color(0xFF0B1B3B),
          decoration: InputDecoration(
            labelText: 'Cash received',
            labelStyle: const TextStyle(color: Color(0xFF667085)),
            filled: true,
            fillColor: Colors.white,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: const BorderSide(color: Color(0xFFD0D5DD)),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: const BorderSide(color: Color(0xFFD0D5DD)),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: const BorderSide(color: Color(0xFF12B981)),
            ),
          ),
          onChanged: (_) => onChanged(),
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 10,
          runSpacing: 10,
          children: presetAmounts
              .map(
                (amount) => OutlinedButton(
                  onPressed: () => onPresetTap(amount),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 12),
                    minimumSize: const Size(0, 42),
                    side: const BorderSide(color: Color(0xFFD0D5DD)),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    backgroundColor: Colors.white,
                    foregroundColor: const Color(0xFF344054),
                  ),
                  child: Text(amount.toStringAsFixed(0)),
                ),
              )
              .toList(),
        ),
        const SizedBox(height: 12),
        Text(
          changeText.isEmpty ? 'Change due' : 'Change due: $changeText',
          style: TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w700,
            color: hasPositiveChange
                ? const Color(0xFF12B981)
                : const Color(0xFF667085),
          ),
        ),
      ],
    );
  }
}

class _QrPaymentSection extends StatelessWidget {
  final List<QrCodeEntry> qrCodes;
  final QrCodeEntry? selectedQr;
  final ValueChanged<QrCodeEntry?> onSelected;
  final Future<void> Function() onMarkPaid;

  const _QrPaymentSection({
    required this.qrCodes,
    required this.selectedQr,
    required this.onSelected,
    required this.onMarkPaid,
  });

  @override
  Widget build(BuildContext context) {
    if (qrCodes.isEmpty) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          boxShadow: const [
            BoxShadow(
              color: Color(0x12000000),
              blurRadius: 14,
              offset: Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 180,
              height: 180,
              decoration: BoxDecoration(
                color: const Color(0xFFF2F4F7),
                borderRadius: BorderRadius.circular(18),
              ),
              child: const Icon(
                Icons.qr_code_2,
                size: 110,
                color: Color(0xFF98A2B3),
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'No QR codes available. Add payment QR codes in Settings.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 13,
                color: Color(0xFF667085),
              ),
            ),
          ],
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        DropdownButtonFormField<QrCodeEntry>(
          initialValue: selectedQr ?? qrCodes.first,
          decoration: InputDecoration(
            labelText: 'Select QR code',
            filled: true,
            fillColor: Colors.white,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: const BorderSide(color: Color(0xFFD0D5DD)),
            ),
          ),
          items: qrCodes
              .map(
                (code) => DropdownMenuItem(
                  value: code,
                  child: Text(code.label),
                ),
              )
              .toList(),
          onChanged: onSelected,
        ),
        const SizedBox(height: 12),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: const Color(0xFFE4E7EC)),
          ),
          child: const Text(
              'Open the selected QR code on the customer device to pay.'),
        ),
      ],
    );
  }
}
