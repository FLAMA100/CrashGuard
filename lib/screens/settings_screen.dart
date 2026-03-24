import 'package:flutter/material.dart';
import '../services/settings_service.dart';
import '../theme/app_theme.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  double _spikeThreshold = 15.0;
  int    _countdownSecs  = 30;
  bool   _loaded = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final spike    = await SettingsService.getSpikeThreshold();
    final countdown = await SettingsService.getCountdownSeconds();
    if (mounted) {
      setState(() {
        _spikeThreshold = spike;
        _countdownSecs  = countdown;
        _loaded = true;
      });
    }
  }

  Future<void> _save() async {
    await SettingsService.setSpikeThreshold(_spikeThreshold);
    await SettingsService.setCountdownSeconds(_countdownSecs);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('Settings saved'),
        backgroundColor: AppTheme.green,
        duration: Duration(seconds: 2),
      ));
      Navigator.pop(context);
    }
  }

  Widget _sectionLabel(String text) => Padding(
        padding: const EdgeInsets.only(bottom: 8, top: 4),
        child: Text(text,
            style: const TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                letterSpacing: 1.5,
                color: AppTheme.muted)),
      );

  Widget _card({required Widget child}) => Container(
        margin: const EdgeInsets.only(bottom: 16),
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: AppTheme.card,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppTheme.border),
        ),
        child: child,
      );

  @override
  Widget build(BuildContext context) {
    if (!_loaded) {
      return const Scaffold(
        backgroundColor: AppTheme.bg,
        body: Center(child: CircularProgressIndicator(color: AppTheme.red)),
      );
    }

    return Scaffold(
      backgroundColor: AppTheme.bg,
      appBar: AppBar(
        title: const Text('Settings'),
        backgroundColor: AppTheme.bg,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [

            // ── Crash sensitivity ──────────────────────────────────────
            _sectionLabel('CRASH SENSITIVITY'),
            _card(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Impact Threshold (spike m/s²)',
                          style: TextStyle(
                              color: AppTheme.textPrimary,
                              fontWeight: FontWeight.w600)),
                      Text(
                        _spikeThreshold.toStringAsFixed(0),
                        style: const TextStyle(
                            color: AppTheme.red,
                            fontWeight: FontWeight.w800,
                            fontSize: 16),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    'Lower = more sensitive. '
                    '10–15 triggers on a firm shake. '
                    '20+ needs a hard impact.',
                    style: TextStyle(
                        fontSize: 12, color: AppTheme.muted, height: 1.4),
                  ),
                  Slider(
                    value: _spikeThreshold,
                    min: 8,
                    max: 35,
                    divisions: 27,
                    activeColor: AppTheme.red,
                    inactiveColor: AppTheme.border,
                    onChanged: (v) => setState(() => _spikeThreshold = v),
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: const [
                      Text('8  Very sensitive',
                          style: TextStyle(
                              fontSize: 10, color: AppTheme.muted)),
                      Text('35  Hard impact only',
                          style: TextStyle(
                              fontSize: 10, color: AppTheme.muted)),
                    ],
                  ),
                ],
              ),
            ),

            // ── Countdown duration ─────────────────────────────────────
            _sectionLabel('COUNTDOWN DURATION'),
            _card(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Seconds before SMS sends',
                          style: TextStyle(
                              color: AppTheme.textPrimary,
                              fontWeight: FontWeight.w600)),
                      Text(
                        '$_countdownSecs s',
                        style: const TextStyle(
                            color: AppTheme.red,
                            fontWeight: FontWeight.w800,
                            fontSize: 16),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    'Time you have to cancel after a crash is detected. '
                    'Set lower for faster alerts, higher to reduce false sends.',
                    style: TextStyle(
                        fontSize: 12, color: AppTheme.muted, height: 1.4),
                  ),
                  Slider(
                    value: _countdownSecs.toDouble(),
                    min: 5,
                    max: 60,
                    divisions: 11,
                    activeColor: AppTheme.red,
                    inactiveColor: AppTheme.border,
                    onChanged: (v) =>
                        setState(() => _countdownSecs = v.toInt()),
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: const [
                      Text('5 s  Fast',
                          style: TextStyle(
                              fontSize: 10, color: AppTheme.muted)),
                      Text('60 s  Slow',
                          style: TextStyle(
                              fontSize: 10, color: AppTheme.muted)),
                    ],
                  ),
                ],
              ),
            ),

            // ── Recommended for demo ───────────────────────────────────
            _sectionLabel('QUICK PRESETS'),
            _card(
              child: Column(
                children: [
                  _presetRow(
                    label: 'Presentation / Demo',
                    desc: 'Threshold 12, Countdown 10s — triggers on firm shake',
                    onTap: () => setState(() {
                      _spikeThreshold = 12;
                      _countdownSecs  = 10;
                    }),
                  ),
                  const Divider(color: AppTheme.border, height: 20),
                  _presetRow(
                    label: 'Daily Use',
                    desc: 'Threshold 18, Countdown 30s — real crash only',
                    onTap: () => setState(() {
                      _spikeThreshold = 18;
                      _countdownSecs  = 30;
                    }),
                  ),
                  const Divider(color: AppTheme.border, height: 20),
                  _presetRow(
                    label: 'High Sensitivity',
                    desc: 'Threshold 10, Countdown 20s — very responsive',
                    onTap: () => setState(() {
                      _spikeThreshold = 10;
                      _countdownSecs  = 20;
                    }),
                  ),
                ],
              ),
            ),

            // ── Save button ────────────────────────────────────────────
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _save,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.red,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                ),
                child: const Text('SAVE SETTINGS',
                    style: TextStyle(
                        fontWeight: FontWeight.w800,
                        letterSpacing: 1.5,
                        fontSize: 14)),
              ),
            ),

            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _presetRow({
    required String label,
    required String desc,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label,
                    style: const TextStyle(
                        color: AppTheme.textPrimary,
                        fontWeight: FontWeight.w600)),
                const SizedBox(height: 2),
                Text(desc,
                    style: const TextStyle(
                        fontSize: 12, color: AppTheme.muted)),
              ],
            ),
          ),
          const Icon(Icons.chevron_right, color: AppTheme.muted, size: 20),
        ],
      ),
    );
  }
}
