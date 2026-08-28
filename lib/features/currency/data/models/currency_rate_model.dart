import '../../../../core/constants/app_constants.dart';
import '../../../../core/error/exceptions.dart';

/// Represents the raw API response for a single date.
/// Holds only the 5 target currencies — the 200+ unrelated keys are discarded
/// at parse time and never reach the domain layer.
///
/// Rates are stored as-is from the API (EGP→X). Inversion to X→EGP is the
/// repository's responsibility, not this model's.
class CurrencyRateModel {
  const CurrencyRateModel({
    required this.date,
    required this.rates,
  });

  /// Date string as returned by the API. Example: "2026-08-28".
  final String date;

  /// Raw rates keyed by lowercase currency code. Example: {"usd": 0.019904522}.
  /// Contains exactly the [AppConstants.targetCurrencies] keys — no more.
  final Map<String, double> rates;

  /// Parses the API response or a cached copy of it.
  ///
  /// Throws [ParsingException] if:
  ///   - the "date" field is missing or not a String
  ///   - the "egp" map is missing or not an object
  ///   - any of the 5 target currency keys is absent or not a number
  factory CurrencyRateModel.fromJson(Map<String, dynamic> json) {
    final date = json['date'];
    if (date is! String) {
      throw const ParsingException(field: 'date');
    }

    final egpMap = json['egp'];
    if (egpMap is! Map<String, dynamic>) {
      throw const ParsingException(field: 'egp');
    }

    final rates = <String, double>{};
    for (final code in AppConstants.targetCurrencies) {
      final value = egpMap[code];
      if (value == null) {
        throw ParsingException(field: 'egp.$code');
      }
      if (value is! num) {
        throw ParsingException(
          field: 'egp.$code',
          message: 'Expected a number for egp.$code, got ${value.runtimeType}.',
        );
      }
      rates[code] = value.toDouble();
    }

    return CurrencyRateModel(date: date, rates: rates);
  }

  /// Serialises back to the same structure used by fromJson.
  /// The "egp" map contains only the 5 cached currencies, not the full 200+.
  Map<String, dynamic> toJson() => {
        'date': date,
        'egp': rates,
      };
}
