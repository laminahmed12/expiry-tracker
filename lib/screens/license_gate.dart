import 'package:flutter/material.dart';
import '../services/license_service.dart';
import 'activation_screen.dart';

class LicenseGate extends StatefulWidget {
  final Widget child;
  const LicenseGate({super.key, required this.child});
  @override State<LicenseGate> createState() => _LicenseGateState();
}

class _LicenseGateState extends State<LicenseGate> {
  LicenseState? state;
  @override void initState() { super.initState(); load(); }
  Future<void> load() async {
    final s = await LicenseService.status();
    if (mounted) setState(() => state = s);
  }
  void openActivation() {
    Navigator.push(context, MaterialPageRoute(builder: (_) => ActivationScreen(onActivated: load)));
  }
  @override Widget build(BuildContext context) {
    if (state == null) return const Scaffold(body: Center(child: CircularProgressIndicator()));
    if (!state!.active) return ExpiredScreen(onActivated: load);
    return Stack(children: [
      widget.child,
      if (state!.trial)
        Positioned(
          top: 4, left: 12, right: 12,
          child: SafeArea(
            bottom: false,
            child: Align(
              alignment: Alignment.topCenter,
              child: Material(
                color: Colors.transparent,
                child: Container(
                  height: 44,
                  constraints: const BoxConstraints(maxWidth: 330),
                  padding: const EdgeInsets.symmetric(horizontal: 10),
                  decoration: BoxDecoration(
                    color: const Color(0xff174d3a),
                    borderRadius: BorderRadius.circular(22),
                    boxShadow: const [BoxShadow(blurRadius: 8, offset: Offset(0, 3), color: Color(0x22000000))],
                  ),
                  child: Row(children: [
                    const Icon(Icons.timer_outlined, color: Colors.white, size: 19),
                    const SizedBox(width: 6),
                    Expanded(
                      child: FittedBox(
                        fit: BoxFit.scaleDown,
                        alignment: Alignment.centerRight,
                        child: Text(
                          'التجربة: \${state!.daysLeft} أيام',
                          maxLines: 1, softWrap: false,
                          style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w700),
                        ),
                      ),
                    ),
                    const SizedBox(width: 4),
                    TextButton(
                      onPressed: openActivation,
                      style: TextButton.styleFrom(minimumSize: const Size(54, 36), padding: const EdgeInsets.symmetric(horizontal: 8), tapTargetSize: MaterialTapTargetSize.shrinkWrap),
                      child: const Text('تفعيل', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w800)),
                    ),
                  ]),
                ),
              ),
            ),
          ),
        ),
    ]);
  }
}

class ExpiredScreen extends StatelessWidget {
  final VoidCallback onActivated;
  const ExpiredScreen({super.key, required this.onActivated});
  @override Widget build(BuildContext context) => Scaffold(
    body: SafeArea(child: Center(child: Padding(
      padding: const EdgeInsets.all(28),
      child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
        const Icon(Icons.lock_clock_outlined, size: 72),
        const SizedBox(height: 20),
        const Text('انتهت الفترة التجريبية', style: TextStyle(fontSize: 26, fontWeight: FontWeight.w900)),
        const SizedBox(height: 10),
        const Text('بياناتك محفوظة على الجهاز. فعّل التطبيق للعودة إلى الاستخدام الكامل.', textAlign: TextAlign.center),
        const SizedBox(height: 28),
        FilledButton.icon(
          onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => ActivationScreen(onActivated: onActivated))),
          icon: const Icon(Icons.key_outlined), label: const Text('تفعيل التطبيق'),
        ),
      ]),
    )),
  );
}