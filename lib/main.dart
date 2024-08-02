import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'firebase_options.dart'; // Ensure this import matches the generated file location
import 'home_page.dart';
import 'package:another_flutter_splash_screen/another_flutter_splash_screen.dart';
import 'package:lottie/lottie.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
        debugShowCheckedModeBanner: false,
        title: 'Grocery Tracker',
        theme: ThemeData(
          primarySwatch: Colors.blue,
        ),
        home: FlutterSplashScreen(
          useImmersiveMode: true,
          duration: const Duration(milliseconds: 5000),
          nextScreen: MyHomePage(),
          backgroundColor: Colors.white,
          splashScreenBody: Center(
            child: Lottie.asset(
              "images/Animation2.json",
              repeat: false,
            ),
          ),
        ));
  }
}
