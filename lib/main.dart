import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:sedim_app/providers/theme_provider.dart';
import 'package:sedim_app/screens/screens.dart';

void main() {
  runApp(
    //Inyectamos el proveedor del tema antes de que nazca la app
    ChangeNotifierProvider(
      create: (_) => ThemeProvider(),
      child: MyApp(),
    )
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    //Escuchamos los cambios de tema
    final themeProvider = Provider.of<ThemeProvider>(context);

    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Sedimcorp App',
      //integro modo tema: usa depende del provider
      themeMode: themeProvider.isDark ? ThemeMode.dark : ThemeMode.light,
      //Se define tema claro
      //TODO: MINIMIZAR ESTO!!!
      theme: ThemeData(        
        brightness: Brightness.light,
        scaffoldBackgroundColor: Color(0xFFF4F6F8),
        primarySwatch: Colors.blue,
        appBarTheme: AppBarTheme(
          backgroundColor: Colors.white,
          foregroundColor: Color(0xFF2c5484),
          elevation: 1,
        ),
        cardColor: Colors.white,
        textTheme: GoogleFonts.poppinsTextTheme(ThemeData.light().textTheme),
        useMaterial3: true
      ),
      //se define tema oscuro
      darkTheme: ThemeData(
        brightness: Brightness.dark,
        scaffoldBackgroundColor: Color(0xFF0f1012),
        primarySwatch: Colors.blue,
        appBarTheme: AppBarTheme(
          backgroundColor: Color(0xFF1e1e1e),
          foregroundColor: Colors.white,
          elevation: 0,
        ),
        cardColor: Color(0xFF1e1e1e),
        textTheme: GoogleFonts.poppinsTextTheme(ThemeData.dark().textTheme),
        useMaterial3: true

      ),
      home: LoginScreen(),
    );
  }
}