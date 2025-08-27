import 'package:flutter/material.dart';
import 'package:app_privacy_guard/app_privacy_guard.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await AppPrivacyGuard.instance.showWatermark(
    assetName: 'logo_beepul_horizontal_dark', // iOS Assets.xcassets
    size: 60,
    offsetY: -72,
    alpha: 1,
  );
  AppPrivacyGuard.instance.startAuto(mode: PrivacyMode.blur); // or PrivacyMode.secure (Android)

  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        appBar: AppBar(title: const Text('Plugin example app')),
        body: Center(
          child: Container(
            height: 300,
            width: 300,
            decoration: BoxDecoration(color: Colors.red),
            child: Text('Running on'),
          ),
        ),
      ),
    );
  }
}
