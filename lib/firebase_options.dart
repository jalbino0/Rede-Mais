import 'package:firebase_core/firebase_core.dart'
    show FirebaseOptions;
import 'package:flutter/foundation.dart'
    show TargetPlatform, defaultTargetPlatform, kIsWeb;

class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    if (kIsWeb) {
      throw UnsupportedError(
        'Firebase não está configurado para Web.',
      );
    }

    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return android;
      case TargetPlatform.iOS:
        throw UnsupportedError(
          'Firebase não está configurado para iOS.',
        );
      case TargetPlatform.macOS:
        throw UnsupportedError(
          'Firebase não está configurado para macOS.',
        );
      case TargetPlatform.windows:
        throw UnsupportedError(
          'Firebase não está configurado para Windows.',
        );
      case TargetPlatform.linux:
        throw UnsupportedError(
          'Firebase não está configurado para Linux.',
        );
      default:
        throw UnsupportedError(
          'Plataforma não suportada.',
        );
    }
  }

  static const FirebaseOptions android =
      FirebaseOptions(
    apiKey:
        'AIzaSyCdOcmf_kNYC0aSG9UYlfXTT2UdEYdbdro',
    appId:
        '1:999853208663:android:f66dc1f9d903b19db89f12',
    messagingSenderId:
        '999853208663',
    projectId:
        'rede-mais-app',
    storageBucket:
        'rede-mais-app.firebasestorage.app',
  );
}
