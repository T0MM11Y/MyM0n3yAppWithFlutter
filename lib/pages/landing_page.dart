import 'package:flutter/material.dart';
import 'package:mymoney/pages/main_page.dart';

void main() => runApp(MyApp());

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: LandingPage(
        duration:
            const Duration(milliseconds: 2000), // Menentukan durasi animasi
        nextRoute: MaterialPageRoute(
            builder: (context) => MainPage()), // Menentukan rute selanjutnya
      ),
    );
  }
}

class LandingPage extends StatefulWidget {
  final Duration duration; // Properti duration
  final Route nextRoute; // Properti nextRoute

  const LandingPage({
    Key? key,
    required this.duration,
    required this.nextRoute,
  }) : super(key: key);

  @override
  _LandingPageState createState() => _LandingPageState();
}

class _LandingPageState extends State<LandingPage> {
  @override
  void initState() {
    super.initState();
    Future.delayed(widget.duration, () {
      Navigator.of(context).pushReplacement(widget.nextRoute);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white, // Set background color to white
      body: Center(
        child: Image.asset(
          'assets/money.gif',
          width: 300,
          height: 300,
        ),
      ),
    );
  }
}
