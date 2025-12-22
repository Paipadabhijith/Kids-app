import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter/foundation.dart';
import 'screens/home_screen.dart';
import 'services/storage_service.dart';
import 'utils/theme.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Set up error handling
  FlutterError.onError = (FlutterErrorDetails details) {
    FlutterError.presentError(details);
    debugPrint('Flutter Error: ${details.exception}');
    debugPrint('Stack trace: ${details.stack}');
  };
  
  // Load environment variables with error handling
  try {
    await dotenv.load(fileName: ".env");
  } catch (e) {
    debugPrint('Warning: Could not load .env file: $e');
    // App can still run, but YouTube features won't work without API key
  }
  
  // Initialize storage service
  try {
    await StorageService.init();
  } catch (e) {
    debugPrint('Error initializing storage: $e');
    // Continue anyway - storage will be initialized on first use
  }
  
  runApp(const KidsTVApp());
}

class KidsTVApp extends StatelessWidget {
  const KidsTVApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Kids TV',
      theme: AppTheme.lightTheme,
      debugShowCheckedModeBanner: false,
      home: const HomeScreen(),
    );
  }
}

