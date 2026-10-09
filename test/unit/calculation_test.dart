import 'package:flutter_test/flutter_test.dart';

num? parseTradeNumber(dynamic raw) {
  if (raw == null) return null;
  if (raw is num) return raw;
  final str = raw.toString().trim().replaceAll(',', '.');
  return num.tryParse(str);
}

Map<String, double> calculateColumnStats(List<Map<String, dynamic>> rows, String columnId) {
  double sum = 0.0;
  int count = 0;
  for (final row in rows) {
    final val = parseTradeNumber(row[columnId]);
    if (val != null) {
      sum += val.toDouble();
      count++;
    }
  }
  final average = count > 0 ? sum / count : 0.0;
  return {'sum': sum, 'average': average, 'count': count.toDouble()};
}

void main() {
  group('Calculation & Parsing Tests', () {
    test('parseTradeNumber gère les différents formats décimaux et valeurs nulles', () {
      expect(parseTradeNumber(100), 100);
      expect(parseTradeNumber(12.5), 12.5);
      expect(parseTradeNumber('12.5'), 12.5);
      expect(parseTradeNumber('12,5'), 12.5);
      expect(parseTradeNumber('-45,2'), -45.2);
      expect(parseTradeNumber('  30.0  '), 30.0);
      expect(parseTradeNumber(''), null);
      expect(parseTradeNumber(null), null);
      expect(parseTradeNumber('invalid'), null);
    });

    test('calculateColumnStats calcule correctement la somme et la moyenne sur une série de trades', () {
      final trades = [
        {'pnl': '150.50'},
        {'pnl': '-50,00'},
        {'pnl': 200},
        {'pnl': null},
        {'pnl': '0'},
      ];

      final stats = calculateColumnStats(trades, 'pnl');
      expect(stats['sum'], 300.50);
      expect(stats['count'], 4.0);
      expect(stats['average'], 300.50 / 4.0);
    });

    test('calculateColumnStats gère une liste vide sans division par zéro', () {
      final stats = calculateColumnStats([], 'pnl');
      expect(stats['sum'], 0.0);
      expect(stats['average'], 0.0);
      expect(stats['count'], 0.0);
    });
  });
}
