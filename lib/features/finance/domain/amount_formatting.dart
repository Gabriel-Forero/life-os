import 'package:intl/intl.dart';

const _noDecimalCurrencies = {'COP', 'JPY', 'KRW', 'CLP', 'VND', 'HUF'};

const _currencySymbols = {
  'COP': '\$',
  'USD': '\$',
  'EUR': '€',
  'GBP': '£',
  'MXN': '\$',
  'ARS': '\$',
  'PEN': 'S/',
  'CLP': '\$',
  'BRL': 'R\$',
  'CAD': 'CA\$',
  'JPY': '¥',
};

extension AmountFormatting on int {
  String toCurrency(String currencyCode) {
    final hasDecimals = !_noDecimalCurrencies.contains(currencyCode);
    final symbol = _currencySymbols[currencyCode] ?? currencyCode;

    if (hasDecimals) {
      final value = this / 100;
      final format = NumberFormat('#,##0.00', 'en_US');
      return '$symbol${format.format(value)}';
    } else {
      final format = NumberFormat('#,##0', 'es_CO');
      return '$symbol${format.format(this)}';
    }
  }
}
