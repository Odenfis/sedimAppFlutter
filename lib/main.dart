import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:sedim_app/screens/screens.dart';

void main() => runApp(const MyApp());

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Sedimcorp App',
      theme: ThemeData(
        brightness: Brightness.dark,
        primarySwatch: Colors.blue,
        textTheme: GoogleFonts.poppinsTextTheme(),
        useMaterial3: true
      ),
      home: LoginScreen(),
    );
  }
}