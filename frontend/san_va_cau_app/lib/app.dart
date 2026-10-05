import 'package:flutter/material.dart';

import 'core/theme/app_theme.dart';
import 'features/app_status/pages/app_status_guard.dart';

class SanVaCauApp extends StatelessWidget {
  const SanVaCauApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'SanVaCau',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light(),
      home: const AppStatusGuard(),
    );
  }
}
