import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

import 'core/globals.dart';
import 'core/theme/app_theme.dart';
import 'core/constants/app_constants.dart';
import 'data/models/sync_action.dart';
import 'data/models/sync_action_type.dart';
import 'data/models/submission.dart';
import 'data/services/sync_service.dart';
import 'data/services/api_client.dart';
import 'presentation/screens/login_screen.dart';
import 'presentation/screens/register_screen.dart';
import 'presentation/screens/role_based_home_router.dart';
import 'state/task_providers.dart';
import 'state/auth_provider.dart';

// ─── Local notifications plugin (for showing FCM in foreground) ──────────────
final FlutterLocalNotificationsPlugin _localNotifications =
    FlutterLocalNotificationsPlugin();

// ─── Navigator Key for global navigation ──────────────────────────────────────
final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

// ─── Background message handler — MUST be a top-level function ───────────────
@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp();
  debugPrint('🔔 Background FCM: ${message.notification?.title}');
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  try {
    // Load environment variables
    try {
      await dotenv.load(fileName: ".env");
      debugPrint('✅ .env file loaded successfully');
    } catch (e) {
      debugPrint('⚠️ .env file not found, using defaults: $e');
    }

    // Initialize Firebase (optional on web - not required for testing)
    try {
      await Firebase.initializeApp();
      FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);
      debugPrint('✅ Firebase initialized successfully');
    } catch (e) {
      // Firebase is optional - app works without it (just no push notifications)
      debugPrint('⚠️ Firebase init skipped (optional on web): $e');
    }

    // Initialize local notifications channel (Android 8+)
    try {
      await _initLocalNotifications();
      debugPrint('✅ Local notifications initialized');
    } catch (e) {
      debugPrint('⚠️ Local notifications init failed: $e');
    }

    // Initialize Hive
    try {
      await Hive.initFlutter();
      debugPrint('✅ Hive initialized');

      // Register Adapters
      Hive.registerAdapter(SyncActionTypeAdapter());
      Hive.registerAdapter(SyncActionAdapter());
      Hive.registerAdapter(SubmissionAdapter());
      debugPrint('✅ Hive adapters registered');

      // Open Boxes
      await Hive.openBox<Submission>(AppConstants.submissionsBox);
      debugPrint('✅ Hive boxes opened');
    } catch (e) {
      debugPrint('⚠️ Hive initialization failed: $e');
      // Continue - Hive is optional for this build
    }

    // Initialize Global Services
    try {
      await SyncService().init();
      debugPrint('✅ Sync service initialized');
    } catch (e) {
      debugPrint('⚠️ Sync service init failed: $e');
    }

    final prefs = await SharedPreferences.getInstance();
    debugPrint('✅ Shared preferences loaded');

    // Initialize Auth State (Persistent Session)
    final container = ProviderContainer(
      overrides: [
        sharedPreferencesProvider.overrideWithValue(prefs),
      ],
    );

    await container.read(authNotifierProvider.notifier).checkAuthStatus();
    debugPrint('✅ Auth state initialized');

    runApp(
      UncontrolledProviderScope(
        container: container,
        child: const TaskManagerApp(),
      ),
    );
  } catch (e, stackTrace) {
    debugPrint('❌ Fatal error during initialization: $e');
    debugPrint('Stack trace: $stackTrace');
    
    // Show error screen if initialization fails
    runApp(
      MaterialApp(
        home: Scaffold(
          backgroundColor: Colors.black,
          body: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.error_outline, color: Colors.red, size: 64),
                const SizedBox(height: 24),
                const Text(
                  'App Initialization Failed',
                  style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 12),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: Text(
                    'Error: $e',
                    style: const TextStyle(color: Colors.red, fontSize: 12),
                    textAlign: TextAlign.center,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Create the Android notification channel and initialize the local plugin.
Future<void> _initLocalNotifications() async {
  const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
  const initSettings = InitializationSettings(android: androidSettings);
  await _localNotifications.initialize(initSettings);

  const channel = AndroidNotificationChannel(
    'task_alerts',
    'Task Alerts',
    description: 'Notifications for task updates, messages, and submissions',
    importance: Importance.high,
  );
  await _localNotifications
      .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin>()
      ?.createNotificationChannel(channel);
}

/// Request FCM permission, get token, register with backend, wire up listeners.
/// Called from HomeScreen after the user is authenticated.
Future<void> setupPushNotifications() async {
  try {
    final messaging = FirebaseMessaging.instance;

    // Request permission (Android 13+ and iOS require explicit consent)
    final settings = await messaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );

    if (settings.authorizationStatus == AuthorizationStatus.denied) {
      debugPrint('⚠️ Push notification permission denied');
      return;
    }

    // Get FCM token and send to backend so server knows where to push
    final token = await messaging.getToken();
    if (token != null) {
      debugPrint('📱 FCM Token obtained');
      try {
        await ApiClient().updateFcmToken(token);
        debugPrint('✅ FCM token registered with backend');
      } catch (e) {
        debugPrint('⚠️ Failed to register FCM token: $e');
      }
    }

    // Keep token fresh — re-register whenever Firebase rotates it
    messaging.onTokenRefresh.listen((newToken) async {
      debugPrint('🔄 FCM token refreshed');
      try {
        await ApiClient().updateFcmToken(newToken);
      } catch (e) {
        debugPrint('⚠️ Failed to update refreshed FCM token: $e');
      }
    });

    // Foreground messages — Firebase doesn't show a heads-up notification
    // automatically, so we show one via flutter_local_notifications
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      debugPrint('🔔 Foreground FCM: ${message.notification?.title}');
      final notification = message.notification;
      if (notification != null) {
        _localNotifications.show(
          notification.hashCode,
          notification.title,
          notification.body,
          const NotificationDetails(
            android: AndroidNotificationDetails(
              'task_alerts',
              'Task Alerts',
              channelDescription: 'Task notifications',
              importance: Importance.high,
              priority: Priority.high,
              icon: '@mipmap/ic_launcher',
            ),
          ),
        );
      }
    });

    // Notification tapped while app is in background (not terminated)
    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      debugPrint('🔔 FCM tapped from background: ${message.data}');
      
      // Extract taskId from notification data
      final taskId = message.data['taskId'] ?? message.data['data_taskId'];
      if (taskId != null && taskId.isNotEmpty) {
        debugPrint('🎯 Navigating to task: $taskId');
        // Navigate to task detail screen
        // NOTE: Navigation happens in HomeScreen via a provider
        navigatorKey.currentState?.pushNamed('/task/$taskId');
      }
    });

  } catch (e) {
    // Firebase may not be available on web in development
    debugPrint('⚠️ Push notifications unavailable: $e');
  }
}

