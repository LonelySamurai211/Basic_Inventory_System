import 'package:flutter/material.dart';

import 'core/theme/app_theme.dart';
import 'features/shell/app_shell.dart';

class CocoolHotelApp extends StatelessWidget {
  const CocoolHotelApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'CoCool Hotel MIMS',
      theme: AppTheme.light,
      home: const AppShell(),
    );
  }
}
