import 'package:flutter_test/flutter_test.dart';
import 'package:life_os/features/finance/domain/amount_formatting.dart';

void main() {
  group('AmountFormatting extension', () {
    test('formats COP without decimals', () {
      expect(3500000.toCurrency('COP'), '\$3.500.000');
    });

    test('formats COP small amount', () {
      expect(25000.toCurrency('COP'), '\$25.000');
    });

    test('formats COP zero', () {
      expect(0.toCurrency('COP'), '\$0');
    });

    test('formats USD with decimals', () {
      expect(1050.toCurrency('USD'), '\$10.50');
    });

    test('formats USD whole dollar', () {
      expect(5000.toCurrency('USD'), '\$50.00');
    });

    test('formats EUR with decimals', () {
      expect(2599.toCurrency('EUR'), '€25.99');
    });
  });
}
