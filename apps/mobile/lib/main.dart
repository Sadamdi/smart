import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

void main() {
  runApp(const ProviderScope(child: SmartApp()));
}

class SmartApp extends StatelessWidget {
  const SmartApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'SMART',
      theme: ThemeData(colorSchemeSeed: const Color(0xFF2563A8), useMaterial3: true),
      home: const Scaffold(
        body: Center(
          child: Padding(
            padding: EdgeInsets.all(24),
            child: Text(
              'SMART\nAplikasi sedang dibangun; layar ini hanya kerangka awal.',
              textAlign: TextAlign.center,
            ),
          ),
        ),
      ),
    );
  }
}
