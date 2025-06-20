import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'firebase_options.dart'; // File yang dihasilkan dari flutterfire configure
import 'splashscreen.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  try {
    // Gunakan file konfigurasi yang dihasilkan oleh flutterfire configure
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    print('✅ Firebase berhasil diinisialisasi');
  } catch (e) {
    print('❌ Error inisialisasi Firebase: $e');
    // Fallback jika file konfigurasi tidak ada atau terjadi kesalahan
    if (kIsWeb) {
      // Jika web, gunakan konfigurasi manual sementara (untuk development)
      await Firebase.initializeApp(
        options: const FirebaseOptions(
          apiKey: "YOUR_API_KEY",
          authDomain: "YOUR_AUTH_DOMAIN",
          projectId: "YOUR_PROJECT_ID",
          storageBucket: "YOUR_STORAGE_BUCKET",
          messagingSenderId: "YOUR_MESSAGING_SENDER_ID",
          appId: "YOUR_APP_ID",
        ),
      );
    } else {
      // Untuk platform mobile, coba inisialisasi default
      await Firebase.initializeApp();
    }
  }

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Semaikan',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Color(0xFF626F47)),
        fontFamily: 'Poppins', // Sesuai dengan theme app Anda
      ),
      home: const SplashScreen(),
      debugShowCheckedModeBanner: false,
    );
  }
}
