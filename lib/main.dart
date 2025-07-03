import 'package:calicut_textile_app/controller/add_supplier_order_controller.dart';
import 'package:calicut_textile_app/controller/get_all_types_controller.dart';
import 'package:calicut_textile_app/controller/get_colours_controller.dart';
import 'package:calicut_textile_app/controller/get_designs_controller.dart';
import 'package:calicut_textile_app/controller/get_supplier_orders_controller.dart';
import 'package:calicut_textile_app/controller/login_controller.dart';
import 'package:calicut_textile_app/controller/product_controller.dart';
import 'package:calicut_textile_app/controller/supplier_group_controller.dart';
import 'package:calicut_textile_app/controller/supplier_list_controller.dart';
import 'package:calicut_textile_app/view/login_screen/login_page.dart';
import 'package:calicut_textile_app/view/main_screen/homepage.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => LoginController()),
        ChangeNotifierProvider(create: (_) => SuppliersController()),
        ChangeNotifierProvider(create: (_) => ProductListController()),
        ChangeNotifierProvider(create: (_) => CreateSupplierOrderController()),
        ChangeNotifierProvider(create: (_) => SupplierOrderController()),
        ChangeNotifierProvider(create: (_) => SupplierProvider()),
        ChangeNotifierProvider(create: (_) => ColorsController()),
        ChangeNotifierProvider(create: (_) => DesignsController()),
        ChangeNotifierProvider(create: (_) => TextileTypesController()),
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
      home: SplashScreen(), // 👈 Start with a splash/loading screen
    );
  }
}

class SplashScreen extends StatefulWidget {
  @override
  _SplashScreenState createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _checkLoginStatus();
  }

  Future<void> _checkLoginStatus() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    bool isLoggedIn = prefs.getBool('isLoggedIn') ?? false;

    // Delay for splash effect (optional)
    await Future.delayed(Duration(seconds: 1));

    if (isLoggedIn) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => Homepage()),
      );
    } else {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => LoginScreen()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(child: Image.asset('assets/calicutlogo.png',width: 200, height: 200)), // Simple loading indicator
    );
  }
}
