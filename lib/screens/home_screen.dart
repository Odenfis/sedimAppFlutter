import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:sedim_app/screens/screens.dart';


class HomeScreen extends StatelessWidget {
   
  const HomeScreen({super.key});
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Menú Principal'),
        backgroundColor: Color(0xFF0f1012),
        actions: [
          IconButton(
            icon: Icon(Icons.exit_to_app),
            onPressed: () => Navigator.pushReplacement(
              context, 
              MaterialPageRoute(builder: (_) => LoginScreen())
              ),            
            )
        ],
      ),
      backgroundColor: Color(0xFF0f1012),
      body: Padding(
        padding: EdgeInsetsGeometry.all(20),
        child: GridView.count(
          crossAxisCount: 2,
          crossAxisSpacing: 15,
          mainAxisSpacing: 15,
          children: [
            _buildMenuCard(
              context,
              "Cambio de \n Precios",
              FontAwesomeIcons.tags,
              Colors.blueAccent,
              PriceScreen()
            ),
            _buildMenuCard(
              context,
              "Proximamente",
              FontAwesomeIcons.box,
              Colors.grey.shade800,
              null
            )
          ],
          ),
        ),
    );
  }

//Widget
Widget _buildMenuCard(BuildContext context, String title, IconData icon, Color color, Widget? page){
  return GestureDetector(
    onTap: page == null ? null : () => Navigator.push(context, MaterialPageRoute(builder: (_) => page)),
    child: Container(
      decoration: BoxDecoration(
        color: Color(0xFF1e1e1e),
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: Colors.white10)
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          FaIcon(icon, size: 40, color: color),
          SizedBox(height: 15),
          Text(
            title,
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
          )
        ],
      ),
    ),
  );
}


}