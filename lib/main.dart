import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nuvora/core/navigation/main_shell.dart';
import 'package:nuvora/core/theme/app_theme.dart';
import 'package:nuvora/features/onboarding/presentation/screens/onboarding_screen.dart';

void main() {
  runApp(const ProviderScope(child: MyApp()));
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  static const bool _isTestEnvironment = bool.fromEnvironment('FLUTTER_TEST');
  bool _didCompleteOnboarding = _isTestEnvironment;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Nuvora',
      theme: buildAppTheme(),
      darkTheme: buildDarkAppTheme(),
      themeMode: ThemeMode.system,
      home: _didCompleteOnboarding
          ? const AppShell()
          : OnboardingScreen(
              onSkip: () => setState(() => _didCompleteOnboarding = true),
              onComplete: () => setState(() => _didCompleteOnboarding = true),
            ),
      debugShowCheckedModeBanner: false,
    );
  }
}
