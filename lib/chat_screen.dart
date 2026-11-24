import 'dart:io';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'services.dart';
import 'users_list.dart';

class ChatScreen extends StatefulWidget {
  final Map<String, dynamic> other;
  const ChatScreen({super.key, required this.other});
  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final _ctrl = TextEditingController();
  Map<String, dynamic>? _reply;
  bool _sending = false;
  late final String _chatId = chatIdFor(myUid, widget.other['uid']);

  void _toast(String m) =>
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(m)));

  Future<void> _send({File? image}) async {
    final text = _ctrl.text.trim();
    if (text.isEmpty && image == null) return;
    final reply = _reply;
    _ctrl.clear();
    setState(() {
      _reply = null;
      _sending = true;
    });
    try {
      await sendMessage(
          otherUid: widget.other['uid'], text: text, image: image, replyTo: reply);
    } catch (e) {
      if (mounted) _toast('فشل الإرسال: $e');
    }
    if (mounted) setState(() => _sending = false);
  }

  Future<void> _pickImage() async {
    final x = await ImagePicker()
        .pickImage(source: ImageSource.gallery, imageQuality: 75, maxWidth: 1600);
    if (x != null) await _send(image: File(x.path));
  }

  Future<void> _forward(Map<String, dynamic> m) async {
    final target = await Navigator.push<Map<String, dynamic>>(
      context,
      MaterialPageRoute(
        builder: (ctx) => Scaffold(
          appBar: AppBar(title: const Text('توجيه إلى...')),
          body: UsersList(onTap: (u) => Navigator.pop(ctx, u)),
        ),
      ),
    );
    if (target == null) return;
    try {
      await sendMessage(
        otherUid: target['uid'],
        text: m['text'] ?? '',
        imageUrl: m['imageUrl'],
        forwarded: true,
      );
      if (mounted) _toast('تم التوجيه إلى ${target['name']}');
    } catch (e) {
      if (mounted) _toast('فشل التوجيه: $e');
    }
  }

  void _menu(String id, Map<String, dynamic> m) {
    final mine = m['senderId'] == myUid;
    final hasText = (m['text'] ?? '').toString().isNotEmpty;
    showModalBottomSheet(
      context: context,
      builder: (ctx) => SafeArea(
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          ListTile(
            leading: const Icon(Icons.reply),
            title: const Text('رد'),
            onTap: () {
              Navigator.pop(ctx);
              setState(() => _reply = {
                    'id': id,
                    'text': hasText ? m['text'] : '📷 صورة',
                    'senderName': mine ? 'أنت' : widget.other['name'],
                  });
            },
          ),
          ListTile(
            leading: const Icon(Icons.forward),
            title: const Text('توجيه'),
            onTap: () {
              Navigator.pop(ctx);
              _forward(m);
            },
          ),
          if (hasText)
            ListTile(
              leading: const Icon(Icons.copy),
              title: const Text('نسخ'),
              onTap: () {
                Clipboard.setData(ClipboardData(text: m['text']));
                Navigator.pop(ctx);
              },
            ),
          if (mine)
            ListTile(
              leading: const Icon(Icons.delete, color: Colors.red),
              title: const Text('حذف'),
              onTap: () {
                Navigator.pop(ctx);
                db
                    .collection('chats')
                    .doc(_chatId)
                    .collection('messages')
                    .doc(id)
                    .delete();
              },
            ),
        ]),
      ),
    );
  }

  Widget _bubble(String id, Map<String, dynamic> m) {
    final mine = m['senderId'] == myUid;
    final reply = m['replyTo'] as Map<String, dynamic>?;
    final img = m['imageUrl'] as String?;
    final text = (m['text'] ?? '') as String;
    final ts = (m['createdAt'] as Timestamp?)?.toDate();
    return Align(
      alignment: mine ? AlignmentDirectional.centerStart : AlignmentDirectional.centerEnd,
      child: GestureDetector(
        onLongPress: () => _menu(id, m),
        child: Container(
          constraints:
              BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.78),
          margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(
            color: mine ? const Color(0xFFD9FDD3) : Colors.white,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            if (m['forwarded'] == true)
              const Row(mainAxisSize: MainAxisSize.min, children: [
                Icon(Icons.forward, size: 14, color: Colors.grey),
                SizedBox(width: 4),
                Text('تم التوجيه',
                    style: TextStyle(
                        fontSize: 11, fontStyle: FontStyle.italic, color: Colors.grey)),
              ]),
            if (reply != null)
              Container(
                width: double.infinity,
                margin: const EdgeInsets.only(bottom: 4),
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.06),
                  borderRadius: BorderRadius.circular(6),
                  border: const BorderDirectional(
                      start: BorderSide(color: Color(0xFF128C7E), width: 4)),
                ),
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(reply['senderName'] ?? '',
                      style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF128C7E))),
                  Text(reply['text'] ?? '',
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontSize: 13)),
                ]),
              ),
            if (img != null)
              GestureDetector(
                onTap: () => Navigator.push(context,
                    MaterialPageRoute(builder: (_) => ImageViewer(url: img))),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: CachedNetworkImage(
                    imageUrl: img,
                    placeholder: (c, u) => const SizedBox(
                        height: 150,
                        child: Center(child: CircularProgressIndicator())),
                  ),
                ),
              ),
            if (text.isNotEmpty)
              Padding(
                  padding: const EdgeInsets.fromLTRB(4, 2, 4, 0),
                  child: Text(text, style: const TextStyle(fontSize: 16))),
            if (ts != null)
              Padding(
                padding: const EdgeInsets.only(top: 2, left: 4, right: 4),
                child: Text(TimeOfDay.fromDateTime(ts).format(context),
                    style: const TextStyle(fontSize: 10, color: Colors.grey)),
              ),
          ]),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(
          titleSpacing: 0,
          title: Row(children: [
            Avatar(url: widget.other['photoUrl'], name: widget.other['name'], radius: 18),
            const SizedBox(width: 10),
            Text(widget.other['name']),
          ]),
        ),
        backgroundColor: const Color(0xFFECE5DD),
        body: Column(children: [
          Expanded(
            child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
              stream: db
                  .collection('chats')
                  .doc(_chatId)
                  .collection('messages')
                  .orderBy('createdAt', descending: true)
                  .snapshots(),
              builder: (c, s) {
                if (!s.hasData) return const Center(child: CircularProgressIndicator());
                final docs = s.data!.docs;
                if (docs.isEmpty) return const Center(child: Text('ابدأ المحادثة 👋'));
                return ListView.builder(
                  reverse: true,
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  itemCount: docs.length,
                  itemBuilder: (c, i) => _bubble(docs[i].id, docs[i].data()),
                );
              },
            ),
          ),
          if (_sending) const LinearProgressIndicator(minHeight: 2),
          if (_reply != null)
            Container(
              color: Colors.white,
              padding: const EdgeInsets.fromLTRB(12, 6, 4, 6),
              child: Row(children: [
                const Icon(Icons.reply, color: Color(0xFF128C7E)),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text('الرد على ${_reply!['senderName']}',
                        style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF128C7E))),
                    Text(_reply!['text'],
                        maxLines: 1, overflow: TextOverflow.ellipsis),
                  ]),
                ),
                IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => setState(() => _reply = null)),
              ]),
            ),
          SafeArea(
            child: Container(
              color: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
              child: Row(children: [
                IconButton(
                    icon: const Icon(Icons.image, color: Color(0xFF128C7E)),
                    onPressed: _sending ? null : _pickImage),
                Expanded(
                  child: TextField(
                    controller: _ctrl,
                    minLines: 1,
                    maxLines: 5,
                    textInputAction: TextInputAction.newline,
                    decoration: const InputDecoration(
                        hintText: 'اكتب رسالة', border: InputBorder.none),
                  ),
                ),
                IconButton(
                    icon: const Icon(Icons.send, color: Color(0xFF128C7E)),
                    onPressed: _sending ? null : () => _send()),
              ]),
            ),
          ),
        ]),
      );
}

class ImageViewer extends StatelessWidget {
  final String url;
  const ImageViewer({super.key, required this.url});
  @override
  Widget build(BuildContext context) => Scaffold(
        backgroundColor: Colors.black,
        appBar: AppBar(backgroundColor: Colors.black, foregroundColor: Colors.white),
        body: Center(
            child: InteractiveViewer(child: CachedNetworkImage(imageUrl: url))),
      );
}
