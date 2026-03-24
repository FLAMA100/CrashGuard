import 'package:background_sms/background_sms.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:flutter/foundation.dart';

class SmsService {
  /// Call once at startup to request SMS permission upfront
  static Future<bool> requestPermission() async {
    final status = await Permission.sms.request();
    debugPrint('SMS permission: $status');
    return status.isGranted;
  }

  static Future<bool> hasPermission() async {
    final status = await Permission.sms.status;
    return status.isGranted;
  }

  /// Sends silent emergency SMS to all contacts automatically
  static Future<void> sendEmergencyToAll({
    required List<String> phoneNumbers,
    required double lat,
    required double lng,
  }) async {
    // Ensure permission
    if (!await hasPermission()) {
      final granted = await requestPermission();
      if (!granted) {
        throw Exception(
          'SMS permission denied. Go to Settings → Apps → CrashGuard → Permissions and allow SMS.',
        );
      }
    }

    final message = _buildMessage(lat, lng);
    debugPrint('Sending SMS to $phoneNumbers');

    for (final rawNumber in phoneNumbers) {
      final number = rawNumber
          .replaceAll(' ', '')
          .replaceAll('-', '')
          .replaceAll('(', '')
          .replaceAll(')', '');

      try {
        final result = await BackgroundSms.sendMessage(
          phoneNumber: number,
          message: message,
          simSlot: 1,
        );
        debugPrint('SMS result for $number: $result');
      } catch (e) {
        debugPrint('SMS error for $number: $e');
        rethrow;
      }
    }
  }

  static String _buildMessage(double lat, double lng) {
    final mapsUrl = 'https://maps.google.com/?q=$lat,$lng';
    return 'EMERGENCY ALERT: I may have been in a car accident. '
        'My location: $mapsUrl '
        'Please call me or send help immediately. '
        '- Sent automatically by CrashGuard';
  }
}
