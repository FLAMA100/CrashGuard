import 'package:shared_preferences/shared_preferences.dart';

class SettingsService {
  static const _keySpike     = 'spike_threshold';
  static const _keyCountdown = 'countdown_seconds';

  static Future<double> getSpikeThreshold() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getDouble(_keySpike) ?? 15.0;
  }

  static Future<void> setSpikeThreshold(double value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble(_keySpike, value);
  }

  static Future<int> getCountdownSeconds() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt(_keyCountdown) ?? 30;
  }

  static Future<void> setCountdownSeconds(int value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_keyCountdown, value);
  }
}
