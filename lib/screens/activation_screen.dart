import 'package:flutter/material.dart';
import '../services/license_service.dart';

class ActivationScreen extends StatefulWidget {
  final VoidCallback onActivated;
  const ActivationScreen({super.key, required this.onActivated});
  @override State<ActivationScreen> createState() => _ActivationScreenState();
}

class _ActivationScreenState extends State<ActivationScreen> {
  final code = TextEditingController();
  String? error;
  bool loading = false;

  Future<void> activate() async {
    final value = code.text.trim().toUpperCase();
    if (value.isEmpty) { setState(() => error = 'أدخل كود التفعيل'); return; }

    setState(() { loading = true; error = null; });
    String? plan;
    if (value.startsWith('AD6-')) plan = '6_months';
    if (value.startsWith('AD12-')) plan = 'year';
    if (value.startsWith('ADP-')) plan = 'permanent';

    if (plan == null) {
      setState(() { loading = false; error = 'كود غير صالح.'; });
      return;
    }

    await LicenseService.activateLocal(value, plan);
    if (!mounted) return;
    widget.onActivated();
    Navigator.pop(context);
  }

  @override Widget build(BuildContext context) => Directionality(
    textDirection: TextDirection.rtl,
    child: Scaffold(
      appBar: AppBar(title: const Text('تفعيل ADREEMK')),
      body: ListView(padding: const EdgeInsets.all(22), children: [
        const Icon(Icons.verified_user_outlined, size: 64),
        const SizedBox(height: 18),
        const Text('أدخل كود التفعيل', style: TextStyle(fontSize: 27, fontWeight: FontWeight.w900)),
        const SizedBox(height: 8),
        const Text('سيتم ربط الترخيص بالجهاز عند التحقق من الخادم.'),
        const SizedBox(height: 24),
        TextField(controller: code, textCapitalization: TextCapitalization.characters,
          decoration: InputDecoration(labelText: 'كود التفعيل', hintText: 'AD6-XXXXXXXX', errorText: error,
            prefixIcon: const Icon(Icons.key), border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)))),
        const SizedBox(height: 18),
        FilledButton(onPressed: loading ? null : activate, child: loading ? const CircularProgressIndicator() : const Text('تفعيل الآن')),
      ]),
    ),
  );
}
