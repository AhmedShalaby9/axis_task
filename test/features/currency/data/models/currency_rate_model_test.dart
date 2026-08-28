import 'package:flutter_test/flutter_test.dart';

import 'package:axis_task/core/error/exceptions.dart';
import 'package:axis_task/features/currency/data/models/currency_rate_model.dart';

void main() {
  group('CurrencyRateModel.fromJson', () {
    test('parses real API shape and keeps only the 5 target currencies', () {
      final json = {
        'date': '2026-08-28',
        'egp': {
          'usd': 0.019904522,
          'eur': 0.017091341,
          'gbp': 0.014646497,
          'sar': 0.074641957,
          'jpy': 3.17830652,
          'aud': 0.031234, // extra key — must be discarded
          'cad': 0.027891,
          'chf': 0.022100,
        },
      };

      final model = CurrencyRateModel.fromJson(json);

      expect(model.date, '2026-08-28');
      expect(model.rates.keys, containsAll(['usd', 'eur', 'gbp', 'sar', 'jpy']));
      expect(model.rates.containsKey('aud'), isFalse);
      expect(model.rates.containsKey('cad'), isFalse);
      expect(model.rates.length, 5);
      expect(model.rates['usd'], 0.019904522);
    });

    test('missing target currency key throws ParsingException naming the field', () {
      final json = {
        'date': '2026-08-28',
        'egp': {
          'usd': 0.019904522,
          // 'eur' deliberately absent
          'gbp': 0.014646497,
          'sar': 0.074641957,
          'jpy': 3.17830652,
        },
      };

      expect(
        () => CurrencyRateModel.fromJson(json),
        throwsA(
          isA<ParsingException>().having((e) => e.field, 'field', 'egp.eur'),
        ),
      );
    });

    test('missing date field throws ParsingException', () {
      final json = {
        'egp': {
          'usd': 0.019904522,
          'eur': 0.017091341,
          'gbp': 0.014646497,
          'sar': 0.074641957,
          'jpy': 3.17830652,
        },
      };

      expect(
        () => CurrencyRateModel.fromJson(json),
        throwsA(isA<ParsingException>().having((e) => e.field, 'field', 'date')),
      );
    });

    test('missing egp map throws ParsingException', () {
      final json = <String, dynamic>{'date': '2026-08-28'};

      expect(
        () => CurrencyRateModel.fromJson(json),
        throwsA(isA<ParsingException>().having((e) => e.field, 'field', 'egp')),
      );
    });
  });

  group('toJson / fromJson round-trip', () {
    test('serialises to the same structure fromJson consumes, producing equal model', () {
      final original = CurrencyRateModel(
        date: '2026-08-28',
        rates: {
          'usd': 0.019904522,
          'eur': 0.017091341,
          'gbp': 0.014646497,
          'sar': 0.074641957,
          'jpy': 3.17830652,
        },
      );

      final json = original.toJson();
      final roundTripped = CurrencyRateModel.fromJson(json);

      expect(roundTripped.date, original.date);
      expect(roundTripped.rates, original.rates);
    });

    test('toJson omits the 200+ unrelated API keys, retaining only 5 targets', () {
      final model = CurrencyRateModel(
        date: '2026-08-28',
        rates: {'usd': 0.019, 'eur': 0.017, 'gbp': 0.014, 'sar': 0.074, 'jpy': 3.17},
      );

      final json = model.toJson();
      final egpMap = json['egp'] as Map<String, dynamic>;

      expect(egpMap.length, 5);
    });
  });
}
