import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'auth_screen.dart';
import 'firebase_options.dart'; // يتولّد بأمر: flutterfire configure
import 'home_screen.dart';
import 'services.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});
  @override
  Widget build(BuildContext context) => MaterialApp(
        title: 'شات',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(colorSchemeSeed: const Color(0xFF128C7E), useMaterial3: true),
        builder: (c, child) => Directionality(textDirection: TextDirection.rtl, child: child!),
        home: const AuthGate(),
      );
}

class AuthGate extends StatelessWidget {
  const AuthGate({super.key});
  static const _loading = Scaffold(body: Center(child: CircularProgressIndicator()));

  @override
  Widget build(BuildContext context) => StreamBuilder<User?>(
        stream: auth.authStateChanges(),
        builder: (c, s) {
          if (s.connectionState == ConnectionState.waiting) return _loading;
          final u = s.data;
          if (u == null) return const AuthScreen();
          return StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
            stream: db.collection('users').doc(u.uid).snapshots(),
            builder: (c, d) {
              if (!d.hasData || !d.data!.exists) return _loading;
              if (d.data!.data()!['banned'] == true) return const BannedScreen();
              return const HomeScreen();
            },
          );
        },
      );
}

class BannedScreen extends StatelessWidget {
  const BannedScreen({super.key});
  @override
  Widget build(BuildContext context) => Scaffold(
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(mainAxisSize: MainAxisSize.min, children: [
              const Icon(Icons.block, size: 72, color: Colors.red),
              const SizedBox(height: 16),
              const Text('تم حظر حسابك من قبل الإدارة', style: TextStyle(fontSize: 18)),
              const SizedBox(height: 16),
              FilledButton(onPressed: () => auth.signOut(), child: const Text('تسجيل الخروج')),
            ]),
          ),
        ),
      );
}