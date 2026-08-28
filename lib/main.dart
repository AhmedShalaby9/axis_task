import 'package:flutter/material.dart';

import 'core/di/injection_container.dart' as di;

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await di.init();
  runApp(const App());
}

class App extends StatelessWidget {
  const App({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      title: 'Axis Task',
      debugShowCheckedModeBanner: false,
      home: Scaffold(
        body: Center(
          child: Text('Axis Task — screens coming soon'),
        ),
      ),
    );
  }
}
