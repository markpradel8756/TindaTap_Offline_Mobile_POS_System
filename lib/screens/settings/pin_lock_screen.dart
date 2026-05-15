import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../../providers/settings_provider.dart';

class PinLockScreen extends StatefulWidget {
  final VoidCallback onUnlocked;

  const PinLockScreen({super.key, required this.onUnlocked});

  @override
  State<PinLockScreen> createState() => _PinLockScreenState();
}

class _PinLockScreenState extends State<PinLockScreen> {
  static const int _pinLength = 4;

  late final List<TextEditingController> _pinControllers;
  late final List<FocusNode> _pinFocusNodes;

  bool _submitting = false;

  @override
  void initState() {
    super.initState();
    _pinControllers = List.generate(_pinLength, (_) => TextEditingController());
    _pinFocusNodes = List.generate(_pinLength, (_) => FocusNode());
  }

  @override
  void dispose() {
    for (final controller in _pinControllers) {
      controller.dispose();
    }
    for (final node in _pinFocusNodes) {
      node.dispose();
    }
    super.dispose();
  }

  /// Reads the current PIN digits from all input boxes.
  String get _pin => _pinControllers.map((c) => c.text).join();

  /// Returns true when all PIN digits have been filled in.
  bool get _isFullPin => _pin.length == _pinLength;

  /// Checks the entered PIN and unlocks the app when it matches.
  Future<void> _unlock() async {
    if (!_isFullPin || _submitting) return;

    final settings = context.read<SettingsProvider>();

    setState(() => _submitting = true);
    try {
      if (settings.verifyPin(_pin)) {
        widget.onUnlocked();
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Incorrect PIN.')),
          );
          _clearPin();
        }
      }
    } finally {
      if (mounted) {
        setState(() => _submitting = false);
      }
    }
  }

  /// Clears the entered digits and returns focus to the first box.
  void _clearPin() {
    for (final controller in _pinControllers) {
      controller.clear();
    }
    _pinFocusNodes.first.requestFocus();
  }

  /// Normalizes a typed digit and advances focus when appropriate.
  void _onDigitChanged({required int index, required String value}) {
    if (value.length > 1) {
      _pinControllers[index].text = value.substring(value.length - 1);
      _pinControllers[index].selection =
          const TextSelection.collapsed(offset: 1);
    }

    if (_pinControllers[index].text.isNotEmpty && index < _pinLength - 1) {
      _pinFocusNodes[index + 1].requestFocus();
    } else if (_isFullPin) {
      _unlock();
    }

    setState(() {});
  }

  /// Moves focus backward when the user presses backspace on an empty box.
  void _onDigitBackspace({required int index, required KeyEvent event}) {
    if (event is! KeyDownEvent ||
        event.logicalKey != LogicalKeyboardKey.backspace) {
      return;
    }

    if (_pinControllers[index].text.isEmpty && index > 0) {
      _pinFocusNodes[index - 1].requestFocus();
    }
  }

  @override

  /// Builds the lock screen used to block app access until the PIN is correct.
  Widget build(BuildContext context) {
    final settings = context.watch<SettingsProvider>();
    final storeName =
        settings.storeName.isEmpty ? 'TindaTap' : settings.storeName;

    return Scaffold(
      backgroundColor: const Color(0xFF1EAF6F),
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Container(
              constraints: const BoxConstraints(maxWidth: 360),
              padding: const EdgeInsets.fromLTRB(24, 40, 24, 32),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(24),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 72,
                    height: 72,
                    decoration: BoxDecoration(
                      color: const Color(0xFF1EAF6F),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: const Icon(
                      Icons.lock,
                      size: 40,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 24),
                  Text(
                    storeName,
                    style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF0B1B3B),
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Enter your PIN to continue',
                    style: TextStyle(
                      fontSize: 14,
                      color: Color(0xFF6E7786),
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 24),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: List.generate(_pinLength, (index) {
                      return SizedBox(
                        width: 54,
                        child: KeyboardListener(
                          focusNode: FocusNode(skipTraversal: true),
                          onKeyEvent: (event) => _onDigitBackspace(
                            index: index,
                            event: event,
                          ),
                          child: TextField(
                            controller: _pinControllers[index],
                            focusNode: _pinFocusNodes[index],
                            keyboardType: TextInputType.number,
                            textAlign: TextAlign.center,
                            obscureText: true,
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
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: 0,
                                vertical: 16,
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(14),
                                borderSide: const BorderSide(
                                  color: Color(0xFFCDD3DC),
                                ),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(14),
                                borderSide: const BorderSide(
                                  color: Color(0xFF1EAF6F),
                                  width: 2,
                                ),
                              ),
                            ),
                            onChanged: (value) => _onDigitChanged(
                              index: index,
                              value: value,
                            ),
                          ),
                        ),
                      );
                    }),
                  ),
                  const SizedBox(height: 24),
                  const Text(
                    "Forgot your PIN? You'll need to clear app data to reset.",
                    style: TextStyle(
                      fontSize: 12,
                      color: Color(0xFF9DA7B7),
                    ),
                    textAlign: TextAlign.center,
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
