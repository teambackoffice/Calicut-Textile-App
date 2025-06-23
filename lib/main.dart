// main.dart
import 'package:calicut_textile_app/controller/login_controller.dart';
import 'package:calicut_textile_app/view/login_screen/login_page.dart';
import 'package:calicut_textile_app/view/main_screen/homepage.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';


void main() {
  runApp(
    
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => LoginController()),
      ],
      child: MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: Homepage(),
    );
  }
}
