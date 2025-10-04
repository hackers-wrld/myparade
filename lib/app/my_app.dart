import 'package:flutter/material.dart';
import 'package:myparadefixed/core/theme/app_theme.dart';
import 'package:myparadefixed/features/parade_location/view/parade_location_screen.dart';

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'My Parade',
      theme: AppTheme.lightTheme,
      home: const ParadeLocationScreen(),
    );
  }
}
