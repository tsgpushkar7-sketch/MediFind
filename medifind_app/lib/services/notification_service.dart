import 'package:firebase_messaging/firebase_messaging.dart';
import 'api_service.dart';

class NotificationService {
  static Future<void> initAndSaveToken(String userId) async {
    final messaging = FirebaseMessaging.instance;

    await messaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );

    String? token = await messaging.getToken();

    if (token != null) {
      await ApiService.saveFcmToken(userId, token);
      print('FCM token saved for user: $userId');
    }
  }
}