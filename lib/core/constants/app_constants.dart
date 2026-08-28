abstract final class AppConstants {
  // ── Currency config ────────────────────────────────────────────────────────

  static const String baseCurrency = 'egp';

  /// The 5 target currencies, lowercase — matches API response keys exactly.
  static const List<String> targetCurrencies = ['usd', 'eur', 'gbp', 'sar', 'jpy'];

  /// Human-readable display names keyed by uppercase ISO 4217 code.
  static const Map<String, String> currencyNames = {
    'USD': 'US Dollar',
    'EUR': 'Euro',
    'GBP': 'British Pound',
    'SAR': 'Saudi Riyal',
    'JPY': 'Japanese Yen',
  };

  // ── URL construction ───────────────────────────────────────────────────────
  //
  // The date is a SUBDOMAIN, not a path segment:
  //   https://{YYYY-MM-DD}.currency-api.pages.dev/v1/currencies/egp.json

  static const String _apiHost = 'currency-api.pages.dev';
  static const String _apiPath = '/v1/currencies/$baseCurrency.json';

  /// Returns the full URL for a specific date's rates.
  ///
  /// Example: ratesUrl(DateTime(2026, 8, 28))
  ///   → https://2026-08-28.currency-api.pages.dev/v1/currencies/egp.json
  static String ratesUrl(DateTime date) {
    final subdomain = _formatDate(date);
    return 'https://$subdomain.$_apiHost$_apiPath';
  }

  // ── Helpers ────────────────────────────────────────────────────────────────

  static String _formatDate(DateTime date) =>
      '${date.year.toString().padLeft(4, '0')}-'
      '${date.month.toString().padLeft(2, '0')}-'
      '${date.day.toString().padLeft(2, '0')}';
}
