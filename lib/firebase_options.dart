// Этот файл — заглушка. Сгенерируйте настоящий файл командой:
//   flutterfire configure
// (после `firebase login` и `flutter pub global activate flutterfire_cli`)
// Это создаст правильные значения apiKey/appId/projectId для Android, iOS,
// Web и т.д. и подключит один и тот же Firebase-проект к обоим приложениям
// (клиент и админ), что и требуется — они должны использовать общую базу.

import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, TargetPlatform;

class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return android;
      case TargetPlatform.iOS:
        return ios;
      default:
        return web;
    }
  }

  static const FirebaseOptions web = FirebaseOptions(
    apiKey: 'REPLACE_ME',
    appId: 'REPLACE_ME',
    messagingSenderId: 'REPLACE_ME',
    projectId: 'parkmap-project',
    authDomain: 'parkmap-project.firebaseapp.com',
    storageBucket: 'parkmap-project.appspot.com',
  );

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyAKxDp1AMoJ5q7u5AHddnaqXD0Cw8EECSY',
    appId: '1:981606727738:android:8031786852dfeff2473503',
    messagingSenderId: '981606727738',
    projectId: 'pro-e5c75',
    storageBucket: 'pro-e5c75.firebasestorage.app',
  );
  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'REPLACE_ME',
    appId: 'REPLACE_ME',
    messagingSenderId: 'REPLACE_ME',
    projectId: 'parkmap-project',
    storageBucket: 'parkmap-project.appspot.com',
    iosBundleId: 'com.example.parkmapAdmin',
  );
}
