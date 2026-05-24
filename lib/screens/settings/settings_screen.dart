import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:provider/provider.dart';

import '../../models/qr_code.dart';
import '../../providers/settings_provider.dart';
import '../../utils/constants.dart';
import '../../services/backup_service.dart';
import '../shared/section_header.dart';
import 'add_qr_dialog.dart';
import 'pin_setup_screen.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final _storeController = TextEditingController();
  late final Future<PackageInfo> _packageInfoFuture;
  bool _initialized = false;
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    _packageInfoFuture = PackageInfo.fromPlatform();
  }

  @override
  void dispose() {
    _storeController.dispose();
    super.dispose();
  }

  /// Copies persisted settings into the text controllers once on first build.
  void _syncControllers(SettingsProvider settings) {
    if (_initialized) return;
    _storeController.text = settings.storeName;
    _initialized = true;
  }

  /// Saves the edited store name and shows a confirmation message.
  Future<void> _saveStoreName() async {
    await context
        .read<SettingsProvider>()
        .updateStoreName(_storeController.text);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Store name updated.')),
      );
    }
  }

  /// Exports the database backup file and shares it with the user.
  Future<void> _exportBackup() async {
    if (_busy) return;
    setState(() => _busy = true);
    try {
      final settings = context.read<SettingsProvider>();
      final payload = await settings.exportBackupData();
      final jsonText = const JsonEncoder.withIndent('  ').convert(payload);
      final fileName =
          'tindatap_backup_${DateFormat('yyyy-MM-dd').format(DateTime.now())}.json';
      final saved = await BackupService.instance.exportBackup(
        fileName: fileName,
        data: Uint8List.fromList(utf8.encode(jsonText)),
      );
      if (!saved) return;
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Backup exported successfully.')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString().replaceFirst('Exception: ', ''))),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _busy = false);
      }
    }
  }

  /// Lets the user pick a backup file and restores the app database from it.
  Future<void> _importBackup() async {
    if (_busy) return;
    setState(() => _busy = true);
    try {
      final jsonText = await BackupService.instance.importBackup();
      if (jsonText == null) return;
      final decoded = jsonDecode(jsonText);
      if (decoded is! Map<String, dynamic>) {
        throw const FormatException('Backup file is corrupted or invalid.');
      }
      await context.read<SettingsProvider>().importBackupData(decoded);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Backup imported successfully.')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString().replaceFirst('Exception: ', ''))),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _busy = false);
      }
    }
  }

  /// Opens the QR code dialog and refreshes the list after a successful save.
  Future<void> _addQrCode() async {
    final saved = await showDialog<bool>(
      context: context,
      builder: (_) => const AddQrDialog(),
    );
    if (saved == true) {
      await context.read<SettingsProvider>().refreshQrCodes();
      if (mounted) setState(() {});
    }
  }

  /// Opens the PIN setup popup in the requested mode and updates the screen if
  /// the PIN configuration changes.
  Future<void> _openPinPopup(PinSetupMode mode) async {
    final result = await showDialog<bool>(
      context: context,
      barrierColor: Colors.transparent,
      builder: (_) => PinSetupScreen(mode: mode),
    );
    if (result == true && mounted) {
      setState(() {});
    }
  }

  /// Shows a large preview of the selected QR code image for review.
  Future<void> _viewQrCode(QrCodeEntry code) async {
    await showDialog<void>(
      context: context,
      builder: (context) => Dialog(
        insetPadding: const EdgeInsets.all(20),
        child: Padding(
          padding: const EdgeInsets.all(18),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                code.label,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF0B1B3B),
                ),
              ),
              const SizedBox(height: 12),
              ClipRRect(
                borderRadius: BorderRadius.circular(14),
                child: Image.file(
                  File(code.imagePath),
                  fit: BoxFit.contain,
                  errorBuilder: (_, __, ___) => Container(
                    height: 220,
                    color: const Color(0xFFF1F5F9),
                    alignment: Alignment.center,
                    child: const Text('QR image not available'),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Text(
                'Open this QR code on the customer device to complete payment.',
                style: TextStyle(
                  fontSize: 13,
                  color: Colors.grey.shade700,
                ),
              ),
              const SizedBox(height: 8),
              Align(
                alignment: Alignment.centerRight,
                child: TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Close'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Reuses the add dialog in edit mode so the QR label can be updated.
  Future<void> _editQrLabel(QrCodeEntry code) async {
    final saved = await showDialog<bool>(
      context: context,
      builder: (_) => AddQrDialog(existing: code),
    );
    if (saved == true) {
      await context.read<SettingsProvider>().refreshQrCodes();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('QR code updated.')),
        );
        setState(() {});
      }
    }
  }

  /// Confirms deletion, removes the QR code, and refreshes the list.
  Future<void> _deleteQrCode(QrCodeEntry code) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete QR Code?'),
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
    );

    if (confirmed != true) return;

    try {
      await context.read<SettingsProvider>().deleteQrCode(code);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('QR code deleted.')),
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

  /// Builds one QR code list tile with preview, actions, and metadata.
  Widget _buildQrTile(QrCodeEntry code) {
    return Card(
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        onTap: () => _viewQrCode(code),
        leading: ClipRRect(
          borderRadius: BorderRadius.circular(10),
          child: Image.file(
            File(code.imagePath),
            width: 48,
            height: 48,
            fit: BoxFit.cover,
            errorBuilder: (_, __, ___) => Container(
              width: 48,
              height: 48,
              color: const Color(0xFFF1F5F9),
              alignment: Alignment.center,
              child: const Icon(Icons.qr_code_2),
            ),
          ),
        ),
        title: Text(
          code.label,
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
        subtitle: const Text('Tap to view QR code'),
        trailing: PopupMenuButton<String>(
          onSelected: (value) {
            switch (value) {
              case 'edit':
                _editQrLabel(code);
                break;
              case 'delete':
                _deleteQrCode(code);
                break;
            }
          },
          itemBuilder: (context) => const [
            PopupMenuItem<String>(
              value: 'edit',
              child: Text('Edit label'),
            ),
            PopupMenuItem<String>(
              value: 'delete',
              child: Text('Delete'),
            ),
          ],
        ),
      ),
    );
  }

  @override

  /// Builds the settings hub with store, security, and data-management actions.
  Widget build(BuildContext context) {
    final settings = context.watch<SettingsProvider>();
    _syncControllers(settings);

    return Scaffold(
      body: Stack(
        children: [
          Column(
            children: [
              SectionHeader(storeName: settings.storeName),
              Expanded(
                child: Container(
                  width: double.infinity,
                  color: const Color(0xFFF8FAFC),
                  child: ListView(
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
                    children: [
                      const SizedBox(height: 4),
                      Card(
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              const Text(
                                'Store Settings',
                                style: TextStyle(fontWeight: FontWeight.bold),
                              ),
                              const SizedBox(height: 12),
                              ListTile(
                                contentPadding: EdgeInsets.zero,
                                leading: Container(
                                  padding: const EdgeInsets.all(10),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFE6F6EF),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: const Icon(Icons.store,
                                      color: Color(0xFF1EAF6F)),
                                ),
                                title: const Text('Store Name'),
                                subtitle: Text(settings.storeName.isEmpty
                                    ? 'Not set'
                                    : settings.storeName),
                                trailing: const Icon(Icons.chevron_right),
                                onTap: () async {
                                  _storeController.text = settings.storeName;
                                  final result = await showDialog<bool>(
                                    context: context,
                                    builder: (context) => AlertDialog(
                                      title: const Text('Edit Store Name'),
                                      content: TextFormField(
                                        controller: _storeController,
                                        decoration: const InputDecoration(
                                          labelText: 'Store Name',
                                        ),
                                      ),
                                      actions: [
                                        TextButton(
                                          onPressed: () =>
                                              Navigator.pop(context, false),
                                          child: const Text('Cancel'),
                                        ),
                                        FilledButton(
                                          onPressed: () async {
                                            await _saveStoreName();
                                            Navigator.pop(context, true);
                                          },
                                          child: const Text('Save'),
                                        ),
                                      ],
                                    ),
                                  );
                                  if (result == true && mounted) {
                                    setState(() {});
                                  }
                                },
                              ),
                              const SizedBox(height: 8),
                              ListTile(
                                contentPadding: EdgeInsets.zero,
                                leading: Container(
                                  padding: const EdgeInsets.all(10),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFE8F0FF),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: const Icon(Icons.attach_money,
                                      color: Color(0xFF2B7BE4)),
                                ),
                                title: const Text('Currency'),
                                subtitle: Text(
                                  '${settings.currencySymbol} ${settings.currencyCode}',
                                ),
                                trailing: const Icon(Icons.chevron_right),
                                onTap: () async {
                                  final choice = await showDialog<String?>(
                                    context: context,
                                    builder: (context) => SimpleDialog(
                                      title: const Text('Select currency'),
                                      children: AppConstants
                                          .supportedCurrencyCodes
                                          .map((code) {
                                        return SimpleDialogOption(
                                          onPressed: () =>
                                              Navigator.pop(context, code),
                                          child: Text(
                                            '${AppConstants.currencySymbols[code] ?? ''} $code',
                                          ),
                                        );
                                      }).toList(),
                                    ),
                                  );
                                  if (choice != null) {
                                    await context
                                        .read<SettingsProvider>()
                                        .updateCurrencyCode(choice);
                                    if (mounted) setState(() {});
                                  }
                                },
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      Card(
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              const Text(
                                'Security',
                                style: TextStyle(fontWeight: FontWeight.bold),
                              ),
                              const SizedBox(height: 12),
                              ListTile(
                                contentPadding: EdgeInsets.zero,
                                leading: Container(
                                  padding: const EdgeInsets.all(10),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFFFF3E0),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: const Icon(Icons.lock,
                                      color: Color(0xFFFB8C00)),
                                ),
                                title: const Text('App PIN',
                                    style: TextStyle(fontSize: 15)),
                                subtitle: Text(
                                  settings.pinEnabled
                                      ? 'Enabled - Tap to change or remove'
                                      : 'Disabled - Tap to set a PIN',
                                  style: const TextStyle(fontSize: 13),
                                ),
                                trailing: const Icon(Icons.chevron_right),
                                onTap: () async {
                                  if (settings.pinEnabled) {
                                    final action =
                                        await showModalBottomSheet<String>(
                                      context: context,
                                      builder: (context) => Column(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          ListTile(
                                            leading: const Icon(Icons.edit),
                                            title: const Text('Change PIN'),
                                            onTap: () => Navigator.pop(
                                                context, 'change'),
                                          ),
                                          ListTile(
                                            leading: const Icon(Icons.restore),
                                            title: const Text('Reset PIN'),
                                            onTap: () =>
                                                Navigator.pop(context, 'reset'),
                                          ),
                                          ListTile(
                                            leading: const Icon(Icons.delete),
                                            title: const Text('Disable PIN'),
                                            onTap: () => Navigator.pop(
                                                context, 'disable'),
                                          ),
                                        ],
                                      ),
                                    );
                                    if (action == 'change' ||
                                        action == 'reset') {
                                      final mode = action == 'change'
                                          ? PinSetupMode.setup
                                          : PinSetupMode.reset;
                                      await _openPinPopup(mode);
                                    } else if (action == 'disable') {
                                      final confirm = await showDialog<bool>(
                                        context: context,
                                        builder: (context) => AlertDialog(
                                          title: const Text('Disable PIN?'),
                                          content: const Text(
                                            'This will remove PIN protection.',
                                          ),
                                          actions: [
                                            TextButton(
                                              onPressed: () =>
                                                  Navigator.pop(context, false),
                                              child: const Text('Cancel'),
                                            ),
                                            FilledButton(
                                              onPressed: () =>
                                                  Navigator.pop(context, true),
                                              child: const Text('Disable'),
                                            ),
                                          ],
                                        ),
                                      );
                                      if (confirm == true) {
                                        await context
                                            .read<SettingsProvider>()
                                            .disablePin();
                                        if (mounted) setState(() {});
                                      }
                                    }
                                  } else {
                                    await _openPinPopup(PinSetupMode.setup);
                                  }
                                },
                              ),
                              const SizedBox(height: 8),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      Card(
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              const Text(
                                'Data Management',
                                style: TextStyle(fontWeight: FontWeight.bold),
                              ),
                              const SizedBox(height: 12),
                              ListTile(
                                contentPadding: EdgeInsets.zero,
                                leading: Container(
                                  padding: const EdgeInsets.all(10),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFEFF6FF),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: const Icon(Icons.upload,
                                      color: Color(0xFF6D5EF8)),
                                ),
                                title: const Text('Export Data'),
                                subtitle:
                                    const Text('Backup all your store data'),
                                trailing: const Icon(Icons.chevron_right),
                                onTap: _busy ? null : _exportBackup,
                              ),
                              const SizedBox(height: 8),
                              ListTile(
                                contentPadding: EdgeInsets.zero,
                                leading: Container(
                                  padding: const EdgeInsets.all(10),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFF3E8FF),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: const Icon(Icons.download,
                                      color: Color(0xFF7A4BFF)),
                                ),
                                title: const Text('Import Data'),
                                subtitle:
                                    const Text('Restore from backup file'),
                                trailing: const Icon(Icons.chevron_right),
                                onTap: _busy ? null : _importBackup,
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      Card(
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              Row(
                                children: [
                                  const Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          'Payment QR Codes',
                                          style: TextStyle(
                                            fontSize: 16,
                                            fontWeight: FontWeight.w700,
                                          ),
                                        ),
                                        SizedBox(height: 4),
                                        Text(
                                          'Add QR codes for GCash, Maya, or other payment methods.',
                                          style: TextStyle(
                                            fontSize: 13,
                                            color: Color(0xFF667085),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  IconButton(
                                    onPressed: _busy ? null : _addQrCode,
                                    style: IconButton.styleFrom(
                                      backgroundColor: const Color(0xFF12B981),
                                      foregroundColor: Colors.white,
                                    ),
                                    icon: const Icon(Icons.add),
                                    tooltip: 'Add QR code',
                                  ),
                                ],
                              ),
                              const SizedBox(height: 12),
                              if (settings.qrCodes.isEmpty)
                                Container(
                                  width: double.infinity,
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 16,
                                    vertical: 28,
                                  ),
                                  decoration: BoxDecoration(
                                    border: Border.all(
                                      color: const Color(0xFFD5DCE5),
                                    ),
                                    borderRadius: BorderRadius.circular(14),
                                  ),
                                  child: const Text(
                                    'No QR codes added yet. Tap + to add one.',
                                    textAlign: TextAlign.center,
                                    style: TextStyle(
                                      fontSize: 14,
                                      color: Color(0xFF475467),
                                    ),
                                  ),
                                )
                              else
                                ListView.separated(
                                  shrinkWrap: true,
                                  physics: const NeverScrollableScrollPhysics(),
                                  itemCount: settings.qrCodes.length,
                                  separatorBuilder: (_, __) =>
                                      const SizedBox(height: 8),
                                  itemBuilder: (context, index) {
                                    return _buildQrTile(
                                        settings.qrCodes[index]);
                                  },
                                ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      Card(
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: FutureBuilder<PackageInfo>(
                            future: _packageInfoFuture,
                            builder: (context, snapshot) {
                              final appName =
                                  snapshot.data?.appName.isNotEmpty == true
                                      ? snapshot.data!.appName
                                      : AppConstants.appName;
                              final version =
                                  snapshot.data?.version.isNotEmpty == true
                                      ? snapshot.data!.version
                                      : 'Loading...';

                              return Column(
                                crossAxisAlignment: CrossAxisAlignment.stretch,
                                children: [
                                  const Text(
                                    'App Information',
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                  const SizedBox(height: 12),
                                  const Text(
                                    'App Name',
                                    style: TextStyle(
                                      fontSize: 13,
                                      color: Color(0xFF667085),
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    appName,
                                    style: const TextStyle(
                                      fontSize: 15,
                                      fontWeight: FontWeight.w600,
                                      color: Color(0xFF0B1B3B),
                                    ),
                                  ),
                                  const SizedBox(height: 14),
                                  const Divider(height: 1),
                                  const SizedBox(height: 14),
                                  const Text(
                                    'Version',
                                    style: TextStyle(
                                      fontSize: 13,
                                      color: Color(0xFF667085),
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    version,
                                    style: const TextStyle(
                                      fontSize: 15,
                                      fontWeight: FontWeight.w600,
                                      color: Color(0xFF0B1B3B),
                                    ),
                                  ),
                                ],
                              );
                            },
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          if (_busy)
            Positioned.fill(
              child: AbsorbPointer(
                absorbing: true,
                child: Container(
                  color: Colors.black.withOpacity(0.15),
                  child: const Center(
                    child: Card(
                      child: Padding(
                        padding: EdgeInsets.symmetric(
                          horizontal: 20,
                          vertical: 18,
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2.5,
                              ),
                            ),
                            SizedBox(width: 14),
                            Text('Please wait...'),
                          ],
                        ),
                      ),
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
