# تطبيق شات (Flutter + Firebase) — شبيه بواتساب

## المميزات
تسجيل/دخول بالإيميل • رسائل نصية وصور • الرد على رسالة • توجيه رسالة • نسخ/حذف •
صورة بروفايل وتغيير الاسم • حظر المستخدمين • لوحة تحكم أدمن (ويب)

## خطوات التشغيل

1. ثبّت Flutter ثم ادخل مجلد المشروع ونفّذ (يولّد مجلدات android وغيرها):
   flutter create --org com.example --project-name chat_app .
   flutter pub get

2. أنشئ مشروعًا في https://console.firebase.google.com وفعّل:
   - Authentication > Sign-in method > Email/Password
   - Firestore Database
   - Storage

3. اربط التطبيق بالمشروع (يولّد lib/firebase_options.dart):
   dart pub global activate flutterfire_cli
   flutterfire configure

4. انشر قواعد الأمان:
   npm i -g firebase-tools && firebase login
   firebase use <PROJECT_ID>
   firebase deploy --only firestore:rules,storage

5. شغّل التطبيق وسجّل حسابك الأول، ثم من Firebase Console > Firestore > users
   افتح مستندك وغيّر isAdmin إلى true (أول أدمن يُعيَّن يدويًا).

6. لوحة الأدمن: افتح admin/index.html وضع إعدادات Web app الخاصة بمشروعك في firebaseConfig،
   وشغّلها محليًا (مثلًا: cd admin && python3 -m http.server 8000) أو انشرها بـ Firebase Hosting.

7. بناء الـ APK:
   flutter build apk --release
   الملف: build/app/outputs/flutter-apk/app-release.apk

## ملاحظات
- الأدمن يرى المستخدمين وعدد المحادثات ويحظر/يرقّي/يحذف بيانات المستخدم، ولا يقرأ محتوى الرسائل (خصوصية).
- حذف حساب الدخول نفسه يتم من Authentication في الـ Console.
- لو ظهر خطأ minSdk: اجعل minSdk = 23 في android/app/build.gradle.
