import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';

import '../../models/qr_code.dart';
import '../../providers/settings_provider.dart';

class AddQrDialog extends StatefulWidget {
  final QrCodeEntry? existing;

  const AddQrDialog({super.key, this.existing});

  @override
  State<AddQrDialog> createState() => _AddQrDialogState();
}

class _AddQrDialogState extends State<AddQrDialog> {
  final _providerController = TextEditingController();
  final _accountController = TextEditingController();
  XFile? _picked;
  bool _saving = false;
  late final bool _isEdit;
  String? _existingImagePath;

  @override
  void dispose() {
    _providerController.dispose();
    _accountController.dispose();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    _isEdit = widget.existing != null;
    if (_isEdit) {
      // Try to split existing label into provider and account by ' - '
      final parts = widget.existing!.label.split(' - ');
      _providerController.text =
          parts.isNotEmpty ? parts.first : widget.existing!.label;
      _accountController.text =
          parts.length > 1 ? parts.sublist(1).join(' - ') : '';
      _existingImagePath = widget.existing!.imagePath;
    }
  }

  /// Opens the gallery picker unless the dialog is in edit mode.
  Future<void> _pickImage() async {
    if (_isEdit) {
      return; // disable changing image in edit mode to avoid complexity
    }
    final file = await ImagePicker().pickImage(source: ImageSource.gallery);
    if (file == null) return;
    setState(() => _picked = file);
  }

  /// Validates that the form has the required values and is not saving.
  bool get _isValid {
    return _providerController.text.trim().isNotEmpty &&
        _accountController.text.trim().isNotEmpty &&
        _picked != null &&
        !_saving;
  }

  /// Saves a new QR code entry or updates an existing label.
  Future<void> _save() async {
    if (!_isValid) return;
    setState(() => _saving = true);
    final label =
        '${_providerController.text.trim()} - ${_accountController.text.trim()}';

    try {
      if (_isEdit) {
        // update only label for existing entry
        final existing = widget.existing!;
        await context
            .read<SettingsProvider>()
            .updateQrCodeLabel(existing, label);
      } else {
        await context.read<SettingsProvider>().addQrCode(
              label: label,
              imageFile: _picked!,
            );
      }
      if (!mounted) return;
      Navigator.of(context).pop(true);
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

  @override
  Widget build(BuildContext context) {
    return Dialog(
      insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 40),
      child: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(18),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  const Expanded(
                    child: Text(
                      'Add QR Code',
                      style:
                          TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.of(context).pop(false),
                    icon: const Icon(Icons.close),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              const Text('Payment Provider',
                  style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
              const SizedBox(height: 8),
              TextField(
                controller: _providerController,
                textInputAction: TextInputAction.next,
                decoration: const InputDecoration(
                  hintText: 'e.g., GCash, Maya, PayMaya',
                  border: OutlineInputBorder(),
                ),
                onChanged: (_) => setState(() {}),
              ),
              const SizedBox(height: 12),
              const Text('Account Name',
                  style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
              const SizedBox(height: 8),
              TextField(
                controller: _accountController,
                textInputAction: TextInputAction.done,
                decoration: const InputDecoration(
                  hintText: 'e.g., Juan Dela Cruz',
                  border: OutlineInputBorder(),
                ),
                onChanged: (_) => setState(() {}),
              ),
              const SizedBox(height: 12),
              const Text('QR Code Image',
                  style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
              const SizedBox(height: 8),
              GestureDetector(
                onTap: _pickImage,
                child: _isEdit
                    ? ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: Image.file(
                          File(_existingImagePath!),
                          height: 140,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => Container(
                            height: 140,
                            decoration: BoxDecoration(
                              border:
                                  Border.all(color: const Color(0xFFD0D7E0)),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            alignment: Alignment.center,
                            child: const Text('QR image not available'),
                          ),
                        ),
                      )
                    : _picked == null
                        ? Container(
                            height: 140,
                            decoration: BoxDecoration(
                              border:
                                  Border.all(color: const Color(0xFFD0D7E0)),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Center(
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: const [
                                  Icon(Icons.upload_file,
                                      size: 30, color: Color(0xFF64748B)),
                                  SizedBox(height: 8),
                                  Text('Upload QR Code',
                                      style: TextStyle(
                                          fontWeight: FontWeight.w600)),
                                  SizedBox(height: 4),
                                  Text('PNG, JPG up to 5MB',
                                      style: TextStyle(fontSize: 12)),
                                ],
                              ),
                            ),
                          )
                        : ClipRRect(
                            borderRadius: BorderRadius.circular(12),
                            child: Image.file(
                              File(_picked!.path),
                              height: 140,
                              fit: BoxFit.cover,
                            ),
                          ),
              ),
              const SizedBox(height: 16),
              FilledButton(
                onPressed: _isValid ? _save : null,
                style: FilledButton.styleFrom(
                  backgroundColor: _isValid
                      ? const Color(0xFF12B981)
                      : const Color(0xFFD7DCE4),
                  foregroundColor:
                      _isValid ? Colors.white : const Color(0xFF8E98A8),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                ),
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  child: _saving
                      ? const SizedBox(
                          height: 16,
                          width: 16,
                          child: CircularProgressIndicator(strokeWidth: 2))
                      : Text(_isEdit ? 'Update QR' : 'Add QR Code'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
