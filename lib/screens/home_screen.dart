import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:sedim_app/screens/screens.dart';
import 'package:sedim_app/widgets/widgets.dart';


class HomeScreen extends StatelessWidget {
   
  const HomeScreen({super.key});
  
  @override
  Widget build(BuildContext context) {

    //obtener colores del tema para el homescreen
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardColor = Theme.of(context).cardColor;
    final textColor = Theme.of(context).textTheme.bodyLarge?.color;

    return Scaffold(
      drawer: SideMenu(),
      appBar: AppBar(
        title: Text('Menú Principal'),
        //backgroundColor: Color(0xFF0f1012),        
        /*
        actions: [
          IconButton(
            icon: Icon(Icons.exit_to_app),
            onPressed: () => Navigator.pushReplacement(
              context, 
              MaterialPageRoute(builder: (_) => LoginScreen())
              ),            
            )
        ]*/
      ),
      //backgroundColor: Color(0xFF0f1012),
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
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
              PriceScreen(),
              cardColor,
              textColor
            ),
            _buildMenuCard(
              context,
              "Proximamente",
              FontAwesomeIcons.box,
              isDark ? Colors.grey.shade800 : Colors.grey.shade300,
              null,
              cardColor,
              textColor
            )
          ],
          ),
        ),
    );
  }

//Widget
Widget _buildMenuCard(BuildContext context, String title, IconData icon, Color iconColor, Widget? page, Color bgColor, Color? txtColor){
  return GestureDetector(
    onTap: page == null ? null : () => Navigator.push(context, MaterialPageRoute(builder: (_) => page)),
    child: Container(
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(15),
        boxShadow: [
          //agregado de sombra para profundidad (espero)
          if (Theme.of(context).brightness == Brightness.light)
          BoxShadow(
            color: Colors.black,
            blurRadius: 10,
            offset: Offset(0, 5)
          )
        ],
        border: Border.all(color: Colors.white10)
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          FaIcon(icon, size: 40, color: iconColor),
          SizedBox(height: 15),
          Text(
            title,
            textAlign: TextAlign.center,
            style: TextStyle(color: txtColor, fontSize: 16, fontWeight: FontWeight.bold),
          )
        ],
      ),
    ),
  );
}


}