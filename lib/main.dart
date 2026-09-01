import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tuneflow/features/music/presentation/screens/home_screen.dart';

import 'core/constants/app_colors.dart';

void main() {
  runApp(const ProviderScope(child: TuneFlowApp()));
}

class TuneFlowApp extends StatelessWidget {
  const TuneFlowApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'TuneFlow',
      debugShowCheckedModeBanner: false,

      theme: ThemeData(
        brightness: Brightness.dark,
        scaffoldBackgroundColor: AppColors.background,

        colorScheme: const ColorScheme.dark(
          primary: AppColors.primary,
          surface: AppColors.surface,
        ),

        appBarTheme: const AppBarTheme(
          backgroundColor: AppColors.background,
          foregroundColor: AppColors.white,
          elevation: 0,
        ),

        textTheme: const TextTheme(
          bodyLarge: TextStyle(color: AppColors.white),
          bodyMedium: TextStyle(color: AppColors.white),
          titleLarge: TextStyle(
            color: AppColors.white,
            fontWeight: FontWeight.bold,
          ),
        ),

        iconTheme: const IconThemeData(color: AppColors.white),

        inputDecorationTheme: const InputDecorationTheme(
          filled: true,
          fillColor: AppColors.surface,
          hintStyle: TextStyle(color: AppColors.white),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.all(Radius.circular(12)),
            borderSide: BorderSide.none,
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.all(Radius.circular(12)),
            borderSide: BorderSide(color: AppColors.primary),
          ),
        ),
      ),

      home: const HomeScreen(),
    );
  }
}
