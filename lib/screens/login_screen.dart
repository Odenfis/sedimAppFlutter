import 'package:flutter/material.dart';
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

  //métodos
  void _login() async {
    setState(() => _isLoading = true);
    final success = await ApiService().login(_userCtrl.text, _passCtrl.text);
    setState(() => _isLoading = false);
    //consultamos
    if (success && mounted){
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => const HomeScreen()));
    } else if (mounted){
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Credenciales incorrectas o error de conexión'))
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xFF0f1012),
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
                  borderRadius: BorderRadius.circular(20)
                ),
                child: Image.asset('assets/logo.png', height: 80),
              ),
              SizedBox(height: 40),
              Text('Bienvenido', style: TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold)),
              SizedBox(height: 30),
              _buildInput(_userCtrl,"Usuario",Icons.person),
              SizedBox(height: 15),
              _buildInput(_passCtrl, "Contraseña", Icons.lock, isPass: true),
              SizedBox(height: 30),
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.blueAccent),
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
  return TextField(
    controller: ctrl,
    obscureText: isPass,
    style: TextStyle(color: Colors.white),
    decoration: InputDecoration(
      labelText: label,
      prefixIcon: Icon(icon, color: Colors.grey),
      filled: true,
      fillColor: Color(0xFF1e1e1e),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
      labelStyle: TextStyle(color: Colors.grey)
    ),
  );
}


}