import 'package:equatable/equatable.dart';

import '../../../../core/enums/data_origin.dart';

/// A single dated snapshot within a currency's history.
/// Rates are inverted (X→EGP), consistent with [ExchangeRate].
class RatePoint extends Equatable {
  const RatePoint({
    required this.date,
    required this.rate,
  });

  final DateTime date;

  /// How many EGP buy 1 unit of the parent currency on [date].
  final double rate;

  @override
  List<Object?> get props => [date, rate];
}

/// Seven (or N) daily rate snapshots for a single currency pair.
///
/// [dataOrigin] reflects the source of the entire response — a mixed-source
/// history list is not modelled; the most conservative origin wins at the
/// repository level (if any point came from cache, the whole entity is cache).
class RateHistory extends Equatable {
  const RateHistory({
    required this.code,
    required this.points,
    required this.dataOrigin,
  });

  /// ISO 4217 code, uppercase. E.g. "USD".
  final String code;

  /// Daily snapshots sorted ascending by date (oldest → newest).
  final List<RatePoint> points;

  /// Source of the history data. Drives stale-data indicators in the UI.
  final DataOrigin dataOrigin;

  @override
  List<Object?> get props => [code, points, dataOrigin];
}
