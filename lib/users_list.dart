import 'package:cached_network_image/cached_network_image.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'services.dart';

class Avatar extends StatelessWidget {
  final String? url;
  final String name;
  final double radius;
  const Avatar({super.key, this.url, required this.name, this.radius = 22});

  @override
  Widget build(BuildContext context) => CircleAvatar(
        radius: radius,
        backgroundImage: url != null ? CachedNetworkImageProvider(url!) : null,
        child: url == null
            ? Text(name.isEmpty ? '?' : name[0].toUpperCase(),
                style: TextStyle(fontSize: radius * 0.8))
            : null,
      );
}

/// قائمة المستخدمين مع بحث؛ تُستخدم للدردشة الجديدة وللتوجيه
class UsersList extends StatefulWidget {
  final void Function(Map<String, dynamic> user) onTap;
  const UsersList({super.key, required this.onTap});
  @override
  State<UsersList> createState() => _UsersListState();
}

class _UsersListState extends State<UsersList> {
  String _q = '';

  @override
  Widget build(BuildContext context) => Column(children: [
        Padding(
          padding: const EdgeInsets.all(8),
          child: TextField(
            onChanged: (v) => setState(() => _q = v.trim().toLowerCase()),
            decoration: const InputDecoration(
                prefixIcon: Icon(Icons.search),
                hintText: 'ابحث بالاسم',
                border: OutlineInputBorder()),
          ),
        ),
        Expanded(
          child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
            stream: db.collection('users').snapshots(),
            builder: (c, s) {
              if (!s.hasData) return const Center(child: CircularProgressIndicator());
              final users = s.data!.docs
                  .map((d) => d.data())
                  .where((u) =>
                      u['uid'] != myUid &&
                      u['banned'] != true &&
                      (u['name'] as String).toLowerCase().contains(_q))
                  .toList();
              if (users.isEmpty) return const Center(child: Text('لا يوجد مستخدمون'));
              return ListView.builder(
                itemCount: users.length,
                itemBuilder: (c, i) {
                  final u = users[i];
                  return ListTile(
                    leading: Avatar(url: u['photoUrl'], name: u['name']),
                    title: Text(u['name']),
                    onTap: () => widget.onTap(u),
                  );
                },
              );
            },
          ),
        ),
      ]);
}
