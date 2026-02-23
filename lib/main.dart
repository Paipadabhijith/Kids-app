import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'screens/home_screen.dart';
import 'services/app_theme_service.dart';
import 'services/storage_service.dart';
import 'services/api_key_service.dart';
import 'utils/theme.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);
  
  // Set up error handling
  FlutterError.onError = (FlutterErrorDetails details) {
    FlutterError.presentError(details);
    debugPrint('Flutter Error: ${details.exception}');
    debugPrint('Stack trace: ${details.stack}');
  };
  
  // Initialize Firebase
  try {
    await Firebase.initializeApp();
    debugPrint('Firebase initialized successfully');
  } catch (e) {
    debugPrint('Error initializing Firebase: $e');
  }
  
  // Load environment variables with error handling
  try {
    await dotenv.load(fileName: ".env");
    
    // Debug: Check if keys are loaded
    debugPrint('=== API Key Debug ===');
    debugPrint('Key 1 loaded: ${dotenv.env['YOUTUBE_API_KEY']?.isNotEmpty ?? false}');
    debugPrint('Key 2 loaded: ${dotenv.env['YOUTUBE_API_KEY_2']?.isNotEmpty ?? false}');
    if (dotenv.env['YOUTUBE_API_KEY'] != null) {
      debugPrint('Key 1 value: ${dotenv.env['YOUTUBE_API_KEY']!.substring(0, 10)}...');
    }
    if (dotenv.env['YOUTUBE_API_KEY_2'] != null) {
      debugPrint('Key 2 value: ${dotenv.env['YOUTUBE_API_KEY_2']!.substring(0, 10)}...');
    }
    debugPrint('===================');
  } catch (e) {
    debugPrint('Warning: Could not load .env file: $e');
    // App can still run, but YouTube features won't work without API key
  }
  
  // Initialize storage service
  try {
    await StorageService.init();
    debugPrint('StorageService initialized');
  } catch (e) {
    debugPrint('Error initializing StorageService: $e');
  }
  
  try {
    await AppThemeService.init();
    debugPrint('AppThemeService initialized');
  } catch (e) {
    debugPrint('Error initializing AppThemeService: $e');
  }
  
  try {
    await ApiKeyService().init(); // Initialize API key service
    debugPrint('ApiKeyService initialized');
  } catch (e, stackTrace) {
    debugPrint('Error initializing ApiKeyService: $e');
    debugPrint('Stack trace: $stackTrace');
    // Continue anyway - app should still work
  }
  
  // Ensure app starts even if initialization had issues
  debugPrint('Starting app...');
  runApp(const KidsTVApp());
}

class KidsTVApp extends StatelessWidget {
  const KidsTVApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<ThemeMode>(
      valueListenable: AppThemeService.themeMode,
      builder: (context, themeMode, _) {
        return MaterialApp(
          title: 'Kids TV',
          theme: AppTheme.lightTheme,
          darkTheme: AppTheme.darkTheme,
          themeMode: themeMode,
          debugShowCheckedModeBanner: false,
          home: Builder(
            builder: (context) {
              // Directly show HomeScreen - Firebase auth is handled inside
              return const HomeScreen();
            },
          ),
          builder: (context, child) {
            // Wrap with error boundary
            return MediaQuery(
              data: MediaQuery.of(context).copyWith(textScaler: TextScaler.linear(1.0)),
              child: child ?? const HomeScreen(),
            );
          },
        );
      },
    );
  }
}

