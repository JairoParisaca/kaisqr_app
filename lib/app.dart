import 'package:flutter/material.dart';

import 'core/theme/app_theme.dart';
import 'features/sala/services/sala_service.dart';
import 'features/sala/views/home_view.dart';

class AppRoot extends StatelessWidget {
  const AppRoot({required this.salaService, super.key});

  final SalaService salaService;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Kais QR',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light(),
      home: HomeView(salaService: salaService),
    );
  }
}
