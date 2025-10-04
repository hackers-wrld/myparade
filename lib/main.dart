import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'app/my_app.dart';
import 'features/parade_location/controller/location_controller.dart';

void main() {
  runApp(
    ChangeNotifierProvider(
      create: (context) => LocationController(),
      child: const MyApp(),
    ),
  );
}
