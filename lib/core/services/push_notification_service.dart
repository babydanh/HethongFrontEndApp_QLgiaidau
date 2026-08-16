import 'dart:io' show Platform;
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:app_quanly_giaidau/core/services/app_logger.dart';
import 'package:app_quanly_giaidau/core/services/dio_client.dart';

/// Top-level background message handler for FCM
@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp();
  // Background notification handled automatically by system/OS
}

class PushNotificationService {
  static const _log = AppLogger('PushNotificationService');
  static final PushNotificationService instance = PushNotificationService._internal();

  PushNotificationService._internal();

  final FlutterLocalNotificationsPlugin _localNotifications =
      FlutterLocalNotificationsPlugin();
  bool _isInitialized = false;
  String? _currentToken;

  static const AndroidNotificationChannel _channel = AndroidNotificationChannel(
    'sporto_high_importance_channel',
    'Thông báo Sporto',
    description: 'Kênh nhận thông báo quan trọng từ ứng dụng Sporto',
    importance: Importance.max,
    playSound: true,
    enableVibration: true,
  );

  /// Initialize Firebase, request permissions, and register FCM Token
  Future<void> initialize({required DioClient dioClient}) async {
    if (_isInitialized || kIsWeb) return;

    try {
      // 1. Initialize Firebase Core
      await Firebase.initializeApp();
      _log.info('Firebase initialized successfully');

      // 2. Set background message handler
      FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

      // 3. Request permissions on iOS and Android 13+
      final settings = await FirebaseMessaging.instance.requestPermission(
        alert: true,
        announcement: false,
        badge: true,
        carPlay: false,
        criticalAlert: false,
        provisional: false,
        sound: true,
      );

      _log.info('Notification permission status: ${settings.authorizationStatus}');

      // 4. Initialize Local Notifications Plugin for Android & iOS Foreground Heads-up Banners
      if (Platform.isIOS) {
        await FirebaseMessaging.instance.setForegroundNotificationPresentationOptions(
          alert: true,
          badge: true,
          sound: true,
        );
      }

      if (Platform.isAndroid) {
        const androidInitSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
        const initSettings = InitializationSettings(android: androidInitSettings);

        await _localNotifications.initialize(
          initSettings,
          onDidReceiveNotificationResponse: (response) {
            _log.info('Local notification tapped with payload: ${response.payload}');
          },
        );

        await _localNotifications
            .resolvePlatformSpecificImplementation<
                AndroidFlutterLocalNotificationsPlugin>()
            ?.createNotificationChannel(_channel);
      }

      // 5. Register device token with backend
      await _registerDeviceToken(dioClient);

      // 6. Listen for Token Refresh
      FirebaseMessaging.instance.onTokenRefresh.listen((newToken) {
        _currentToken = newToken;
        _sendTokenToBackend(dioClient, newToken);
      });

      // 7. Foreground message listener (Displays local notification banner while in app)
      FirebaseMessaging.onMessage.listen((RemoteMessage message) {
        _log.info('Received foreground FCM message: ${message.notification?.title}');
        _showForegroundNotification(message);
      });

      // 8. Notification opened from background
      FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
        _log.info('FCM Notification tapped from background: ${message.data}');
      });

      _isInitialized = true;
    } catch (e, st) {
      _log.error('Failed to initialize PushNotificationService', e, st);
    }
  }

  /// Get FCM token and send to backend
  Future<void> _registerDeviceToken(DioClient dioClient) async {
    try {
      // On iOS, ensure APNs token is available before requesting FCM token
      if (Platform.isIOS) {
        String? apnsToken = await FirebaseMessaging.instance.getAPNSToken();
        if (apnsToken == null) {
          // APNs token might take a few moments to resolve on app cold start
          await Future.delayed(const Duration(seconds: 2));
          apnsToken = await FirebaseMessaging.instance.getAPNSToken();
          _log.info('iOS APNs token status: ${apnsToken != null ? "Available" : "Not yet assigned"}');
        }
      }

      final token = await FirebaseMessaging.instance.getToken();
      if (token != null && token.isNotEmpty) {
        _currentToken = token;
        _log.info('FCM Device Token: $token');
        await _sendTokenToBackend(dioClient, token);
      }
    } catch (e) {
      _log.error('Error fetching FCM token: $e');
    }
  }

  /// Send device token to backend
  Future<void> _sendTokenToBackend(DioClient dioClient, String token) async {
    try {
      final platform = Platform.isIOS ? 'IOS' : 'ANDROID';
      await dioClient.dio.post(
        '/notifications/device-token',
        data: {
          'token': token,
          'platform': platform,
          'deviceInfo': '${Platform.operatingSystem} ${Platform.operatingSystemVersion}',
        },
      );
      _log.info('Device token registered with backend successfully');
    } catch (e) {
      _log.error('Failed to register device token with backend: $e');
    }
  }

  /// Display a local notification banner when a message is received in the foreground
  void _showForegroundNotification(RemoteMessage message) {
    final notification = message.notification;
    final android = message.notification?.android;

    if (notification != null && !kIsWeb) {
      _localNotifications.show(
        notification.hashCode,
        notification.title,
        notification.body,
        NotificationDetails(
          android: AndroidNotificationDetails(
            _channel.id,
            _channel.name,
            channelDescription: _channel.description,
            icon: android?.smallIcon ?? '@mipmap/ic_launcher',
            importance: Importance.max,
            priority: Priority.high,
            playSound: true,
            enableVibration: true,
          ),
          iOS: const DarwinNotificationDetails(
            presentAlert: true,
            presentBadge: true,
            presentSound: true,
          ),
        ),
        payload: message.data.toString(),
      );
    }
  }

  /// Unregister device token on user logout
  Future<void> unregisterToken({required DioClient dioClient}) async {
    if (_currentToken == null) return;
    try {
      await dioClient.dio.delete(
        '/notifications/device-token',
        data: {'token': _currentToken},
      );
      _currentToken = null;
      _log.info('Device token unregistered from backend');
    } catch (e) {
      _log.error('Failed to unregister device token: $e');
    }
  }
}
