import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_functions/cloud_functions.dart';

import 'firebase_options.dart';
import 'app.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  // Use local Functions emulator when running locally
  FirebaseFunctions.instance.useFunctionsEmulator('127.0.0.1', 5001);
  runApp(const ProviderScope(child: HeroBidApp()));
}
