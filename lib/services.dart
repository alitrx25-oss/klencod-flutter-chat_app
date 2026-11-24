import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';

final db = FirebaseFirestore.instance;
final auth = FirebaseAuth.instance;
String get myUid => auth.currentUser!.uid;

/// معرّف المحادثة ثابت بين شخصين (الأصغر_الأكبر)
String chatIdFor(String a, String b) {
  final l = [a, b]..sort();
  return l.join('_');
}

Future<String> uploadFile(File f, String path) async {
  final ref = FirebaseStorage.instance.ref(path);
  await ref.putFile(f);
  return ref.getDownloadURL();
}

/// إرسال رسالة (نص / صورة / رد / توجيه)
Future<void> sendMessage({
  required String otherUid,
  String text = '',
  File? image,
  String? imageUrl,
  Map<String, dynamic>? replyTo,
  bool forwarded = false,
}) async {
  final chatId = chatIdFor(myUid, otherUid);
  final chatRef = db.collection('chats').doc(chatId);
  final msgRef = chatRef.collection('messages').doc();
  String? url = imageUrl;
  if (image != null) {
    url = await uploadFile(image, 'chat_images/$chatId/${msgRef.id}.jpg');
  }
  await chatRef.set({
    'members': [myUid, otherUid],
    'lastMessage': text.isNotEmpty ? text : '📷 صورة',
    'updatedAt': FieldValue.serverTimestamp(),
  }, SetOptions(merge: true));
  await msgRef.set({
    'senderId': myUid,
    'text': text,
    'imageUrl': url,
    'replyTo': replyTo,
    'forwarded': forwarded,
    'createdAt': FieldValue.serverTimestamp(),
  });
}
