import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../../providers/settings_provider.dart';

enum PinSetupMode { setup, reset }

class PinSetupScreen extends StatefulWidget {
  final PinSetupMode mode;

  const PinSetupScreen({super.key, required this.mode});

  @override
  State<PinSetupScreen> createState() => _PinSetupScreenState();
}

class _PinSetupScreenState extends State<PinSetupScreen> {
  static const int _pinLength = 4;

  late final List<TextEditingController> _pinControllers;
  late final List<TextEditingController> _confirmControllers;
  late final List<FocusNode> _pinFocusNodes;
  late final List<FocusNode> _confirmFocusNodes;

  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _pinControllers = List.generate(_pinLength, (_) => TextEditingController());
    _confirmControllers =
        List.generate(_pinLength, (_) => TextEditingController());
    _pinFocusNodes = List.generate(_pinLength, (_) => FocusNode());
    _confirmFocusNodes = List.generate(_pinLength, (_) => FocusNode());
  }

  @override
  void dispose() {
    for (final controller in _pinControllers) {
      controller.dispose();
    }
    for (final controller in _confirmControllers) {
      controller.dispose();
    }
    for (final node in _pinFocusNodes) {
      node.dispose();
    }
    for (final node in _confirmFocusNodes) {
      node.dispose();
    }
    super.dispose();
  }

  /// Reads the primary PIN entry boxes as one string.
  String get _pin => _pinControllers.map((c) => c.text).join();

  /// Reads the confirmation PIN entry boxes as one string.
  String get _confirmPin => _confirmControllers.map((c) => c.text).join();

  /// Returns true when both PIN entries are complete and identical.
  bool get _isValidPin =>
      _pin.length == _pinLength &&
      _confirmPin.length == _pinLength &&
      _pin == _confirmPin;

  /// Saves the new PIN and closes the dialog when validation passes.
  Future<void> _savePin() async {
    if (!_isValidPin || _saving) return;

    setState(() => _saving = true);
    try {
      await context.read<SettingsProvider>().updatePin(_pin);
      if (mounted) {
        Navigator.of(context).pop(true);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString().replaceFirst('Exception: ', ''))),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _saving = false);
      }
    }
  }

  /// Normalizes pasted input and advances the cursor through the PIN fields.
  void _onDigitChanged({
    required bool isConfirm,
    required int index,
    required String value,
  }) {
    final controllers = isConfirm ? _confirmControllers : _pinControllers;
    final focusNodes = isConfirm ? _confirmFocusNodes : _pinFocusNodes;

    if (value.length > 1) {
      // Keep only the last numeric character if user pastes text.
      controllers[index].text = value.substring(value.length - 1);
      controllers[index].selection = const TextSelection.collapsed(offset: 1);
    }

    if (controllers[index].text.isNotEmpty && index < _pinLength - 1) {
      focusNodes[index + 1].requestFocus();
    }

    setState(() {});
  }

  /// Moves focus to the previous digit when the user deletes an empty field.
  void _onDigitBackspace({
    required bool isConfirm,
    required int index,
    required KeyEvent event,
  }) {
    if (event is! KeyDownEvent ||
        event.logicalKey != LogicalKeyboardKey.backspace) {
      return;
    }

    final controllers = isConfirm ? _confirmControllers : _pinControllers;
    final focusNodes = isConfirm ? _confirmFocusNodes : _pinFocusNodes;

    if (controllers[index].text.isEmpty && index > 0) {
      focusNodes[index - 1].requestFocus();
    }
  }

  /// Builds one row of PIN boxes for either the PIN or confirmation entry.
  Widget _buildPinRow({required bool isConfirm}) {
    final controllers = isConfirm ? _confirmControllers : _pinControllers;
    final focusNodes = isConfirm ? _confirmFocusNodes : _pinFocusNodes;

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: List.generate(_pinLength, (index) {
        return SizedBox(
          width: 54,
          child: KeyboardListener(
            focusNode: FocusNode(skipTraversal: true),
            onKeyEvent: (event) => _onDigitBackspace(
              isConfirm: isConfirm,
              index: index,
              event: event,
            ),
            child: TextField(
              controller: controllers[index],
              focusNode: focusNodes[index],
              keyboardType: TextInputType.number,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w700,
                color: Color(0xFF0B1B3B),
              ),
              inputFormatters: [
                FilteringTextInputFormatter.digitsOnly,
                LengthLimitingTextInputFormatter(1),
              ],
              decoration: InputDecoration(
                counterText: '',
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 0, vertical: 16),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: const BorderSide(color: Color(0xFFCDD3DC)),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide:
                      const BorderSide(color: Color(0xFF9DA7B7), width: 1.5),
                ),
              ),
              onChanged: (value) => _onDigitChanged(
                isConfirm: isConfirm,
                index: index,
                value: value,
              ),
            ),
          ),
        );
      }),
    );
  }

  @override

  /// Builds the popup used to set or reset the app PIN.
  Widget build(BuildContext context) {
    final title =
        widget.mode == PinSetupMode.reset ? 'Reset PIN' : 'Set up PIN';
    final isPinReady = _isValidPin;

    return Scaffold(
      backgroundColor: Colors.black38,
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Container(
              width: 360,
              padding: const EdgeInsets.fromLTRB(24, 20, 24, 22),
              decoration: BoxDecoration(
                color: const Color(0xFFFAFAFB),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          title,
                          style: const TextStyle(
                            fontSize: 28,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFF0B1B3B),
                            letterSpacing: -0.5,
                          ),
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close, color: Color(0xFF6E7786)),
                        onPressed: () => Navigator.of(context).pop(false),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Enter 4-digit PIN',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w500,
                      color: Color(0xFF0B1B3B),
                    ),
                  ),
                  const SizedBox(height: 16),
                  _buildPinRow(isConfirm: false),
                  const SizedBox(height: 22),
                  const Text(
                    'Confirm PIN',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w500,
                      color: Color(0xFF0B1B3B),
                    ),
                  ),
                  const SizedBox(height: 16),
                  _buildPinRow(isConfirm: true),
                  const SizedBox(height: 24),
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton.icon(
                      onPressed: _saving || !_isValidPin ? null : _savePin,
                      icon: _saving
                          ? const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Icon(Icons.check, size: 16),
                      label: const Padding(
                        padding: EdgeInsets.symmetric(vertical: 12),
                        child: Text('Set PIN'),
                      ),
                      style: FilledButton.styleFrom(
                        backgroundColor: isPinReady
                            ? const Color(0xFF10B981)
                            : const Color(0xFFD7DCE4),
                        foregroundColor:
                            isPinReady ? Colors.white : const Color(0xFF8E98A8),
                        disabledBackgroundColor: const Color(0xFFD7DCE4),
                        disabledForegroundColor: const Color(0xFF8E98A8),
                        textStyle: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
