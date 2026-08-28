import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;

import '../../../../core/constants/app_constants.dart';
import '../../../../core/error/exceptions.dart';
import '../models/currency_rate_model.dart';

abstract interface class CurrencyRemoteDatasource {
  /// Fetches the full EGP rate snapshot for [date] from the remote API.
  ///
  /// Throws:
  ///   [NetworkException]  — no connection or request timed out
  ///   [ServerException]   — non-200 HTTP status
  ///   [ParsingException]  — malformed JSON or missing expected key
  Future<CurrencyRateModel> getRatesForDate(DateTime date);
}

class CurrencyRemoteDatasourceImpl implements CurrencyRemoteDatasource {
  CurrencyRemoteDatasourceImpl(this._client);

  final http.Client _client;

  static const _timeout = Duration(seconds: 10);

  @override
  Future<CurrencyRateModel> getRatesForDate(DateTime date) async {
    final url = Uri.parse(AppConstants.ratesUrl(date));

    final http.Response response;
    try {
      response = await _client.get(url).timeout(_timeout);
    } on SocketException {
      throw const NetworkException();
    } on TimeoutException {
      throw const NetworkException(
        message: 'The request timed out. Please check your connection.',
      );
    }

    if (response.statusCode != 200) {
      throw ServerException(statusCode: response.statusCode);
    }

    final Map<String, dynamic> json;
    try {
      json = jsonDecode(response.body) as Map<String, dynamic>;
    } on FormatException {
      throw const ParsingException(
        field: 'root',
        message: 'The server returned invalid JSON.',
      );
    }

    // fromJson throws ParsingException on any structural mismatch.
    return CurrencyRateModel.fromJson(json);
  }
}
