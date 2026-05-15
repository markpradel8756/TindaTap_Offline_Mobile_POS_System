import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/settings_provider.dart';

enum _OnboardingStep {
  storeName,
  currency,
  pinChoice,
  setPin,
  skipPin,
}

class SetupScreen extends StatefulWidget {
  const SetupScreen({super.key});

  @override
  State<SetupScreen> createState() => _SetupScreenState();
}

class _SetupScreenState extends State<SetupScreen> {
  final TextEditingController _storeNameController = TextEditingController();

  _OnboardingStep _step = _OnboardingStep.storeName;
  String _currencyCode = 'PHP';
  String _pinValue = '';
  String _confirmPinValue = '';
  bool _wantsPin = false;
  bool _submitting = false;

  static const List<Map<String, String>> _currencies = [
    {'code': 'PHP', 'label': 'Philippine Peso', 'symbol': '₱'},
    {'code': 'USD', 'label': 'US Dollar', 'symbol': r'$'},
    {'code': 'EUR', 'label': 'Euro', 'symbol': '€'},
    {'code': 'GBP', 'label': 'British Pound', 'symbol': '£'},
  ];

  @override
  void dispose() {
    _storeNameController.dispose();
    super.dispose();
  }

  int get _progressIndex {
    switch (_step) {
      case _OnboardingStep.storeName:
        return 0;
      case _OnboardingStep.currency:
        return 1;
      case _OnboardingStep.pinChoice:
      case _OnboardingStep.setPin:
      case _OnboardingStep.skipPin:
        return 2;
    }
  }

  Future<bool> _onWillPop() async {
    switch (_step) {
      case _OnboardingStep.storeName:
        return false;
      case _OnboardingStep.currency:
        setState(() => _step = _OnboardingStep.storeName);
        return false;
      case _OnboardingStep.pinChoice:
        setState(() => _step = _OnboardingStep.currency);
        return false;
      case _OnboardingStep.setPin:
      case _OnboardingStep.skipPin:
        setState(() => _step = _OnboardingStep.pinChoice);
        return false;
    }
  }

