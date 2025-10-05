import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:myparadefixed/features/parade_location/controller/location_controller.dart';
import 'package:myparadefixed/features/parade_location/controller/weather_controller.dart';
import 'package:myparadefixed/features/parade_location/view/parade_location_screen.dart';
import 'package:provider/provider.dart';

import 'firebase_options.dart';

Future<void> main() async {
  // Ensure widgets are initialized before the app starts
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  // Optional: Configure Google Maps for Android and iOS
  // GoogleMapsFlutterAndroid.useAndroidTileOverlays = false;
  // GoogleMapsFlutterIOS.useTileOverlays = false;

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (context) => LocationController()),
        ChangeNotifierProvider(create: (context) => WeatherController()),
      ],
      child: MaterialApp(
        title: 'MyParade',
        debugShowCheckedModeBanner: false, // Hide debug banner
        theme: _buildAppTheme(), // Apply the custom theme
        home: const ParadeLocationScreen(),
      ),
    );
  }

  // NEW: Define the app theme
  static ThemeData _buildAppTheme() {
    // Make the method static
    final ColorScheme colorScheme = const ColorScheme.light(
      primary: Color(0xFF333D44), // Dark Slate Gray
      secondary: Color(0xFFBC5D40), // Muted Terracotta
      background: Color(0xFFF4F4F4), // Light Stone Gray
      surface: Color(0xFFFFFFFF), // White
      error: Color(0xFFB74635),
      onPrimary: Color(0xFFFFFFFF),
      onSecondary: Color(0xFFFFFFFF),
      onSurface: Color(0xFF22282C), // Darkest Slate for text
      onBackground: Color(0xFF22282C),
      onError: Color(0xFFFFFFFF),
    );

    return ThemeData(
      useMaterial3: true, // Use Material 3 design
      colorScheme: colorScheme,
      // NEW: Customize text themes for consistency
      textTheme: _buildTextTheme(),
      // NEW: Customize elevated button theme
      elevatedButtonTheme: _buildElevatedButtonTheme(colorScheme),
      // NEW: Customize app bar theme
      appBarTheme: _buildAppBarTheme(colorScheme),
      // NEW: Customize card theme - CORRECTED AGAIN
      cardTheme: CardThemeData(
        // Use CardThemeData directly
        color: Colors.white, // Use a specific color or colorScheme.surface
        elevation: 4,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(16)),
        ),
      ),
      // NEW: Customize input decoration theme
      inputDecorationTheme: _buildInputDecorationTheme(),
    );
  }

  // NEW: Define text theme
  static TextTheme _buildTextTheme() {
    // Make the method static
    return const TextTheme(
      displayLarge: TextStyle(
        fontSize: 36,
        fontWeight: FontWeight.bold,
        color: Color(0xFF2196F3), // Blue header
      ),
      headlineMedium: TextStyle(
        fontSize: 24,
        fontWeight: FontWeight.bold,
        color: Color(0xFF2196F3), // Blue header
      ),
      titleLarge: TextStyle(
        fontSize: 20,
        fontWeight: FontWeight.w600,
        color: Color(0xFF2196F3), // Blue header
      ),
      titleMedium: TextStyle(
        fontSize: 18,
        fontWeight: FontWeight.w500,
        color: Color(0xFF2196F3), // Blue header
      ),
      bodyLarge: TextStyle(
        fontSize: 16,
        color: Colors.black87, // Standard body text
      ),
      bodyMedium: TextStyle(
        fontSize: 14,
        color: Colors.grey, // Smaller body text
      ),
    );
  }

  // NEW: Define elevated button theme
  static ElevatedButtonThemeData _buildElevatedButtonTheme(
    ColorScheme colorScheme,
  ) {
    // Make the method static
    return ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: colorScheme.primary,
        foregroundColor: colorScheme.onPrimary,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        padding: const EdgeInsets.symmetric(vertical: 16),
      ),
    );
  }

  // NEW: Define app bar theme
  static AppBarTheme _buildAppBarTheme(ColorScheme colorScheme) {
    // Make the method static
    return AppBarTheme(
      backgroundColor: colorScheme.primary,
      foregroundColor: colorScheme.onPrimary,
      titleTextStyle: const TextStyle(
        fontSize: 20,
        fontWeight: FontWeight.bold,
        color: Colors.white,
      ),
    );
  }

  // NEW: Define input decoration theme
  static InputDecorationTheme _buildInputDecorationTheme() {
    // Make the method static
    return InputDecorationTheme(
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Colors.grey),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Colors.grey),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Color(0xFF2196F3), width: 2),
      ),
    );
  }
}
