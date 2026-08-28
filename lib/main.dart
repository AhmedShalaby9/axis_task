import 'package:flutter/material.dart';

import 'core/di/injection_container.dart' as di;
import 'core/theme/app_theme.dart';
import 'features/currency/presentation/pages/rates_list_page.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await di.init();
  runApp(const App());
}

class App extends StatelessWidget {
  const App({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Axis Task',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.dark,
      home: const RatesListPage(),
    );
  }
}
