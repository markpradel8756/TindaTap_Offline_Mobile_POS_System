import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';

import '../../providers/settings_provider.dart';

class QrManagementScreen extends StatefulWidget {
  const QrManagementScreen({super.key});

  @override
  State<QrManagementScreen> createState() => _QrManagementScreenState();
}

class _QrManagementScreenState extends State<QrManagementScreen> {
  /// Lets the user pick an image, enter a label, and save a QR code entry.
  Future<void> _addQrCode() async {
    final imagePicker = ImagePicker();
    final picked = await imagePicker.pickImage(source: ImageSource.gallery);
    if (picked == null) return;

    final labelController = TextEditingController();
    final label = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('QR Code Label'),
        content: TextField(
          controller: labelController,
          style: const TextStyle(
            color: Color(0xFF0B1B3B),
            fontWeight: FontWeight.w600,
          ),
          cursorColor: const Color(0xFF0B1B3B),
          decoration: const InputDecoration(
            labelText: 'Example: GCash Personal',
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel')),
          FilledButton(
              onPressed: () => Navigator.pop(context, labelController.text),
              child: const Text('Save')),
        ],
      ),
    );
    labelController.dispose();
    if (label == null || label.trim().isEmpty) return;

    try {
      await context
          .read<SettingsProvider>()
          .addQrCode(label: label, imageFile: picked);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('QR code saved.')),
        );
      }
      setState(() {});
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString().replaceFirst('Exception: ', ''))),
        );
      }
    }
  }

  @override

  /// Builds the QR management screen showing saved codes and add/delete tools.
  Widget build(BuildContext context) {
    final settings = context.watch<SettingsProvider>();

    return Scaffold(
      appBar: AppBar(title: const Text('QR Code Management')),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _addQrCode,
        icon: const Icon(Icons.add),
        label: const Text('Add QR Code'),
      ),
      body: settings.qrCodes.isEmpty
          ? const Center(child: Text('No QR codes yet.'))
          : ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: settings.qrCodes.length,
              separatorBuilder: (_, __) => const SizedBox(height: 8),
              itemBuilder: (context, index) {
                final code = settings.qrCodes[index];
                return Dismissible(
                  key: ValueKey(code.id ?? code.imagePath),
                  background: Container(
                    color: Colors.red,
                    alignment: Alignment.centerRight,
                    padding: const EdgeInsets.only(right: 20),
                    child: const Icon(Icons.delete, color: Colors.white),
                  ),
                  direction: DismissDirection.endToStart,
                  confirmDismiss: (_) async {
                    return await showDialog<bool>(
                          context: context,
                          builder: (context) => AlertDialog(
                            title: const Text('Delete QR code?'),
                            content: Text('Delete ${code.label}?'),
                            actions: [
                              TextButton(
                                onPressed: () => Navigator.pop(context, false),
                                child: const Text('Cancel'),
                              ),
                              FilledButton(
                                onPressed: () => Navigator.pop(context, true),
                                child: const Text('Delete'),
                              ),
                            ],
                          ),
                        ) ??
                        false;
                  },
                  onDismissed: (_) async {
                    await context.read<SettingsProvider>().deleteQrCode(code);
                  },
                  child: Card(
                    child: ListTile(
                      leading: Image.file(
                        File(code.imagePath),
                        width: 56,
                        height: 56,
                        fit: BoxFit.cover,
                      ),
                      title: Text(code.label),
                      subtitle: Text(code.imagePath),
                    ),
                  ),
                );
              },
            ),
    );
  }
}