class TaskManagerApp extends ConsumerWidget {
  const TaskManagerApp({super.key});

  static GlobalKey<ScaffoldMessengerState> get scaffoldMessengerKey =>
      appScaffoldMessengerKey;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authNotifierProvider);

    if (authState.status == AuthStatus.initial ||
        authState.status == AuthStatus.loading) {
      return MaterialApp(
        navigatorKey: navigatorKey,
        debugShowCheckedModeBanner: false,
        theme: AppTheme.lightTheme,
        home: const Scaffold(
          backgroundColor: AppTheme.backgroundLight,
          body: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                SizedBox(
                  width: 60,
                  height: 60,
                  child: CircularProgressIndicator(
                    strokeWidth: 3,
                    color: AppTheme.primaryCoral,
                  ),
                ),
                SizedBox(height: 24),
                Text(
                  'INITIALIZING SECURE SESSION...',
                  style: TextStyle(
                    color: AppTheme.textMuted,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 2,
                    fontSize: 10,
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return MaterialApp(
      navigatorKey: navigatorKey,
      scaffoldMessengerKey: appScaffoldMessengerKey,
      debugShowCheckedModeBanner: false,
      title: 'Task Manager',
      theme: AppTheme.lightTheme,
      themeMode: ThemeMode.light,
      home: authState.status == AuthStatus.authenticated
          ? const RoleBasedHomeRouter()
          : const LoginScreen(),
      routes: {
        RegisterScreen.routeName: (context) => const RegisterScreen(),
      },
    );
  }
}
