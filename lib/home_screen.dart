import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'chat_screen.dart';
import 'profile_screen.dart';
import 'services.dart';
import 'users_list.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(
          title: const Text('الدردشات'),
          actions: [
            StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
              stream: db.collection('users').doc(myUid).snapshots(),
              builder: (c, s) {
                final u = s.data?.data();
                return IconButton(
                  icon: Avatar(url: u?['photoUrl'], name: u?['name'] ?? '', radius: 16),
                  onPressed: () => Navigator.push(context,
                      MaterialPageRoute(builder: (_) => const ProfileScreen())),
                );
              },
            ),
          ],
        ),
        body: UsersList(
          onTap: (u) => Navigator.push(
              context, MaterialPageRoute(builder: (_) => ChatScreen(other: u))),
        ),
      );
}
