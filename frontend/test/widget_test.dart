import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:student_career_app/app.dart';

void main() {
  testWidgets('App initialization smoke test', (WidgetTester tester) async {
    SharedPreferences.setMockInitialValues({});
    await tester.pumpWidget(const StudentCareerApp());
    expect(find.byType(StudentCareerApp), findsOneWidget);
  });
}
