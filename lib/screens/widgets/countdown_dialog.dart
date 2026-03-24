import 'dart:async';
import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';

class CountdownDialog extends StatefulWidget {
  final int seconds;
  final VoidCallback onSendNow;
  final VoidCallback onCancel;

  const CountdownDialog({
    super.key,
    required this.seconds,
    required this.onSendNow,
    required this.onCancel,
  });

  @override
  State<CountdownDialog> createState() => _CountdownDialogState();
}

class _CountdownDialogState extends State<CountdownDialog>
    with SingleTickerProviderStateMixin {
  late int _secondsLeft;
  Timer? _timer;
  late AnimationController _pulse;
  bool _fired = false;

  @override
  void initState() {
    super.initState();
    _secondsLeft = widget.seconds;
    _pulse = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    )..repeat(reverse: true);

    _timer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (!mounted) { t.cancel(); return; }
      setState(() => _secondsLeft--);
      if (_secondsLeft <= 0) {
        t.cancel();
        _doSend();
      }
    });
  }

  void _doSend() {
    if (_fired) return;
    _fired = true;
    _timer?.cancel();
    // Close dialog first, then fire callback after frame
    if (mounted) Navigator.of(context).pop();
    Future.microtask(() => widget.onSendNow());
  }

  void _doCancel() {
    if (_fired) return;
    _fired = true;
    _timer?.cancel();
    if (mounted) Navigator.of(context).pop();
    Future.microtask(() => widget.onCancel());
  }

  @override
  void dispose() {
    _timer?.cancel();
    _pulse.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: AppTheme.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: const BorderSide(color: AppTheme.red, width: 1.5),
      ),
      child: Padding(
        padding: const EdgeInsets.all(28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                color: AppTheme.redSoft,
                shape: BoxShape.circle,
                border: Border.all(color: AppTheme.red, width: 1.5),
              ),
              child: const Icon(Icons.warning_amber_rounded,
                  color: AppTheme.red, size: 30),
            ),
            const SizedBox(height: 16),
            const Text(
              'CRASH DETECTED',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w800,
                color: AppTheme.red,
                letterSpacing: 2,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'A sudden impact was detected.\nEmergency SMS will send automatically.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 13, color: AppTheme.muted, height: 1.5),
            ),
            const SizedBox(height: 24),
            AnimatedBuilder(
              animation: _pulse,
              builder: (_, __) => Transform.scale(
                scale: 1.0 + (_pulse.value * 0.05),
                child: Text(
                  '$_secondsLeft',
                  style: const TextStyle(
                    fontSize: 80,
                    fontWeight: FontWeight.w900,
                    color: AppTheme.red,
                    height: 1,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 4),
            const Text(
              'SECONDS UNTIL SMS SENDS',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: AppTheme.muted,
                letterSpacing: 1.2,
              ),
            ),
            const SizedBox(height: 28),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: _doCancel,
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: AppTheme.border),
                      foregroundColor: AppTheme.textPrimary,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10)),
                    ),
                    child: const Text("I'M OK",
                        style: TextStyle(fontWeight: FontWeight.bold,
                            letterSpacing: 1)),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: ElevatedButton(
                    onPressed: _doSend,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.red,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10)),
                    ),
                    child: const Text('SEND NOW',
                        style: TextStyle(fontWeight: FontWeight.bold,
                            letterSpacing: 1, color: Colors.white)),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
