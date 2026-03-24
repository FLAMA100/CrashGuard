import 'dart:async';
import 'package:flutter/material.dart';
import '../services/crash_detection_service.dart';
import '../services/location_service.dart';
import '../services/sms_service.dart';
import '../services/contacts_storage_service.dart';
import '../services/settings_service.dart';
import '../theme/app_theme.dart';
import 'widgets/countdown_dialog.dart';
import 'contacts_screen.dart';
import 'settings_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen>
    with SingleTickerProviderStateMixin {
  late CrashDetectionService _crashService;
  late AnimationController _pulseController;
  late Animation<double> _pulseAnim;

  bool _isMonitoring = false;
  bool _showingAlert = false;
  int _alertsSent = 0;

  double _accelMag = 0.0;
  double _gyroMag = 0.0;
  int _countdownSecs = 30;

  @override
  void initState() {
    super.initState();

    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );
    _pulseAnim = Tween<double>(begin: 1.0, end: 1.08).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    _crashService = CrashDetectionService(
      onCrashDetected: _handleCrashDetected,
      onSensorUpdate: (accel, gyro) {
        if (mounted) {
          setState(() {
            _accelMag = accel;
            _gyroMag = gyro;
          });
        }
      },
    );

    _loadSettings();
    SmsService.requestPermission();
  }

  Future<void> _loadSettings() async {
    final spike = await SettingsService.getSpikeThreshold();
    final countdown = await SettingsService.getCountdownSeconds();
    if (mounted) {
      setState(() => _countdownSecs = countdown);
      _crashService.spikeThreshold = spike;
    }
  }

  void _toggleMonitoring() {
    setState(() {
      _isMonitoring = !_isMonitoring;
    });
    if (_isMonitoring) {
      _crashService.start();
      _pulseController.repeat(reverse: true);
    } else {
      _crashService.stop();
      _pulseController.stop();
      _pulseController.reset();
    }
  }

  Future<void> _handleCrashDetected() async {
    if (_showingAlert || !mounted) return;
    _showingAlert = true;

    await _loadSettings(); // refresh countdown duration

    if (!mounted) return;
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => CountdownDialog(
        seconds: _countdownSecs,
        onSendNow: () {
          _showingAlert = false;
          _sendEmergencyAlert();
        },
        onCancel: () {
          _showingAlert = false;
        },
      ),
    );
  }

  Future<void> _sendEmergencyAlert() async {
    final contacts = await ContactsStorageService.loadContacts();

    if (contacts.isEmpty) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('No emergency contacts set. Add contacts in the Contacts tab.'),
          backgroundColor: Colors.orange,
          duration: Duration(seconds: 4),
        ));
      }
      return;
    }

    final position = await LocationService.getCurrentLocation();
    final lat = position?.latitude ?? 0.0;
    final lng = position?.longitude ?? 0.0;
    final phones = contacts.map((c) => c.phone).toList();

    try {
      await SmsService.sendEmergencyToAll(
        phoneNumbers: phones,
        lat: lat,
        lng: lng,
      );
      if (mounted) {
        setState(() => _alertsSent++);
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('✓ Emergency SMS sent to ${contacts.length} contact(s)'),
          backgroundColor: AppTheme.green,
          duration: const Duration(seconds: 4),
        ));
      }
    } catch (e) {
      debugPrint('SMS failed: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('SMS failed: $e'),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 6),
        ));
      }
    }
  }

  @override
  void dispose() {
    _crashService.dispose();
    _pulseController.dispose();
    super.dispose();
  }

  // ── Helpers ────────────────────────────────────────────────────────────────

  double _barFraction(double value, double max) =>
      (value / max).clamp(0.0, 1.0);

  Widget _sensorRow(String label, double value, double maxVal,
      {required Color color}) {
    final fraction = _barFraction(value, maxVal);
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          SizedBox(
            width: 80,
            child: Text(label,
                style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.muted,
                    letterSpacing: .5)),
          ),
          Expanded(
            child: Container(
              height: 6,
              decoration: BoxDecoration(
                color: AppTheme.border,
                borderRadius: BorderRadius.circular(3),
              ),
              child: FractionallySizedBox(
                alignment: Alignment.centerLeft,
                widthFactor: fraction,
                child: Container(
                  decoration: BoxDecoration(
                    color: color,
                    borderRadius: BorderRadius.circular(3),
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(width: 10),
          SizedBox(
            width: 44,
            child: Text(
              value.toStringAsFixed(1),
              textAlign: TextAlign.right,
              style: TextStyle(
                  fontSize: 11,
                  color: color,
                  fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }

  Widget _statCard(String label, String value, IconData icon) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 10),
        decoration: BoxDecoration(
          color: AppTheme.card,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppTheme.border),
        ),
        child: Column(
          children: [
            Icon(icon, color: AppTheme.muted, size: 18),
            const SizedBox(height: 6),
            Text(value,
                style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    color: AppTheme.textPrimary)),
            const SizedBox(height: 2),
            Text(label,
                textAlign: TextAlign.center,
                style: const TextStyle(
                    fontSize: 10, color: AppTheme.muted, letterSpacing: .4)),
          ],
        ),
      ),
    );
  }

  // ── Build ──────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final gForce = _accelMag / 9.81;

    return Scaffold(
      backgroundColor: AppTheme.bg,
      appBar: AppBar(
        backgroundColor: AppTheme.bg,
        title: Row(
          children: [
            Container(
              width: 8, height: 8,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: _isMonitoring ? AppTheme.green : AppTheme.muted,
              ),
            ),
            const SizedBox(width: 8),
            const Text('CRASHGUARD',
                style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 2.5,
                    color: AppTheme.textPrimary)),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.contacts_outlined),
            color: AppTheme.muted,
            tooltip: 'Contacts',
            onPressed: () => Navigator.push(context,
                MaterialPageRoute(builder: (_) => const ContactsScreen())),
          ),
          IconButton(
            icon: const Icon(Icons.settings_outlined),
            color: AppTheme.muted,
            tooltip: 'Settings',
            onPressed: () async {
              await Navigator.push(context,
                  MaterialPageRoute(builder: (_) => const SettingsScreen()));
              _loadSettings(); // reload after returning
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
        child: Column(
          children: [

            // ── Big shield button ─────────────────────────────────────────
            const SizedBox(height: 16),
            GestureDetector(
              onTap: _toggleMonitoring,
              child: AnimatedBuilder(
                animation: _pulseAnim,
                builder: (_, child) => Transform.scale(
                  scale: _isMonitoring ? _pulseAnim.value : 1.0,
                  child: child,
                ),
                child: Container(
                  width: 170,
                  height: 170,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: _isMonitoring
                        ? AppTheme.redSoft
                        : AppTheme.card,
                    border: Border.all(
                      color: _isMonitoring ? AppTheme.red : AppTheme.border,
                      width: 2.5,
                    ),
                    boxShadow: _isMonitoring
                        ? [
                            BoxShadow(
                              color: AppTheme.red.withOpacity(0.25),
                              blurRadius: 30,
                              spreadRadius: 5,
                            )
                          ]
                        : [],
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        _isMonitoring ? Icons.shield : Icons.shield_outlined,
                        size: 52,
                        color: _isMonitoring ? AppTheme.red : AppTheme.muted,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        _isMonitoring ? 'STOP' : 'START',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 3,
                          color: _isMonitoring ? AppTheme.red : AppTheme.muted,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),

            const SizedBox(height: 12),
            Text(
              _isMonitoring ? 'MONITORING ACTIVE' : 'TAP SHIELD TO START',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                letterSpacing: 2,
                color: _isMonitoring ? AppTheme.red : AppTheme.muted,
              ),
            ),

            const SizedBox(height: 28),

            // ── Sensor panel ──────────────────────────────────────────────
            Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: AppTheme.card,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: AppTheme.border),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.sensors, size: 14, color: AppTheme.muted),
                      const SizedBox(width: 6),
                      const Text('LIVE SENSORS',
                          style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 1.5,
                              color: AppTheme.muted)),
                      const Spacer(),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: _isMonitoring
                              ? AppTheme.green.withOpacity(0.15)
                              : AppTheme.border,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          _isMonitoring ? 'LIVE' : 'IDLE',
                          style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w700,
                              color: _isMonitoring
                                  ? AppTheme.green
                                  : AppTheme.muted),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  _sensorRow('ACCEL MAG', _accelMag, 50,
                      color: AppTheme.red),
                  _sensorRow('G-FORCE', gForce, 5,
                      color: Colors.orangeAccent),
                  _sensorRow('GYRO', _gyroMag, 20,
                      color: AppTheme.green),
                ],
              ),
            ),

            const SizedBox(height: 16),

            // ── Stats row ─────────────────────────────────────────────────
            Row(
              children: [
                _statCard('ALERTS\nSENT', '$_alertsSent',
                    Icons.send_outlined),
                const SizedBox(width: 10),
                _statCard('THRESHOLD\nm/s²',
                    _crashService.spikeThreshold.toStringAsFixed(0),
                    Icons.speed_outlined),
                const SizedBox(width: 10),
                _statCard('COUNTDOWN\nSECS', '$_countdownSecs',
                    Icons.timer_outlined),
              ],
            ),

            const SizedBox(height: 20),

            // ── Info card ─────────────────────────────────────────────────
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppTheme.card,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: AppTheme.border),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AppTheme.redSoft,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(Icons.info_outline,
                        color: AppTheme.red, size: 18),
                  ),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Text(
                      'On crash detection, a 30-second countdown starts. '
                      'SMS sends automatically with your GPS location. '
                      'Tap "I\'M OK" to cancel if it\'s a false alarm.',
                      style: TextStyle(
                          fontSize: 12,
                          color: AppTheme.muted,
                          height: 1.5),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }
}
