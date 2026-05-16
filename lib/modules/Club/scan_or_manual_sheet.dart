import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

import '../../core/models/club/game_model.dart';
import '../../core/styles/colors.dart';

/// Shows two options: QR scan or manual shortId entry.
/// Returns the shortId string or null if dismissed.
Future<String?> showScanOrManualSheet(BuildContext context, GameModel game) {
  return showModalBottomSheet<String>(
    context: context,
    isScrollControlled: true,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
    ),
    builder: (_) => _ScanOrManualSheet(game: game),
  );
}

/// Generic scan or manual input sheet for any context (games, services, etc.)
/// Returns the scanned/entered code or null if dismissed.
Future<String?> showScanOrManualInputSheet(
  BuildContext context, {
  required String title,
  String? subtitle,
  String? icon,
  String? coinsDisplay,
}) {
  return showModalBottomSheet<String>(
    context: context,
    isScrollControlled: true,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
    ),
    builder: (_) => _GenericScanOrManualSheet(
      title: title,
      subtitle: subtitle,
      icon: icon,
      coinsDisplay: coinsDisplay,
    ),
  );
}

class _ScanOrManualSheet extends StatefulWidget {
  final GameModel game;

  const _ScanOrManualSheet({required this.game});

  @override
  State<_ScanOrManualSheet> createState() => _ScanOrManualSheetState();
}

enum _Mode { choose, scan, manual }

class _ScanOrManualSheetState extends State<_ScanOrManualSheet> {
  _Mode _mode = _Mode.choose;
  final _controller = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  MobileScannerController? _scannerController;
  bool _scanned = false;

  @override
  void dispose() {
    _controller.dispose();
    _scannerController?.dispose();
    super.dispose();
  }

  void _startScan() {
    _scannerController = MobileScannerController();
    setState(() => _mode = _Mode.scan);
  }

  void _onDetect(BarcodeCapture capture) {
    if (_scanned) return;
    final code = capture.barcodes.firstOrNull?.rawValue;
    if (code != null && code.isNotEmpty) {
      _scanned = true;
      Navigator.of(context).pop(code);
    }
  }

