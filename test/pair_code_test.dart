import 'package:flutter_test/flutter_test.dart';
import 'package:tb_chat/services/nearby_scanner.dart';

void main() {
  test('pair code is 5 readable characters, even when the token has _ or -', () {
    for (final token in ['JH_XT', 'a-b_c', '12345', '____', 'x']) {
      expect(pairCode(token), matches(RegExp(r'^[A-HJ-NP-Z2-9]{5}$')));
    }
  });

  test('the same token gives the same code on both phones', () {
    expect(pairCode('JH_XT'), pairCode('JH_XT'));
  });

  test('different tokens give different codes', () {
    expect(pairCode('JH_XT'), isNot(pairCode('JH-XT')));
  });
}
