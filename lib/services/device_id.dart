import 'dart:math';
import 'package:shared_preferences/shared_preferences.dart';

class DeviceIdService {
  static const key = 'adreemk_device_id_v1';

  static Future<String> get() async {
    final p = await SharedPreferences.getInstance();
    final old = p.getString(key);
    if (old != null && old.isNotEmpty) return old;
    final r = Random.secure();
    final id = List.generate(24, (_) => r.nextInt(16).toRadixString(16)).join();
    await p.setString(key, id);
    return id;
  }
}