  void _submitManual() {
    if (_formKey.currentState!.validate()) {
      Navigator.of(context).pop(_controller.text.trim());
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: AnimatedSize(
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeOut,
        child: Container(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Handle
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: colorScheme.outlineVariant,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 20),
              // Title
              Row(
                children: [
                  Text(widget.game.icon, style: const TextStyle(fontSize: 28)),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      widget.game.nameAr,
                      style: theme.textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: colorScheme.primary.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      '${widget.game.coins} 🪙',
                      style: TextStyle(
                        color: colorScheme.primary,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),

              if (_mode == _Mode.choose) ...[
                // Option buttons
                _OptionButton(
                  icon: Icons.qr_code_scanner_rounded,
                  label: 'مسح QR Code',
                  sublabel: 'امسح رمز QR الخاص بالطفل',
                  onTap: _startScan,
                ),
                const SizedBox(height: 12),
                _OptionButton(
                  icon: Icons.keyboard_alt_outlined,
                  label: 'إدخال الرمز يدوياً',
                  sublabel: 'اكتب الرمز القصير للطفل',
                  onTap: () => setState(() => _mode = _Mode.manual),
                ),
                const SizedBox(height: 8),
              ],

              if (_mode == _Mode.scan) ...[
                ClipRRect(
                  borderRadius: BorderRadius.circular(16),
                  child: SizedBox(
                    height: 260,
                    child: MobileScanner(
                      controller: _scannerController!,
                      onDetect: _onDetect,
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                TextButton.icon(
                  onPressed: () {
                    _scannerController?.dispose();
                    _scannerController = null;
                    setState(() => _mode = _Mode.choose);
                  },
                  icon: const Icon(Icons.arrow_back),
                  label: const Text('رجوع'),
                ),
              ],

              if (_mode == _Mode.manual) ...[
                Form(
                  key: _formKey,
                  child: TextFormField(
                    controller: _controller,
                    autofocus: true,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                    ),
                    decoration: InputDecoration(
                      hintText: 'الرمز القصير',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                    validator: (v) =>
                        (v == null || v.trim().isEmpty) ? 'أدخل الرمز' : null,
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    TextButton(
                      onPressed: () => setState(() => _mode = _Mode.choose),
                      child: const Text('رجوع'),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: FilledButton(
                        onPressed: _submitManual,
                        child: const Text('تأكيد'),
                      ),
                    ),
                  ],
                ),
              ],
              const SizedBox(height: 8),
            ],
          ),
        ),
      ),
    );
  }
}

class _GenericScanOrManualSheet extends StatefulWidget {
  final String title;
  final String? subtitle;
  final String? icon;
  final String? coinsDisplay;

  const _GenericScanOrManualSheet({
    required this.title,
    this.subtitle,
    this.icon,
    this.coinsDisplay,
  });

  @override
  State<_GenericScanOrManualSheet> createState() =>
      _GenericScanOrManualSheetState();
}

enum _GenericMode { choose, scan, manual }

class _GenericScanOrManualSheetState extends State<_GenericScanOrManualSheet> {
  _GenericMode _mode = _GenericMode.choose;
  final _controller = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  MobileScannerController? _scannerController;
  bool _scanned = false;

  @override
  void dispose() {
    _controller.dispose();
    _scannerController?.dispose();
    super.dispose();
  }

  void _startScan() {
    _scannerController = MobileScannerController();
    setState(() => _mode = _GenericMode.scan);
  }

  void _onDetect(BarcodeCapture capture) {
    if (_scanned) return;
    final code = capture.barcodes.firstOrNull?.rawValue;
    if (code != null && code.isNotEmpty) {
      _scanned = true;
      Navigator.of(context).pop(code);
    }
  }

  void _submitManual() {
    if (_formKey.currentState!.validate()) {
      Navigator.of(context).pop(_controller.text.trim());
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: AnimatedSize(
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeOut,
        child: Container(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Handle
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: colorScheme.outlineVariant,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 20),
              // Title
              Row(
                children: [
                  if (widget.icon != null) ...[
                    Text(widget.icon!, style: const TextStyle(fontSize: 28)),
                    const SizedBox(width: 10),
                  ],
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.title,
                          style: theme.textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        if (widget.subtitle != null) ...[
                          const SizedBox(height: 4),
                          Text(
                            widget.subtitle!,
                            style: TextStyle(
                              fontSize: 12,
                              color: colorScheme.onSurface.withOpacity(0.6),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                  if (widget.coinsDisplay != null) ...[
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: colorScheme.primary.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        widget.coinsDisplay!,
                        style: TextStyle(
                          color: colorScheme.primary,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
              const SizedBox(height: 24),
              if (_mode == _GenericMode.choose) ...[
                // Option buttons
                _OptionButton(
                  icon: Icons.qr_code_scanner_rounded,
                  label: 'مسح QR Code',
                  sublabel: 'امسح الرمز',
                  onTap: _startScan,
                ),
                const SizedBox(height: 12),
                _OptionButton(
                  icon: Icons.keyboard_alt_outlined,
                  label: 'إدخال يدوي',
                  sublabel: 'اكتب الرمز يدويًا',
                  onTap: () => setState(() => _mode = _GenericMode.manual),
                ),
                const SizedBox(height: 8),
              ],
              if (_mode == _GenericMode.scan) ...[
                ClipRRect(
                  borderRadius: BorderRadius.circular(16),
                  child: SizedBox(
                    height: 260,
                    child: MobileScanner(
                      controller: _scannerController!,
                      onDetect: _onDetect,
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                TextButton.icon(
                  onPressed: () {
                    _scannerController?.dispose();
                    _scannerController = null;
                    setState(() => _mode = _GenericMode.choose);
                  },
                  icon: const Icon(Icons.arrow_back),
                  label: const Text('رجوع'),
                ),
              ],
              if (_mode == _GenericMode.manual) ...[
                Form(
                  key: _formKey,
                  child: TextFormField(
                    controller: _controller,
                    autofocus: true,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                    ),
                    decoration: InputDecoration(
                      hintText: 'الرمز القصير',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                    validator: (v) =>
                        (v == null || v.trim().isEmpty) ? 'أدخل الرمز' : null,
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    TextButton(
                      onPressed: () =>
                          setState(() => _mode = _GenericMode.choose),
                      child: const Text('رجوع'),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: FilledButton(
                        onPressed: _submitManual,
                        child: const Text('تأكيد'),
                      ),
                    ),
                  ],
                ),
              ],
              const SizedBox(height: 8),
            ],
          ),
        ),
      ),
    );
  }
}

class _OptionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final String sublabel;
  final VoidCallback onTap;

  const _OptionButton({
    required this.icon,
    required this.label,
    required this.sublabel,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          border: Border.all(color: colorScheme.outlineVariant),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: colorScheme.primary.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: colorScheme.primary, size: 24),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: const TextStyle(
                      color: teal900,
                      fontWeight: FontWeight.w700,
                      fontSize: 15,
                    ),
                  ),
                  Text(
                    sublabel,
                    style: TextStyle(
                      fontSize: 12,
                      color: colorScheme.onSurface.withOpacity(0.5),
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.arrow_forward_ios_rounded,
              size: 16,
              color: colorScheme.onSurface.withOpacity(0.4),
            ),
          ],
        ),
      ),
    );
  }
}
