import 'package:flutter_test/flutter_test.dart';
import 'package:labaku/main.dart';

void main() {
  testWidgets('App renders without crashing', (WidgetTester tester) async {
    await tester.pumpWidget(const LabaKuApp());
    expect(find.text('Beranda'), findsOneWidget);
  });
}
