import 'dart:convert';
import 'package:http/http.dart' as http;

class LicensingApi {
  static const defaultBaseUrl = 'https://expiry-tracker.lamin-ahmed12.workers.dev';
  final String baseUrl;
  const LicensingApi([this.baseUrl = defaultBaseUrl]);

  Uri _uri(String path) => Uri.parse(baseUrl.replaceAll(RegExp(r'/+$'), '') + path);

  Future<Map<String, dynamic>> activate({required String code, required String deviceId}) async {
    final response = await http.post(_uri('/v1/activate'), headers: const {'content-type': 'application/json'}, body: jsonEncode({'code': code, 'deviceId': deviceId})).timeout(const Duration(seconds: 15));
    final data = jsonDecode(response.body) as Map<String, dynamic>;
    if (response.statusCode < 200 || response.statusCode >= 300 || data['ok'] != true) throw LicensingException(_messageFor(data['error']?.toString()), statusCode: response.statusCode);
    return data;
  }

  Future<Map<String, dynamic>> checkLicense(String deviceId) async {
    final response = await http.get(_uri('/v1/license/${Uri.encodeComponent(deviceId)}')).timeout(const Duration(seconds: 15));
    final data = jsonDecode(response.body) as Map<String, dynamic>;
    if (response.statusCode < 200 || response.statusCode >= 300 || data['ok'] != true) throw LicensingException(_messageFor(data['error']?.toString()), statusCode: response.statusCode);
    return data;
  }

  String _messageFor(String? error) {
    switch (error) {
      case 'invalid_license': return 'كود التفعيل غير صحيح.';
      case 'device_mismatch': return 'هذا الترخيص مرتبط بجهاز آخر.';
      case 'license_expired': return 'انتهت صلاحية الترخيص.';
      case 'license_not_found': return 'لا يوجد ترخيص لهذا الجهاز.';
      default: return 'تعذر الاتصال بخادم الترخيص.';
    }
  }
}

class LicensingException implements Exception {
  final String message; final int statusCode;
  const LicensingException(this.message, {required this.statusCode});
  @override String toString() => message;
}