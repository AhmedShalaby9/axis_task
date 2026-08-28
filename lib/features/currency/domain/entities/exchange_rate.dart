import 'package:equatable/equatable.dart';

import '../../../../core/enums/data_origin.dart';
import 'egp_trend.dart';

/// A single currency's exchange rate relative to EGP, fully decorated for
/// display. All rates are inverted (X→EGP) — the repository handles inversion.
///
/// Delta fields default to zero when constructed by the repository from a single
/// date's data. [GetAllRatesWithChange] populates them after comparing two dates.
class ExchangeRate extends Equatable {
  const ExchangeRate({
    required this.code,
    required this.name,
    required this.rate,
    required this.rateDate,
    required this.dataOrigin,
    this.absoluteDelta = 0.0,
    this.percentDelta = 0.0,
    this.egpTrend = EgpTrend.unchanged,
  });

  /// ISO 4217 code, uppercase. E.g. "USD". Used as a map key and display label.
  final String code;

  /// Human-readable name. E.g. "US Dollar". Supplied by the repository.
  final String name;

  /// How many EGP buy 1 unit of [code]. Already inverted from the API value.
  final double rate;

  /// The calendar date these rates belong to, parsed from the API's "date" field.
  final DateTime rateDate;

  /// Whether this entity was resolved from the remote API or local cache.
  /// Drives the "last updated" indicator (Module 2) and stale warning (Module 3).
  final DataOrigin dataOrigin;

  /// Today's [rate] minus yesterday's [rate], on inverted values.
  /// Negative = EGP strengthened (fewer EGP needed). Zero when delta is unknown.
  final double absoluteDelta;

  /// [absoluteDelta] expressed as a percentage of yesterday's rate.
  /// Zero when delta is unknown.
  final double percentDelta;

  /// Direction of EGP's strength. Derived from [absoluteDelta] by the use case.
  /// Defaults to [EgpTrend.unchanged] until the use case populates it.
  final EgpTrend egpTrend;

  ExchangeRate copyWith({
    String? code,
    String? name,
    double? rate,
    DateTime? rateDate,
    DataOrigin? dataOrigin,
    double? absoluteDelta,
    double? percentDelta,
    EgpTrend? egpTrend,
  }) {
    return ExchangeRate(
      code: code ?? this.code,
      name: name ?? this.name,
      rate: rate ?? this.rate,
      rateDate: rateDate ?? this.rateDate,
      dataOrigin: dataOrigin ?? this.dataOrigin,
      absoluteDelta: absoluteDelta ?? this.absoluteDelta,
      percentDelta: percentDelta ?? this.percentDelta,
      egpTrend: egpTrend ?? this.egpTrend,
    );
  }

  @override
  List<Object?> get props => [
        code,
        name,
        rate,
        rateDate,
        dataOrigin,
        absoluteDelta,
        percentDelta,
        egpTrend,
      ];
}
