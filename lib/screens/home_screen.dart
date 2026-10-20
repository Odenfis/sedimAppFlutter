import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:provider/provider.dart';
import 'package:sedim_app/models/permission_model.dart';
import 'package:sedim_app/providers/user_provider.dart';
import 'package:sedim_app/screens/screens.dart';
import 'package:sedim_app/widgets/widgets.dart';


class HomeScreen extends StatelessWidget {
   
  const HomeScreen({super.key});
  
  @override
  Widget build(BuildContext context) {
    //Filtro UI por permisos: módulos visibles según permisos[] del login
    final userProvider = Provider.of<UserProvider>(context);
    final puedeVerPrecios = userProvider.hasPermission(PermissionModel.herramientas);
    final puedeVerClaves = userProvider.isAdmin; //claves: solo Administrador (backend 403)

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
            if (puedeVerPrecios)
            _buildMenuCard(
              context,
              "Cambio de \n Precios",
              FontAwesomeIcons.tags,
              Colors.blueAccent,
              const PriceScreen(),
              cardColor,
              textColor
            ),
            if (puedeVerClaves)
            _buildMenuCard(
              context, 
              'Gestión de \nClaves', 
              Icons.vpn_key, 
              Colors.orangeAccent, 
              const KeysScreen(), 
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
Widget _buildMenuCard(BuildContext context, String title, dynamic icon, Color iconColor, Widget? page, Color bgColor, Color? txtColor){
  final isEnabled = page != null;
  final isDark = Theme.of(context).brightness == Brightness.dark;
  return GestureDetector(
    onTap: !isEnabled
        ? () => ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Módulo próximamente...')),
            )
        : () => Navigator.push(context, MaterialPageRoute(builder: (_) => page)),
    child: Opacity(
      opacity: isEnabled ? 1.0 : 0.7,
      child: Container(
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(15),
        boxShadow: [
          //agregado de sombra para profundidad (espero)
          if (!isDark)
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 10,
            offset: Offset(0, 5)
          )
        ],
        border: Border.all(color: Colors.white10)
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          if (icon is FaIconData)
            FaIcon(icon, size: 40, color: iconColor)
          else if (icon is IconData)
            Icon(icon, size: 40, color: iconColor),
          SizedBox(height: 15),
          Text(
            title,
            textAlign: TextAlign.center,
            style: TextStyle(color: txtColor, fontSize: 16, fontWeight: FontWeight.bold),
          )
        ],
      ),
      ),
      ),
  );
}


}