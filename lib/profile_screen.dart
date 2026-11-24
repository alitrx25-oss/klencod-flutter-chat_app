import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'services.dart';
import 'users_list.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});
  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final _name = TextEditingController();
  bool _init = false, _busy = false;

  void _toast(String m) =>
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(m)));

  Future<void> _changePhoto() async {
    final x = await ImagePicker()
        .pickImage(source: ImageSource.gallery, imageQuality: 80, maxWidth: 800);
    if (x == null) return;
    setState(() => _busy = true);
    try {
      final url = await uploadFile(File(x.path), 'profile_pics/$myUid.jpg');
      // رقم الوقت لتجنّب عرض الصورة القديمة من الكاش
      await db.collection('users').doc(myUid).update(
          {'photoUrl': '$url&t=${DateTime.now().millisecondsSinceEpoch}'});
    } catch (e) {
      if (mounted) _toast('فشل رفع الصورة: $e');
    }
    if (mounted) setState(() => _busy = false);
  }

  Future<void> _removePhoto() async {
    await db.collection('users').doc(myUid).update({'photoUrl': null});
  }

  Future<void> _saveName() async {
    final n = _name.text.trim();
    if (n.isEmpty) return;
    await db.collection('users').doc(myUid).update({'name': n});
    if (mounted) _toast('تم الحفظ');
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(title: const Text('الملف الشخصي')),
        body: StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
          stream: db.collection('users').doc(myUid).snapshots(),
          builder: (c, s) {
            final u = s.data?.data();
            if (u == null) return const Center(child: CircularProgressIndicator());
            if (!_init) {
              _name.text = u['name'];
              _init = true;
            }
            return ListView(padding: const EdgeInsets.all(24), children: [
              Center(
                child: Stack(children: [
                  Avatar(url: u['photoUrl'], name: u['name'], radius: 60),
                  Positioned(
                    bottom: 0,
                    left: 0,
                    child: CircleAvatar(
                      backgroundColor: Theme.of(context).colorScheme.primary,
                      child: _busy
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(
                                  strokeWidth: 2, color: Colors.white))
                          : IconButton(
                              icon: const Icon(Icons.camera_alt, color: Colors.white),
                              onPressed: _changePhoto),
                    ),
                  ),
                ]),
              ),
              if (u['photoUrl'] != null)
                TextButton(onPressed: _removePhoto, child: const Text('حذف الصورة')),
              const SizedBox(height: 16),
              TextField(
                  controller: _name,
                  decoration: const InputDecoration(
                      labelText: 'الاسم', border: OutlineInputBorder())),
              const SizedBox(height: 12),
              Text(u['email'] ?? '', textAlign: TextAlign.center),
              const SizedBox(height: 16),
              FilledButton(onPressed: _saveName, child: const Text('حفظ الاسم')),
              const SizedBox(height: 12),
              OutlinedButton.icon(
                icon: const Icon(Icons.logout),
                label: const Text('تسجيل الخروج'),
                onPressed: () {
                  Navigator.pop(context);
                  auth.signOut();
                },
              ),
            ]);
          },
        ),
      );
}
