import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:provider/provider.dart';
import 'package:sedim_app/providers/theme_provider.dart';
import 'package:sedim_app/screens/screens.dart';

class SideMenu extends StatelessWidget {
   
  const SideMenu({super.key});
  
  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final isDark = themeProvider.isDark;

    return Drawer(
      //color de fondo adaptable al modo oscuro o claro
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          //cabecera
          UserAccountsDrawerHeader(
            decoration: BoxDecoration(
              //colores de gradientes - relacion sedimcorp
              gradient: LinearGradient(
                colors: isDark
                ? [Colors.black87, Colors.black54]
                : [Color(0xFF2c5484), Color(0xFF4a7bb5)],
              begin: AlignmentGeometry.topLeft,
              end: AlignmentGeometry.bottomRight
                )
            ),
            accountName: Text('Administrador', style: TextStyle(fontWeight: FontWeight.bold),), 
            accountEmail: Text('admin@sedimcorp.com'),
            currentAccountPicture: CircleAvatar(
              backgroundColor: Colors.white,
              child: Padding(
                padding: EdgeInsets.all(5),
                child: Image.asset('assets/logo.png'),
                ),
            ),
          ),
          //seccion configuracion
          ListTile(
            title: Text('Modo Oscuro', style: TextStyle(color: Theme.of(context).textTheme.bodyLarge?.color)),
            leading: Icon(
              isDark ? Icons.dark_mode : Icons.light_mode,
              color: isDark ? Colors.amber : Colors.grey,
            ),
            trailing: Switch(
              value: isDark,
              activeThumbColor: Colors.blueAccent, 
              onChanged: (value) {
                //cambiamos
                themeProvider.toogleTheme();
              }
              ),
          ),
          Divider(),
          //TODO: Agregar soon
          ListTile(
            leading: Icon(Icons.settings),
            title: Text('Configuraciones'),
            onTap: (){
              Navigator.pop(context); //close menu
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Proximamente...')
                  )
                );
            },
          ),
          ListTile(
            leading: Icon(FontAwesomeIcons.circleInfo),
            title: Text('Acerca de'),
            onTap: () {
              //TODO: completar someday
            },
          ),
          Divider(),
          //Cerrar Sesion
          ListTile(
            leading: Icon(Icons.exit_to_app, color: Colors.redAccent),
            title: Text('Cerrar Sesión', style: TextStyle(color: Colors.redAccent)),
            onTap: () {
              Navigator.pushReplacement(
                context, 
                MaterialPageRoute(
                  builder: (_) => LoginScreen()
                  )
                );
            },
          )
        ],
      ),
    );
  }
}