import 'package:flutter/material.dart';
import 'screens/join_screen.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'LiveServer Client',
      theme: ThemeData.dark().copyWith(
        primaryColor: Colors.blueGrey,
        scaffoldBackgroundColor: const Color(0xFF222222),
        colorScheme: const ColorScheme.dark(
          primary: Colors.blue,
          secondary: Colors.greenAccent,
        ),
      ),
      home: const JoinScreen(),
      debugShowCheckedModeBanner: false,
    );
  }
}
