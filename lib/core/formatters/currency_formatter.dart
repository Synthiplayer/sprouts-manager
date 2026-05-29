import 'package:intl/intl.dart';

final NumberFormat _euroCurrencyFormat = NumberFormat.currency(
  locale: 'de_DE',
  symbol: '',
  decimalDigits: 2,
);

String formatEuro(double value) {
  final formatted = _euroCurrencyFormat.format(value).trim();
  return '$formatted EUR';
}

double parseEuroInput(String raw) {
  var normalized = raw.trim();
  if (normalized.isEmpty) {
    return 0;
  }

  normalized = normalized.replaceAll('EUR', '').replaceAll('€', '').trim();

  if (normalized.contains(',') && normalized.contains('.')) {
    normalized = normalized.replaceAll('.', '').replaceAll(',', '.');
  } else if (normalized.contains(',')) {
    normalized = normalized.replaceAll(',', '.');
  }

  return double.tryParse(normalized) ?? 0;
}
