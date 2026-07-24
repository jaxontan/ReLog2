import 'dart:convert';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../features/auth/presentation/view_models/auth_view_model.dart';

// Notification channels
const String _defaultChannelId = 'reLog2_default';
const String _chatChannelId = 'reLog2_chat';
const String _memoryChannelId = 'reLog2_memory';

// Background message handler (must be top-level function)
@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp();
  // debugPrint('Background message: ${message.messageId}'); // Not available on web
}

/// Local notifications plugin instance
final FlutterLocalNotificationsPlugin _localNotifications = FlutterLocalNotificationsPlugin();

/// Notification service provider
final notificationServiceProvider = Provider<NotificationService>((ref) => NotificationService(ref));

class NotificationService {
  final Ref _ref;
  final FirebaseMessaging _messaging = FirebaseMessaging.instance;

  NotificationService(this._ref);

  /// Initialize FCM and local notifications
  Future<void> initialize() async {
    // Request permissions
    await _requestPermissions();

    // Initialize local notifications
    await _initLocalNotifications();

    // Get FCM token
    await _refreshToken();

    // Handle foreground messages
    FirebaseMessaging.onMessage.listen(_handleForegroundMessage);

    // Handle background messages opened by user
    FirebaseMessaging.onMessageOpenedApp.listen(_handleMessageOpenedApp);

    // Handle terminated app opened by notification
    final initialMessage = await _messaging.getInitialMessage();
    if (initialMessage != null) {
      _handleMessageOpenedApp(initialMessage);
    }

    // Listen for token refresh
    _messaging.onTokenRefresh.listen(_onTokenRefresh);

    // debugPrint('Notification service initialized');
  }

  /// Request notification permissions
  Future<void> _requestPermissions() async {
    final settings = await _messaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
      provisional: false,
      carPlay: false,
      criticalAlert: false,
    );

    // debugPrint('Notification permission: ${settings.authorizationStatus}');
  }

  /// Initialize local notifications plugin
  Future<void> _initLocalNotifications() async {
    const androidInit = AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosInit = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );

    const initSettings = InitializationSettings(
      android: androidInit,
      iOS: iosInit,
    );

    await _localNotifications.initialize(
      initSettings,
      onDidReceiveNotificationResponse: _onNotificationTapped,
    );

    // Create notification channels (Android)
    try {
      final androidPlugin = _localNotifications.resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin>();
      if (androidPlugin != null) {
        await androidPlugin.createNotificationChannel(
          const AndroidNotificationChannel(
            _defaultChannelId,
            'General Notifications',
            description: 'General app notifications',
            importance: Importance.defaultImportance,
          ),
        );
        await androidPlugin.createNotificationChannel(
          const AndroidNotificationChannel(
            _chatChannelId,
            'Chat Messages',
            description: 'Notifications for new chat messages',
            importance: Importance.high,
          ),
        );
        await androidPlugin.createNotificationChannel(
          const AndroidNotificationChannel(
            _memoryChannelId,
            'Memory Updates',
            description: 'Notifications for new memories in your journals',
            importance: Importance.defaultImportance,
          ),
        );
      }
    } catch (e) {
      // debugPrint('Failed to create notification channels: $e');
    }
  }

  /// Get and register FCM token with Supabase
  Future<void> _refreshToken() async {
    try {
      final token = await _messaging.getToken();
      if (token != null) {
        await _registerTokenWithBackend(token);
        // debugPrint('FCM Token: $token');
      }
    } catch (e) {
      // debugPrint('Failed to get FCM token: $e');
    }
  }

  /// Register FCM token with Supabase (user's device_tokens table)
  Future<void> _registerTokenWithBackend(String token) async {
    final user = _ref.read(authServiceProvider).currentUser;
    if (user == null) return;

    try {
      await Supabase.instance.client.from('device_tokens').upsert({
        'user_id': user.id,
        'token': token,
        'platform': 'mobile', // Platform.isIOS ? 'ios' : Platform.isAndroid ? 'android' : 'web',
        'updated_at': DateTime.now().toIso8601String(),
      }, onConflict: 'user_id,token');
    } catch (e) {
      // debugPrint('Failed to register token with backend: $e');
    }
  }

  /// Handle token refresh
  Future<void> _onTokenRefresh(String token) async {
    // debugPrint('FCM Token refreshed: $token');
    await _registerTokenWithBackend(token);
  }

  /// Handle foreground messages
  void _handleForegroundMessage(RemoteMessage message) {
    // debugPrint('Foreground message: ${message.notification?.title}');
    _showLocalNotification(message);
  }

  /// Handle notification tap (app in background/terminated)
  void _handleMessageOpenedApp(RemoteMessage message) {
    // debugPrint('Message opened app: ${message.data}');
    _navigateFromMessage(message);
  }

  /// Handle notification tap from local notifications
  void _onNotificationTapped(NotificationResponse response) {
    final payload = response.payload;
    if (payload != null) {
      // debugPrint('Local notification tapped: $payload');
      // Parse payload and navigate
    }
  }

  /// Show local notification for foreground messages
  Future<void> _showLocalNotification(RemoteMessage message) async {
    final notification = message.notification;
    final data = message.data;

    String channelId = _defaultChannelId;
    if (data['type'] == 'chat') channelId = _chatChannelId;
    if (data['type'] == 'memory') channelId = _memoryChannelId;

    const androidDetails = AndroidNotificationDetails(
      _defaultChannelId,
      'General Notifications',
      channelDescription: 'General app notifications',
      importance: Importance.high,
      priority: Priority.high,
    );

    const iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    await _localNotifications.show(
      notification.hashCode,
      notification?.title ?? 'ReLog2',
      notification?.body ?? 'New notification',
      NotificationDetails(android: androidDetails, iOS: iosDetails),
      payload: jsonEncode(data),
    );
  }

  /// Navigate based on notification data
  void _navigateFromMessage(RemoteMessage message) {
    final data = message.data;
    final type = data['type'];
    final albumId = data['album_id'];
    final memoryId = data['memory_id'];
    final messageId = data['message_id'];

    // Navigation will be handled by the router
    // This can be connected to GoRouter via a navigator key
    // debugPrint('Navigate: type=$type, albumId=$albumId, memoryId=$memoryId, messageId=$messageId');
  }

  /// Subscribe to album topic for notifications
  Future<void> subscribeToAlbum(String albumId) async {
    try {
      await _messaging.subscribeToTopic('album_$albumId');
      // debugPrint('Subscribed to album_$albumId');
    } catch (e) {
      // debugPrint('Failed to subscribe to album topic: $e');
    }
  }

  /// Unsubscribe from album topic
  Future<void> unsubscribeFromAlbum(String albumId) async {
    try {
      await _messaging.unsubscribeFromTopic('album_$albumId');
      // debugPrint('Unsubscribed from album_$albumId');
    } catch (e) {
      // debugPrint('Failed to unsubscribe from album topic: $e');
    }
  }

  /// Delete FCM token on logout
  Future<void> deleteToken() async {
    final user = _ref.read(authServiceProvider).currentUser;
    if (user == null) return;

    try {
      final token = await _messaging.getToken();
      if (token != null) {
        await Supabase.instance.client
            .from('device_tokens')
            .delete()
            .eq('user_id', user.id)
            .eq('token', token);
      }
    } catch (e) {
      // debugPrint('Failed to delete token: $e');
    }
  }
}

/// Initialize notifications at app startup
final initNotificationsProvider = FutureProvider<void>((ref) async {
  final service = ref.read(notificationServiceProvider);
  await service.initialize();
});