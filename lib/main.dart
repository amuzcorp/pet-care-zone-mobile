import 'package:flutter/material.dart';
import 'package:petcarezone/pages/product_connection/0_login_page.dart';
import 'package:petcarezone/pages/product_connection/1_power_check_page.dart';
import 'package:petcarezone/services/user_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  MyAppState createState() => MyAppState();
}

class MyAppState extends State<MyApp> {
  final UserService userService = UserService();
  late Future<Widget> _initialPage;

  @override
  void initState() {
    super.initState();
    _initialPage = userService.initializeApp();
  }
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      theme: ThemeData(
        fontFamily: 'LG_Smart_UI',
        primarySwatch: Colors.blue,
      ),
      home: FutureBuilder<Widget>(
        future: _initialPage,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Scaffold(
              body: Center(child: CircularProgressIndicator()),
            );
          } else if (snapshot.hasError) {
            return const Scaffold(
              body: Center(child: Text('Error initializing app')),
            );
          } else {
            return snapshot.data ?? const LoginPage();
          }
        },
      ),
      onGenerateRoute: (settings) {
        switch (settings.name) {
          case '/PowerCheck':
            return MaterialPageRoute(builder: (_) => const PowerCheckPage());
          case '/login':
          default:
            return MaterialPageRoute(builder: (_) => const LoginPage());
        }
      },
    );
  }
}
