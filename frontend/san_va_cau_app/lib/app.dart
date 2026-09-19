import 'package:flutter/material.dart';

import 'core/theme/app_theme.dart';
import 'features/main/main_shell.dart';

class SanVaCauApp extends StatelessWidget {
  const SanVaCauApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'SanVaCau',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light(),
      home: const MainShell(),
    );
  }
}
