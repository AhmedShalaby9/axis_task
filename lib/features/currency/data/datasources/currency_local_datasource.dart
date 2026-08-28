import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../../../../core/error/exceptions.dart';
import '../models/currency_rate_model.dart';

abstract interface class CurrencyLocalDatasource {
  /// Persists [model] under a date-scoped key.
  /// Overwrites any previously cached value for that date.
  Future<void> cacheRates(CurrencyRateModel model);

  /// Returns the cached [CurrencyRateModel] for [date].
  ///
  /// Throws [CacheException] if no entry exists for that date or if the
  /// stored value cannot be decoded (e.g. corrupted storage).
  Future<CurrencyRateModel> getCachedRates(DateTime date);
}

class CurrencyLocalDatasourceImpl implements CurrencyLocalDatasource {
  CurrencyLocalDatasourceImpl(this._prefs);

  final SharedPreferences _prefs;

  static const _keyPrefix = 'rates_';

  @override
  Future<void> cacheRates(CurrencyRateModel model) async {
    await _prefs.setString(
      '$_keyPrefix${model.date}',
      jsonEncode(model.toJson()),
    );
  }

  @override
  Future<CurrencyRateModel> getCachedRates(DateTime date) {
    final key = '$_keyPrefix${_formatDate(date)}';
    final raw = _prefs.getString(key);

    if (raw == null) {
      throw const CacheException(
        message: 'No cached rates found for this date.',
      );
    }

    try {
      final json = jsonDecode(raw) as Map<String, dynamic>;
      return Future.value(CurrencyRateModel.fromJson(json));
    } catch (_) {
      // Covers FormatException from jsonDecode and ParsingException from
      // fromJson — both indicate the stored value is unusable.
      throw const CacheException(
        message: 'Cached rate data is corrupt and cannot be read.',
      );
    }
  }

  String _formatDate(DateTime date) =>
      '${date.year.toString().padLeft(4, '0')}-'
      '${date.month.toString().padLeft(2, '0')}-'
      '${date.day.toString().padLeft(2, '0')}';
}
