import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'state.dart';
import 'root_shell.dart';

void main() {
  runApp(const SuzopApp());
}

class SuzopApp extends StatelessWidget {
  const SuzopApp({super.key});

  @override
  Widget build(BuildContext context) => ChangeNotifierProvider(
        create: (_) => AppState()..load(),
        child: Consumer<AppState>(
          builder: (context, st, _) => MaterialApp(
            title: 'suzop',
            debugShowCheckedModeBanner: false,
            theme: ThemeData(
              useMaterial3: true,
              scaffoldBackgroundColor: const Color(0xFFE3F3FE),
              colorScheme: ColorScheme.fromSeed(
                seedColor: const Color(0xFF2E7CF6),
                brightness: Brightness.light,
              ),
            ),
            darkTheme: ThemeData(
              useMaterial3: true,
              scaffoldBackgroundColor: const Color(0xFF0B1E33),
              colorScheme: ColorScheme.fromSeed(
                seedColor: const Color(0xFF2E7CF6),
                brightness: Brightness.dark,
              ),
            ),
            themeMode: st.dark ? ThemeMode.dark : ThemeMode.light,
            home: const RootShell(),
          ),
        ),
      );
}
