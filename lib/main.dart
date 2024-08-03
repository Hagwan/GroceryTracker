import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:provider/provider.dart';
import 'firebase_options.dart';
import 'home_page.dart';
import 'theme_provider.dart';
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
    return ChangeNotifierProvider(
      create: (context) => ThemeProvider(),
      child: Consumer<ThemeProvider>(
        builder: (context, themeProvider, child) {
          return MaterialApp(
            debugShowCheckedModeBanner: false,
            title: 'Grocery Tracker',
            theme: ThemeData(
              brightness: Brightness.light,
              primarySwatch: Colors.blue,
            ),
            darkTheme: ThemeData(
              brightness: Brightness.dark,
              primarySwatch: Colors.blue,
            ),
            themeMode: themeProvider.themeMode,
            home: FlutterSplashScreen(
              useImmersiveMode: true,
              duration: const Duration(milliseconds: 2000),
              nextScreen: MyHomePage(),
              backgroundColor: Colors.black87,
              splashScreenBody: Center(
                child: Lottie.asset(
                  "images/Animation - 1722683529126.json",
                  repeat: false,
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
