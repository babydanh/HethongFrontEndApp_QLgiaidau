import 'package:firebase_core/firebase_core.dart';
import 'package:app_quanly_giaidau/firebase_options.dart';

class FirebaseConfig {
  static Future<void> init() async {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );

    // Bật Firestore offline persistence (Tạm thời tắt để debug lỗi treo)
    // FirebaseFirestore.instance.settings = const Settings(
    //   persistenceEnabled: true,
    //   cacheSizeBytes: Settings.CACHE_SIZE_UNLIMITED,
    // );
  }
}
