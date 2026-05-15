import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/product.dart';
import '../../providers/product_provider.dart';
import '../../providers/settings_provider.dart';
import '../shared/section_header.dart';

class AddEditProductScreen extends StatefulWidget {
  final ProductModel? product;

  const AddEditProductScreen({super.key, this.product});

  @override
  State<AddEditProductScreen> createState() => _AddEditProductScreenState();
}

class _AddEditProductScreenState extends State<AddEditProductScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _codeController;
  late final TextEditingController _nameController;
  late final TextEditingController _priceController;
  late final TextEditingController _quantityController;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    final product = widget.product;
    _codeController = TextEditingController(text: product?.productCode ?? '');
    _nameController = TextEditingController(text: product?.name ?? '');
    _priceController =
        TextEditingController(text: product?.price.toStringAsFixed(2) ?? '');
    _quantityController = TextEditingController(
      text: product != null ? product.quantity.toStringAsFixed(0) : '',
    );

    _codeController.addListener(_onFormChanged);
    _nameController.addListener(_onFormChanged);
    _priceController.addListener(_onFormChanged);
    _quantityController.addListener(_onFormChanged);
  }

  @override
  void dispose() {
    _codeController.removeListener(_onFormChanged);
    _nameController.removeListener(_onFormChanged);
    _priceController.removeListener(_onFormChanged);
    _quantityController.removeListener(_onFormChanged);
    _codeController.dispose();
    _nameController.dispose();
    _priceController.dispose();
    _quantityController.dispose();
    super.dispose();
  }

  /// Rebuilds the screen whenever a form field changes.
  void _onFormChanged() {
    if (!mounted) return;
    setState(() {});
  }

  /// Validates the form, saves the product, and closes the editor on success.
  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _saving = true);
    try {
      final product = ProductModel(
        id: widget.product?.id,
        productCode: _codeController.text.trim(),
        name: _nameController.text.trim(),
        price: double.parse(_priceController.text.trim()),
        quantity: double.parse(_quantityController.text.trim()),
        createdAt: widget.product?.createdAt,
        updatedAt: widget.product?.updatedAt,
      );

      final provider = context.read<ProductProvider>();
      if (widget.product == null) {
        await provider.addProduct(product);
      } else {
        await provider.updateProduct(product);
      }

      if (mounted) Navigator.pop(context);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString().replaceFirst('Exception: ', ''))),
        );
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  /// Adjusts the layout scale slightly on narrow screens.
  double _scaleForWidth(double width) {
    if (width < 360) return 0.92;
    if (width < 410) return 0.98;
    return 1.0;
  }

  /// Builds the shared text-field decoration used across the form.
  InputDecoration _fieldDecoration(
    String hint,
    double scale, {
    Widget? prefixIcon,
  }) {
    return InputDecoration(
      hintText: hint,
      hintStyle: TextStyle(
        color: const Color(0xFF98A2B3),
        fontSize: 15 * scale,
        fontWeight: FontWeight.w500,
      ),
      prefixIcon: prefixIcon,
      filled: true,
      fillColor: const Color(0xFFF9FAFB),
      contentPadding: EdgeInsets.symmetric(
        horizontal: 16 * scale,
        vertical: 14 * scale,
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: Color(0xFFD7DCE3)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: Color(0xFF12B981), width: 1.4),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: Color(0xFFF04438)),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: Color(0xFFF04438), width: 1.4),
      ),
    );
  }

  /// Wraps a labeled field in a card-style container for consistent spacing.
  Widget _fieldCard({
    required String label,
    required Widget child,
    required double scale,
  }) {
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 14 * scale,
              fontWeight: FontWeight.w700,
              color: const Color(0xFF1E2E4A),
            ),
          ),
          SizedBox(height: 12 * scale),
          child,
        ],
      ),
    );
  }

  /// Returns true when the form contains valid values and can be saved.
  bool get _isReadyToSave {
    final code = _codeController.text.trim();
    final name = _nameController.text.trim();
    final price = double.tryParse(_priceController.text.trim());
    final quantity = double.tryParse(_quantityController.text.trim());

    if (code.isEmpty || name.isEmpty) return false;
    if (!RegExp(r'^[a-zA-Z0-9\-_.]+$').hasMatch(code)) return false;
    if (price == null || price < 0) return false;
    if (quantity == null || quantity < 0) return false;
    return true;
  }

  @override

  /// Builds the add/edit product form and its fixed save button.
  Widget build(BuildContext context) {
    final isEdit = widget.product != null;
    final settings = context.watch<SettingsProvider>();
    final width = MediaQuery.sizeOf(context).width;
    final scale = _scaleForWidth(width);

    return Scaffold(
      body: Column(
        children: [
          SectionHeader(storeName: settings.storeName),
          Expanded(
            child: Container(
              width: double.infinity,
              color: const Color(0xFFF2F4F7),
              child: SafeArea(
                top: false,
                child: Column(
                  children: [
                    Container(
                      width: double.infinity,
                      color: Colors.white,
                      padding: EdgeInsets.symmetric(
                        horizontal: 18 * scale,
                        vertical: 16 * scale,
                      ),
                      child: Row(
                        children: [
                          IconButton(
                            onPressed: _saving
                                ? null
                                : () => Navigator.of(context).maybePop(),
                            icon: const Icon(Icons.arrow_back_ios_new_rounded),
                            color: const Color(0xFF344054),
                            iconSize: 20 * scale,
                            splashRadius: 22,
                            padding: EdgeInsets.zero,
                            constraints: const BoxConstraints(),
                          ),
                          SizedBox(width: 10 * scale),
                          Expanded(
                            child: Text(
                              isEdit ? 'Edit Product' : 'Add New Product',
                              style: TextStyle(
                                fontSize: 18 * scale,
                                fontWeight: FontWeight.w700,
                                color: const Color(0xFF0B1B3B),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    Expanded(
                      child: Form(
                        key: _formKey,
                        child: SingleChildScrollView(
                          padding: EdgeInsets.fromLTRB(
                            16 * scale,
                            18 * scale,
                            16 * scale,
                            24 * scale,
                          ),
                          child: Column(
                            children: [
                              _fieldCard(
                                label: 'Product Name',
                                scale: scale,
                                child: TextFormField(
                                  controller: _nameController,
                                  style: TextStyle(
                                    color: const Color(0xFF0B1B3B),
                                    fontSize: 15 * scale,
                                    fontWeight: FontWeight.w600,
                                  ),
                                  cursorColor: const Color(0xFF0B1B3B),
                                  decoration: _fieldDecoration(
                                    'e.g., Lucky Me Pancit Canton',
                                    scale,
                                  ),
                                  textCapitalization: TextCapitalization.words,
                                  validator: (value) {
                                    if (value == null || value.trim().isEmpty) {
                                      return 'Product name is required.';
                                    }
                                    return null;
                                  },
                                ),
                              ),
                              SizedBox(height: 18 * scale),
                              _fieldCard(
                                label: 'Product Code',
                                scale: scale,
                                child: TextFormField(
                                  controller: _codeController,
                                  style: TextStyle(
                                    color: const Color(0xFF0B1B3B),
                                    fontSize: 15 * scale,
                                    fontWeight: FontWeight.w600,
                                  ),
                                  cursorColor: const Color(0xFF0B1B3B),
                                  decoration:
                                      _fieldDecoration('E.G., LM001', scale),
                                  textCapitalization:
                                      TextCapitalization.characters,
                                  validator: (value) {
                                    if (value == null || value.trim().isEmpty) {
                                      return 'Product code is required.';
                                    }
                                    if (!RegExp(r'^[a-zA-Z0-9\-_.]+$')
                                        .hasMatch(value.trim())) {
                                      return 'Use only letters, numbers, dash, underscore, or dot.';
                                    }
                                    return null;
                                  },
                                ),
                              ),
                              SizedBox(height: 18 * scale),
                              _fieldCard(
                                label: 'Price (${settings.currencySymbol})',
                                scale: scale,
                                child: TextFormField(
                                  controller: _priceController,
                                  style: TextStyle(
                                    color: const Color(0xFF0B1B3B),
                                    fontSize: 15 * scale,
                                    fontWeight: FontWeight.w600,
                                  ),
                                  cursorColor: const Color(0xFF0B1B3B),
                                  keyboardType:
                                      const TextInputType.numberWithOptions(
                                    decimal: true,
                                  ),
                                  decoration: _fieldDecoration(
                                    '0.00',
                                    scale,
                                    prefixIcon: Padding(
                                      padding: EdgeInsets.only(
                                        left: 14 * scale,
                                        right: 8 * scale,
                                      ),
                                      child: Text(
                                        settings.currencySymbol,
                                        style: TextStyle(
                                          fontSize: 15 * scale,
                                          fontWeight: FontWeight.w700,
                                          color: const Color(0xFF475467),
                                        ),
                                      ),
                                    ),
                                  ).copyWith(
                                    prefixIconConstraints: const BoxConstraints(
                                      minWidth: 0,
                                      minHeight: 0,
                                    ),
                                  ),
                                  validator: (value) {
                                    final parsed = double.tryParse(
                                      value?.trim() ?? '',
                                    );
                                    if (parsed == null || parsed < 0) {
                                      return 'Enter a valid price.';
                                    }
                                    return null;
                                  },
                                ),
                              ),
                              SizedBox(height: 18 * scale),
                              _fieldCard(
                                label: 'Stock Quantity',
                                scale: scale,
                                child: TextFormField(
                                  controller: _quantityController,
                                  style: TextStyle(
                                    color: const Color(0xFF0B1B3B),
                                    fontSize: 15 * scale,
                                    fontWeight: FontWeight.w600,
                                  ),
                                  cursorColor: const Color(0xFF0B1B3B),
                                  keyboardType:
                                      const TextInputType.numberWithOptions(
                                    decimal: true,
                                  ),
                                  decoration: _fieldDecoration('0', scale),
                                  validator: (value) {
                                    final parsed = double.tryParse(
                                      value?.trim() ?? '',
                                    );
                                    if (parsed == null || parsed < 0) {
                                      return 'Enter a valid quantity.';
                                    }
                                    return null;
                                  },
                                ),
                              ),
                              SizedBox(height: 100 * scale),
                            ],
                          ),
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
      bottomNavigationBar: SafeArea(
        top: false,
        child: Container(
          color: const Color(0xFFF2F4F7),
          padding: EdgeInsets.fromLTRB(
            16 * scale,
            10 * scale,
            16 * scale,
            12 * scale,
          ),
          child: SizedBox(
            width: double.infinity,
            height: 56 * scale,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 180),
              curve: Curves.easeOut,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(28),
                boxShadow: _isReadyToSave && !_saving
                    ? const [
                        BoxShadow(
                          color: Color(0x6612B981),
                          blurRadius: 18,
                          spreadRadius: 2,
                          offset: Offset(0, 6),
                        ),
                      ]
                    : const [],
              ),
              child: FilledButton.icon(
                onPressed: (!_isReadyToSave || _saving) ? null : _save,
                icon: _saving
                    ? SizedBox(
                        height: 18 * scale,
                        width: 18 * scale,
                        child: const CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : Icon(
                        Icons.save_rounded,
                        size: 20 * scale,
                        color: Colors.white,
                      ),
                label: Text(
                  _saving ? 'Saving...' : 'Save Product',
                  style: TextStyle(
                    fontSize: 16 * scale,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
                style: FilledButton.styleFrom(
                  backgroundColor: const Color(0xFF12B981),
                  disabledBackgroundColor: const Color(0xFF8BD8C1),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(28),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