  void _nextFromStoreName() {
    if (_storeNameController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter your store name.')),
      );
      return;
    }
    setState(() => _step = _OnboardingStep.currency);
  }

  void _nextFromCurrency() {
    setState(() => _step = _OnboardingStep.pinChoice);
  }

  void _choosePinOption(bool setPin) {
    _wantsPin = setPin;
    setState(() {
      _step = setPin ? _OnboardingStep.setPin : _OnboardingStep.skipPin;
    });
  }

  String? _validatePin(String value) {
    if (!RegExp(r'^\d{4}$').hasMatch(value)) {
      return 'PIN must be exactly 4 digits.';
    }
    return null;
  }

  Future<void> _completeSetup() async {
    if (_submitting) return;

    if (_wantsPin) {
      final pinError = _validatePin(_pinValue.trim());
      if (pinError != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(pinError)),
        );
        return;
      }
      if (_pinValue.trim() != _confirmPinValue.trim()) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('PIN entries do not match.')),
        );
        return;
      }
    }

    setState(() => _submitting = true);

    try {
      final settings = context.read<SettingsProvider>();
      await settings.updateStoreName(_storeNameController.text.trim());
      await settings.updateCurrencyCode(_currencyCode);

      if (_wantsPin) {
        await settings.savePinConfiguration(
          pin: _pinValue.trim(),
          securityQuestion: 'What is your store name?',
          securityAnswer: _storeNameController.text.trim(),
        );
      } else {
        await settings.disablePin();
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString().replaceFirst('Exception: ', ''))),
      );
    } finally {
      if (mounted) {
        setState(() => _submitting = false);
      }
    }
  }

  Widget _stepIndicator() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(3, (index) {
        final active = index == _progressIndex;
        return AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          margin: const EdgeInsets.symmetric(horizontal: 4),
          width: 8,
          height: 8,
          decoration: BoxDecoration(
            color: active ? const Color(0xFF12B981) : const Color(0xFFC6CAD2),
            shape: BoxShape.circle,
          ),
        );
      }),
    );
  }

  Widget _buildStoreStep() {
    final width = MediaQuery.of(context).size.width;
    final titleSize = width < 360 ? 21.0 : 24.0;
    final bodySize = width < 360 ? 13.0 : 14.0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const _HeaderIcon(icon: Icons.storefront_outlined),
        const SizedBox(height: 14),
        Text(
          'Welcome to TindaTap!',
          textAlign: TextAlign.center,
          maxLines: 2,
          style: TextStyle(
            fontSize: titleSize,
            fontWeight: FontWeight.w800,
            color: const Color(0xFF0B1B3B),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Let\'s set up your store in a few simple steps',
          textAlign: TextAlign.center,
          maxLines: 2,
          style: TextStyle(fontSize: bodySize, color: const Color(0xFF475467)),
        ),
        const SizedBox(height: 16),
        const Text(
          'Store Name',
          style: TextStyle(
            fontWeight: FontWeight.w700,
            fontSize: 14,
            color: Color(0xFF1F2A44),
          ),
        ),
        const SizedBox(height: 6),
        TextField(
          controller: _storeNameController,
          textInputAction: TextInputAction.done,
          onChanged: (_) => setState(() {}),
          style: const TextStyle(
            color: Color(0xFF0B1B3B),
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
          decoration: InputDecoration(
            hintText: 'e.g., Maria\'s Sari-Sari Store',
            hintStyle: const TextStyle(
              color: Color(0xFF667085),
              fontSize: 13,
            ),
            filled: true,
            fillColor: const Color(0xFFF3F4F6),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 14,
              vertical: 11,
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: const BorderSide(color: Color(0xFFD0D5DD)),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: const BorderSide(color: Color(0xFFD0D5DD)),
            ),
          ),
        ),
        const SizedBox(height: 14),
        _ActionButton(
          label: 'Continue',
          onPressed: _storeNameController.text.trim().isEmpty
              ? null
              : _nextFromStoreName,
          trailingIcon: Icons.chevron_right,
        ),
      ],
    );
  }

  Widget _buildCurrencyStep() {
    final width = MediaQuery.of(context).size.width;
    final titleSize = width < 360 ? 21.0 : 24.0;
    final bodySize = width < 360 ? 13.0 : 14.0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const _HeaderIcon(icon: Icons.attach_money),
        const SizedBox(height: 14),
        Text(
          'Choose Your Currency',
          textAlign: TextAlign.center,
          maxLines: 2,
          style: TextStyle(
            fontSize: titleSize,
            fontWeight: FontWeight.w800,
            color: const Color(0xFF0B1B3B),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Select the currency you\'ll use for pricing',
          textAlign: TextAlign.center,
          maxLines: 2,
          style: TextStyle(fontSize: bodySize, color: const Color(0xFF475467)),
        ),
        const SizedBox(height: 14),
        ..._currencies.map((currency) {
          final selected = _currencyCode == currency['code'];
          return Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: InkWell(
              borderRadius: BorderRadius.circular(14),
              onTap: () => setState(() => _currencyCode = currency['code']!),
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                decoration: BoxDecoration(
                  color: selected
                      ? const Color(0xFFE1F4EA)
                      : const Color(0xFFF1F3F6),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color:
                        selected ? const Color(0xFF12B981) : Colors.transparent,
                  ),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 34,
                      height: 34,
                      decoration: BoxDecoration(
                        color: selected
                            ? const Color(0xFF12B981)
                            : const Color(0xFFE5E7EB),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Center(
                        child: Text(
                          currency['symbol']!,
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: selected
                                ? Colors.white
                                : const Color(0xFF475467),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 7),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            currency['label']!,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                              color: Color(0xFF0B1B3B),
                            ),
                          ),
                          Text(
                            currency['code']!,
                            style: const TextStyle(
                              color: Color(0xFF475467),
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 4),
                    Icon(
                      selected ? Icons.check_circle : Icons.circle_outlined,
                      size: width < 360 ? 16 : 18,
                      color: selected
                          ? const Color(0xFF12B981)
                          : const Color(0xFFC6CAD2),
                    ),
                  ],
                ),
              ),
            ),
          );
        }),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: _ActionButton(
                label: 'Back',
                isPrimary: false,
                onPressed: () =>
                    setState(() => _step = _OnboardingStep.storeName),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _ActionButton(
                label: 'Continue',
                trailingIcon: Icons.chevron_right,
                onPressed: _nextFromCurrency,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildPinChoiceStep() {
    final width = MediaQuery.of(context).size.width;
    final titleSize = width < 360 ? 21.0 : 24.0;
    final bodySize = width < 360 ? 13.0 : 14.0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const _HeaderIcon(icon: Icons.lock_outline),
        const SizedBox(height: 14),
        Text(
          'Secure Your Store',
          textAlign: TextAlign.center,
          maxLines: 2,
          style: TextStyle(
            fontSize: titleSize,
            fontWeight: FontWeight.w800,
            color: const Color(0xFF0B1B3B),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Would you like to add a 4-digit PIN for extra security?',
          textAlign: TextAlign.center,
          maxLines: 2,
          style: TextStyle(fontSize: bodySize, color: const Color(0xFF475467)),
        ),
        const SizedBox(height: 14),
        _ChoiceTile(
          title: 'Yes, set up a PIN',
          subtitle: 'Protect your store data',
          selected: true,
          onTap: () => _choosePinOption(true),
        ),
        const SizedBox(height: 8),
        _ChoiceTile(
          title: 'Skip for now',
          subtitle: 'You can add it later in Settings',
          selected: false,
          onTap: () => _choosePinOption(false),
        ),
      ],
    );
  }

  Widget _buildSetPinStep() {
    final width = MediaQuery.of(context).size.width;
    final titleSize = width < 360 ? 21.0 : 24.0;
    final bodySize = width < 360 ? 13.0 : 14.0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const _HeaderIcon(icon: Icons.lock_outline),
        const SizedBox(height: 14),
        Text(
          'Secure Your Store',
          textAlign: TextAlign.center,
          maxLines: 2,
          style: TextStyle(
            fontSize: titleSize,
            fontWeight: FontWeight.w800,
            color: const Color(0xFF0B1B3B),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Would you like to add a 4-digit PIN for extra security?',
          textAlign: TextAlign.center,
          maxLines: 2,
          style: TextStyle(fontSize: bodySize, color: const Color(0xFF475467)),
        ),
        const SizedBox(height: 14),
        const Text('Enter 4-digit PIN',
            style: TextStyle(
              fontWeight: FontWeight.w700,
              fontSize: 14,
              color: Color(0xFF1F2A44),
            )),
        const SizedBox(height: 6),
        _PinInputField(
          maxLength: 4,
          onChanged: (value) => setState(() => _pinValue = value),
        ),
        const SizedBox(height: 10),
        const Text('Confirm PIN',
            style: TextStyle(
              fontWeight: FontWeight.w700,
              fontSize: 14,
              color: Color(0xFF1F2A44),
            )),
        const SizedBox(height: 6),
        _PinInputField(
          maxLength: 4,
          onChanged: (value) => setState(() => _confirmPinValue = value),
        ),
        const SizedBox(height: 14),
        Row(
          children: [
            Expanded(
              child: _ActionButton(
                label: 'Back',
                isPrimary: false,
                onPressed: () =>
                    setState(() => _step = _OnboardingStep.pinChoice),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _ActionButton(
                label: 'Complete Setup',
                leadingIcon: Icons.check,
                onPressed: (_pinValue.length == 4 &&
                        _confirmPinValue.length == 4 &&
                        !_submitting)
                    ? _completeSetup
                    : null,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildSkipPinStep() {
    final width = MediaQuery.of(context).size.width;
    final titleSize = width < 360 ? 21.0 : 24.0;
    final bodySize = width < 360 ? 13.0 : 14.0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const _HeaderIcon(icon: Icons.lock_outline),
        const SizedBox(height: 14),
        Text(
          'Secure Your Store',
          textAlign: TextAlign.center,
          maxLines: 2,
          style: TextStyle(
            fontSize: titleSize,
            fontWeight: FontWeight.w800,
            color: const Color(0xFF0B1B3B),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Would you like to add a 4-digit PIN for extra security?',
          textAlign: TextAlign.center,
          maxLines: 2,
          style: TextStyle(fontSize: bodySize, color: const Color(0xFF475467)),
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: _ActionButton(
                label: 'Back',
                isPrimary: false,
                onPressed: () =>
                    setState(() => _step = _OnboardingStep.pinChoice),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _ActionButton(
                label: 'Complete Setup',
                leadingIcon: Icons.check,
                onPressed: _submitting ? null : _completeSetup,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildStepContent() {
    switch (_step) {
      case _OnboardingStep.storeName:
        return _buildStoreStep();
      case _OnboardingStep.currency:
        return _buildCurrencyStep();
      case _OnboardingStep.pinChoice:
        return _buildPinChoiceStep();
      case _OnboardingStep.setPin:
        return _buildSetPinStep();
      case _OnboardingStep.skipPin:
        return _buildSkipPinStep();
    }
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: _onWillPop,
      child: Scaffold(
        resizeToAvoidBottomInset: true,
        body: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [Color(0xFF14B785), Color(0xFF09A370)],
            ),
          ),
          child: SafeArea(
            child: LayoutBuilder(
              builder: (context, constraints) {
                return SingleChildScrollView(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  child: ConstrainedBox(
                    constraints:
                        BoxConstraints(minHeight: constraints.maxHeight),
                    child: Center(
                      child: Container(
                        width: double.infinity,
                        constraints: const BoxConstraints(maxWidth: 420),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF8F8F9),
                          borderRadius: BorderRadius.circular(28),
                          boxShadow: const [
                            BoxShadow(
                              color: Color(0x22000000),
                              blurRadius: 12,
                              offset: Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Padding(
                          padding: const EdgeInsets.fromLTRB(16, 14, 16, 12),
                          child: AnimatedSwitcher(
                            duration: const Duration(milliseconds: 220),
                            transitionBuilder: (child, animation) {
                              return FadeTransition(
                                opacity: animation,
                                child: SlideTransition(
                                  position: Tween<Offset>(
                                    begin: const Offset(0.08, 0),
                                    end: Offset.zero,
                                  ).animate(animation),
                                  child: child,
                                ),
                              );
                            },
                            child: Column(
                              key: ValueKey(_step),
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                _buildStepContent(),
                                const SizedBox(height: 10),
                                _stepIndicator(),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ),
      ),
    );
  }
}

class _HeaderIcon extends StatelessWidget {
  final IconData icon;

  const _HeaderIcon({required this.icon});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 52,
      height: 52,
      decoration: BoxDecoration(
        color: const Color(0xFF12B981),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Icon(icon, size: 28, color: Colors.white),
    );
  }
}

class _ActionButton extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;
  final IconData? trailingIcon;
  final IconData? leadingIcon;
  final bool isPrimary;

  const _ActionButton({
    required this.label,
    this.onPressed,
    this.trailingIcon,
    this.leadingIcon,
    this.isPrimary = true,
  });

  @override
  Widget build(BuildContext context) {
    final enabled = onPressed != null;
    return SizedBox(
      height: 44,
      child: FilledButton(
        onPressed: onPressed,
        style: FilledButton.styleFrom(
          foregroundColor: isPrimary ? Colors.white : const Color(0xFF24324A),
          backgroundColor: isPrimary
              ? (enabled ? const Color(0xFF12B981) : const Color(0xFFD1D5DB))
              : const Color(0xFFE5E7EB),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
          textStyle: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (leadingIcon != null) ...[
              Icon(leadingIcon, size: 18),
              const SizedBox(width: 4),
            ],
            Flexible(
              child: Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
              ),
            ),
            if (trailingIcon != null) ...[
              const SizedBox(width: 4),
              Icon(trailingIcon, size: 18),
            ],
          ],
        ),
      ),
    );
  }
}

class _ChoiceTile extends StatelessWidget {
  final String title;
  final String subtitle;
  final bool selected;
  final VoidCallback onTap;

  const _ChoiceTile({
    required this.title,
    required this.subtitle,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(14),
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: selected ? const Color(0xFFE1F4EA) : const Color(0xFFF1F3F6),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: selected ? const Color(0xFF12B981) : const Color(0xFFD0D5DD),
          ),
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF0B1B3B),
                    ),
                  ),
                  const SizedBox(height: 1),
                  Text(
                    subtitle,
                    style: const TextStyle(
                      color: Color(0xFF475467),
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.chevron_right,
              color:
                  selected ? const Color(0xFF12B981) : const Color(0xFF98A2B3),
            ),
          ],
        ),
      ),
    );
  }
}

class _PinInputField extends StatelessWidget {
  final int maxLength;
  final ValueChanged<String> onChanged;

  const _PinInputField({
    required this.onChanged,
    this.maxLength = 4,
  });

  @override
  Widget build(BuildContext context) {
    return _PinBoxesField(
      length: maxLength,
      onChanged: onChanged,
    );
  }
}

class _PinBoxesField extends StatefulWidget {
  final int length;
  final ValueChanged<String> onChanged;

  const _PinBoxesField({required this.length, required this.onChanged});

  @override
  State<_PinBoxesField> createState() => _PinBoxesFieldState();
}

class _PinBoxesFieldState extends State<_PinBoxesField> {
  late final List<TextEditingController> _controllers;
  late final List<FocusNode> _focusNodes;

  @override
  void initState() {
    super.initState();
    _controllers = List.generate(widget.length, (_) => TextEditingController());
    _focusNodes = List.generate(widget.length, (_) => FocusNode());
  }

  @override
  void dispose() {
    for (final c in _controllers) {
      c.dispose();
    }
    for (final f in _focusNodes) {
      f.dispose();
    }
    super.dispose();
  }

  void _emitValue() {
    final value = _controllers.map((e) => e.text).join();
    widget.onChanged(value);
  }

  void _handleChanged(int index, String value) {
    var normalized = value;
    if (normalized.length > 1) {
      normalized = normalized.substring(normalized.length - 1);
    }
    normalized = normalized.replaceAll(RegExp(r'[^0-9]'), '');

    _controllers[index].value = TextEditingValue(
      text: normalized,
      selection: TextSelection.collapsed(offset: normalized.length),
    );

    if (normalized.isNotEmpty && index < widget.length - 1) {
      _focusNodes[index + 1].requestFocus();
    }

    if (normalized.isEmpty && index > 0) {
      _focusNodes[index - 1].requestFocus();
    }

    _emitValue();
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        for (int index = 0; index < widget.length; index++) ...[
          if (index > 0) const SizedBox(width: 6),
          Expanded(
            child: AspectRatio(
              aspectRatio: 1,
              child: Builder(
                builder: (context) {
                  final hasDigit = _controllers[index].text.isNotEmpty;
                  return TextField(
                    controller: _controllers[index],
                    focusNode: _focusNodes[index],
                    autofocus: index == 0,
                    textAlign: TextAlign.center,
                    keyboardType: TextInputType.number,
                    maxLength: 1,
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF0B1B3B),
                    ),
                    decoration: InputDecoration(
                      counterText: '',
                      contentPadding: const EdgeInsets.symmetric(vertical: 8),
                      filled: true,
                      fillColor: const Color(0xFFF3F4F6),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: BorderSide(
                          color: hasDigit
                              ? const Color(0xFF12B981)
                              : const Color(0xFFD0D5DD),
                        ),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: BorderSide(
                          color: hasDigit
                              ? const Color(0xFF12B981)
                              : const Color(0xFFD0D5DD),
                        ),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: const BorderSide(
                          color: Color(0xFF12B981),
                          width: 1.5,
                        ),
                      ),
                    ),
                    onChanged: (value) => _handleChanged(index, value),
                  );
                },
              ),
            ),
          ),
        ],
      ],
    );
  }
}
