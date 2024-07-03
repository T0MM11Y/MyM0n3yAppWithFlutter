import 'package:flutter/material.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:mymoney/pages/main_page.dart';

void main() async {
  await initializeDateFormatting('id_ID', null);
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: MainPage(),
      theme: ThemeData(
        primaryColor: Color.fromARGB(255, 38, 155, 153),
      ),
    );
  }
}
