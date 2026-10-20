import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:sedim_app/models/user_model.dart';
import 'package:sedim_app/providers/company_provider.dart';
import 'package:sedim_app/providers/theme_provider.dart';
import 'package:sedim_app/providers/user_provider.dart';
import 'package:sedim_app/screens/screens.dart';
import 'package:sedim_app/services/api_service.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  final userProvider = UserProvider();
  final companyProvider = CompanyProvider();
  runApp(
    //Inyectamos los proveedores globales antes de que nazca la app
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => ThemeProvider()),
        ChangeNotifierProvider<UserProvider>.value(value: userProvider),
        ChangeNotifierProvider<CompanyProvider>.value(value: companyProvider),
      ],
      child: MyApp(userProvider: userProvider, companyProvider: companyProvider),
    )
  );
}

class MyApp extends StatefulWidget {
  final UserProvider userProvider;
  final CompanyProvider companyProvider;

  const MyApp({super.key, required this.userProvider, required this.companyProvider});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  Future<UserModel?>? _restauracion;

  @override
  void initState() {
    super.initState();
    //Restauramos la sesión persistida (tokens JWT + usuario) al arrancar
    _restauracion = widget.userProvider.restoreSession().then((usuario) {
      //Si había sesión, sincronizamos también las empresas autorizadas
      if (usuario != null && usuario.empresas.isNotEmpty) {
        widget.companyProvider.setEmpresas(usuario.empresas);
      }
      return usuario;
    });
    //Si el refresh token expira/revoca en caliente, volvemos al login
    ApiService.sesionInvalidada.addListener(_alExpirarSesion);
  }

  @override
  void dispose() {
    ApiService.sesionInvalidada.removeListener(_alExpirarSesion);
    super.dispose();
  }

  void _alExpirarSesion() {
    if (!mounted) return;
    Navigator.of(context, rootNavigator: true).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const LoginScreen()),
      (route) => false,
    );
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Tu sesión expiró. Inicia sesión nuevamente')),
    );
  }

  @override
  Widget build(BuildContext context) {
    //Escuchamos los cambios de tema
    final themeProvider = Provider.of<ThemeProvider>(context);

    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Sedimcorp App',
      //integro modo tema: usa depende del provider
      themeMode: themeProvider.isDark ? ThemeMode.dark : ThemeMode.light,
      theme: AppTheme.light,
      darkTheme: AppTheme.dark,
      //Pantalla de arranque: splash mientras se restaura sesión,
      //HomeScreen si hay sesión activa, LoginScreen en caso contrario
      home: FutureBuilder<UserModel?>(
        future: _restauracion,
        builder: (context, snapshot) {
          if (snapshot.connectionState != ConnectionState.done) {
            return const _SplashScreen();
          }
          //Sesión restaurada (tokens persistidos) -> Home; si no -> Login
          final usuarioRestaurado = snapshot.data;
          return usuarioRestaurado != null ? const HomeScreen() : const LoginScreen();
        },
      ),
    );
  }
}

/// Splash simple mostrado mientras se restaura la sesión persistida.
class _SplashScreen extends StatelessWidget {
  const _SplashScreen();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Image.asset('assets/logo.png', height: 80),
            ),
            const SizedBox(height: 30),
            const CircularProgressIndicator(),
          ],
        ),
      ),
    );
  }
}

class AppTheme {
  AppTheme._();

  static const _brandBlue = Color(0xFF2c5484);
  static const _scaffoldLight = Color(0xFFF4F6F8);
  static const _scaffoldDark = Color(0xFF0f1012);
  static const _cardDark = Color(0xFF1e1e1e);

  //Se define tema claro
  static final ThemeData light = ThemeData(
    brightness: Brightness.light,
    scaffoldBackgroundColor: _scaffoldLight,
    primarySwatch: Colors.blue,
    appBarTheme: const AppBarTheme(
      backgroundColor: Colors.white,
      foregroundColor: _brandBlue,
      elevation: 1,
    ),
    cardColor: Colors.white,
    textTheme: GoogleFonts.poppinsTextTheme(ThemeData.light().textTheme),
    useMaterial3: true,
  );

  //se define tema oscuro
  static final ThemeData dark = ThemeData(
    brightness: Brightness.dark,
    scaffoldBackgroundColor: _scaffoldDark,
    primarySwatch: Colors.blue,
    appBarTheme: const AppBarTheme(
      backgroundColor: _cardDark,
      foregroundColor: Colors.white,
      elevation: 0,
    ),
    cardColor: _cardDark,
    textTheme: GoogleFonts.poppinsTextTheme(ThemeData.dark().textTheme),
    useMaterial3: true,
  );
}
