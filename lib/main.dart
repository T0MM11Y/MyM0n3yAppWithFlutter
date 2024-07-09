import 'package:flutter/material.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:mymoney/pages/main_page.dart';
import 'package:mymoney/pages/landing_page.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initializeDateFormatting('id_ID', null);
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: LandingPage(
        duration: const Duration(milliseconds: 2000),
        nextRoute: MaterialPageRoute(builder: (context) => MainPage()),
      ),
      theme: ThemeData(
        primaryColor: const Color.fromARGB(255, 38, 155, 153),
      ),
    );
  }
}
