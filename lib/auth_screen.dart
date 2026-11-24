import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'services.dart';

class AuthScreen extends StatefulWidget {
  const AuthScreen({super.key});
  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  final _email = TextEditingController();
  final _pass = TextEditingController();
  final _name = TextEditingController();
  bool _register = false, _busy = false;

  void _toast(String m) =>
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(m)));

  Future<void> _submit() async {
    setState(() => _busy = true);
    try {
      if (_register) {
        if (_name.text.trim().isEmpty) throw 'اكتب اسمك';
        final cred = await auth.createUserWithEmailAndPassword(
            email: _email.text.trim(), password: _pass.text);
        await db.collection('users').doc(cred.user!.uid).set({
          'uid': cred.user!.uid,
          'name': _name.text.trim(),
          'email': _email.text.trim(),
          'photoUrl': null,
          'isAdmin': false,
          'banned': false,
          'createdAt': FieldValue.serverTimestamp(),
        });
      } else {
        await auth.signInWithEmailAndPassword(
            email: _email.text.trim(), password: _pass.text);
      }
    } on FirebaseAuthException catch (e) {
      if (mounted) _toast(e.message ?? e.code);
    } catch (e) {
      if (mounted) _toast('$e');
    }
    if (mounted) setState(() => _busy = false);
  }

  Future<void> _reset() async {
    if (_email.text.trim().isEmpty) return _toast('اكتب الإيميل أولًا');
    await auth.sendPasswordResetEmail(email: _email.text.trim());
    if (mounted) _toast('تم إرسال رابط استعادة كلمة المرور');
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        body: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Column(children: [
                const Icon(Icons.chat, size: 72, color: Color(0xFF128C7E)),
                const SizedBox(height: 8),
                Text(_register ? 'إنشاء حساب' : 'تسجيل الدخول',
                    style: Theme.of(context).textTheme.headlineSmall),
                const SizedBox(height: 24),
                if (_register) ...[
                  TextField(
                      controller: _name,
                      decoration: const InputDecoration(
                          labelText: 'الاسم', border: OutlineInputBorder())),
                  const SizedBox(height: 12),
                ],
                TextField(
                    controller: _email,
                    keyboardType: TextInputType.emailAddress,
                    decoration: const InputDecoration(
                        labelText: 'الإيميل', border: OutlineInputBorder())),
                const SizedBox(height: 12),
                TextField(
                    controller: _pass,
                    obscureText: true,
                    decoration: const InputDecoration(
                        labelText: 'كلمة المرور', border: OutlineInputBorder())),
                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton(
                    onPressed: _busy ? null : _submit,
                    child: _busy
                        ? const SizedBox(
                            height: 18,
                            width: 18,
                            child: CircularProgressIndicator(strokeWidth: 2))
                        : Text(_register ? 'تسجيل' : 'دخول'),
                  ),
                ),
                TextButton(
                    onPressed: () => setState(() => _register = !_register),
                    child: Text(_register
                        ? 'عندي حساب بالفعل'
                        : 'مفيش حساب؟ أنشئ حساب جديد')),
                if (!_register)
                  TextButton(onPressed: _reset, child: const Text('نسيت كلمة المرور')),
              ]),
            ),
          ),
        ),
      );
}
