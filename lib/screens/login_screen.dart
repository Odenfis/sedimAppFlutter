import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:sedim_app/models/user_model.dart';
import 'package:sedim_app/providers/company_provider.dart';
import 'package:sedim_app/providers/user_provider.dart';
import 'package:sedim_app/screens/screens.dart';
import 'package:sedim_app/services/api_service.dart';

class LoginScreen extends StatefulWidget {
   
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _userCtrl = TextEditingController();
  final _passCtrl = TextEditingController();
  bool _isLoading = false;
  //variable para sneekpeak de contraseña
  bool _isObscure = true;

  //métodos
  void _login() async {
    setState(() => _isLoading = true);
    //call api (ahora devuelve usuario + tokens JWT)
    final result = await ApiService().login(_userCtrl.text, _passCtrl.text);
    setState(() => _isLoading = false);
    if (result.exitoso && mounted){
      //json a modelo (incluye permisos[] y empresas[])
      final user = UserModel.fromJson(result.user!);
      //save provider global (persiste usuario + tokens si el backend los emitió)
      await Provider.of<UserProvider>(context, listen: false)
          .setUser(user, accessToken: result.accessToken, refreshToken: result.refreshToken);
      if (!mounted) return;
      //cargamos las empresas autorizadas para el dropdown multi-empresa
      Provider.of<CompanyProvider>(context, listen: false).setEmpresas(user.empresas);
      //navegamos
      Navigator.pushReplacement(
        context, MaterialPageRoute(builder: (_) => const HomeScreen()));
    } else if (mounted){
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Credenciales incorrectas o error de conexión'))
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    //agregamos temas por si acaso
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = Theme.of(context).textTheme.bodyLarge?.color;
    return Scaffold(
      //backgroundColor: Color(0xFF0f1012),
      //dejamos que el fondo lo maneje el main (espero...)
      body: Center(
         child: SingleChildScrollView(
          padding: EdgeInsets.all(30),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              //logo
              Container(
                padding: EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  //agregamos para manejar sombra en modo claro
                  boxShadow: [
                    if(!isDark)
                      BoxShadow(
                        color: Colors.black12,
                        blurRadius: 15,
                        offset: Offset(0, 5)
                      )
                  ]
                ),
                child: Image.asset('assets/logo.png', height: 80),
              ),
              SizedBox(height: 40),
              Text('Bienvenido', style: TextStyle(color: textColor, fontSize: 24, fontWeight: FontWeight.bold)),
              SizedBox(height: 30),
              _buildInput(_userCtrl,"Usuario",Icons.person),
              SizedBox(height: 15),
              _buildInput(_passCtrl, "Contraseña", Icons.lock, isPass: true),
              SizedBox(height: 30),
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blueAccent,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10)
                    )
                    ),
                  onPressed: _isLoading ? null : _login, 
                  child: _isLoading
                  ? CircularProgressIndicator(color: Colors.white)
                  : Text('INGRESAR', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold))
                  ),
              )
            ],
          ),
         )
      ),
    );
  }

Widget _buildInput(TextEditingController ctrl, String label, IconData icon, {bool isPass = false}){

  //agregamos cambios por tema aquí
  final isDark = Theme.of(context).brightness == Brightness.dark;
  final inputFill = isDark ? Color(0xFF1e1e1e) : Colors.white;
  final hintColor = isDark ? Colors.grey : Colors.grey.shade600;


  return TextField(
    controller: ctrl,
    //obscureText: isPass,
    obscureText: isPass ? _isObscure : false,
    style: TextStyle(
      //color: Colors.white
      color: Theme.of(context).textTheme.bodyLarge?.color
      ),
    decoration: InputDecoration(
      labelText: label,
      //labelStyle: TextStyle(color: Colors.grey),
      labelStyle: TextStyle(color: hintColor),            
      prefixIcon: Icon(icon, color: Colors.blueAccent),
      //agregamos ojito
      suffixIcon: isPass
      ? IconButton(
        icon: Icon(
          //oculto es isObscure true se muestra ojo
          //caso contrario no se muestra
          _isObscure ? Icons.visibility : Icons.visibility_off,
          color: Colors.grey,
        ),
        onPressed: (){
          setState(() {
            _isObscure = !_isObscure;
          });
        },        
        )
      : null,
      filled: true,
      //fillColor: Color(0xFF1e1e1e),
      fillColor: inputFill,
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: isDark ? BorderSide.none : BorderSide(
          color: Colors.grey.shade300
        )
      )
    ),
  );
}


}