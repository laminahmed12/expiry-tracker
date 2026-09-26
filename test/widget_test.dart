import 'package:flutter_test/flutter_test.dart';
import 'package:adreemk_expiry/main.dart';

void main() {
  testWidgets('ADREEMK app starts', (tester) async {
    await tester.pumpWidget(const AdreemkApp());
    expect(find.text('ADREEMK'), findsOneWidget);
  });
}
