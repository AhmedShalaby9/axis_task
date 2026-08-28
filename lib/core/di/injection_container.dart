import 'package:get_it/get_it.dart';

import 'modules/currency_module.dart';
import 'modules/network_module.dart';

/// Global service locator. Import this file wherever you need `sl`.
final sl = GetIt.instance;

/// Registers all dependencies. Must be awaited before [runApp].
Future<void> init() async {
  await registerNetworkModule(sl);
  registerCurrencyModule(sl);
}
