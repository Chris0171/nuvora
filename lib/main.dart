import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nuvora/core/navigation/main_shell.dart';
import 'package:nuvora/core/theme/app_theme.dart';

void main() {
  runApp(const ProviderScope(child: MyApp()));
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Nuvora',
      theme: buildAppTheme(),
      home: const MainShell(),
      debugShowCheckedModeBanner: false,
    );
  }
}
