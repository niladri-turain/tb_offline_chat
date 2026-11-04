import 'package:flutter_test/flutter_test.dart';

import 'package:tb_offline_chat/app.dart';

void main() {
  testWidgets('Welcome screen shows Get started', (tester) async {
    await tester.pumpWidget(const TbChatApp());
    await tester.pumpAndSettle();

    expect(find.text('TB Chat'), findsOneWidget);
    expect(find.text('Get started'), findsOneWidget);
  });
}
