import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:provider/provider.dart';
import 'package:sedim_app/providers/company_provider.dart';
import 'package:sedim_app/providers/theme_provider.dart';
import 'package:sedim_app/providers/user_provider.dart';
import 'package:sedim_app/screens/screens.dart';
import 'package:sedim_app/services/api_service.dart';

class SideMenu extends StatelessWidget {
   
  const SideMenu({super.key});
  
  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final user = Provider.of<UserProvider>(context).user;
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
            accountName: Text(
              user?.nombre ?? 'Usuario',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ), 
            accountEmail: Text(
              '${user?.rol ?? 'Sin Rol'} | @${user?.usuario ?? ''}',
              style: TextStyle(color: Colors.white70),
            ),
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
                themeProvider.toggleTheme();
              }
              ),
          ),
          Divider(),
          ListTile(
            leading: Icon(Icons.settings),
            title: Text('Configuraciones'),
            subtitle: Text(
              'Tema y preferencias de la app',
              style: TextStyle(fontSize: 12, color: Colors.grey),
            ),
            onTap: () {
              Navigator.pop(context); //close menu
              _showSettingsSheet(context, isDark, themeProvider);
            },
          ),
          ListTile(
            leading: FaIcon(FontAwesomeIcons.circleInfo),
            title: Text('Acerca de'),
            onTap: () {
              Navigator.pop(context);
              _showAboutDialog(context);
            },
          ),
          Divider(),
          //Cerrar Sesion
          ListTile(
            leading: Icon(Icons.exit_to_app, color: Colors.redAccent),
            title: Text('Cerrar Sesión', style: TextStyle(color: Colors.redAccent)),
            onTap: () async {
              //1. Revocamos tokens en el servidor y limpiamos el local (JWT)
              await ApiService().logout();
              if (!context.mounted) return;
              //2. Limpiamos el estado global
              Provider.of<UserProvider>(context, listen: false).clearUser();
              Provider.of<CompanyProvider>(context, listen: false).limpiar();
              //3. Volvemos al login
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (_) => LoginScreen()),
              );
            },
          )
        ],
      ),
    );
  }

  void _showSettingsSheet(
    BuildContext context,
    bool isDark,
    ThemeProvider themeProvider,
  ) {
    showModalBottomSheet(
      context: context,
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 8),
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey.shade400,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            SwitchListTile(
              title: const Text('Modo Oscuro'),
              secondary: Icon(isDark ? Icons.dark_mode : Icons.light_mode),
              value: isDark,
              onChanged: (_) {
                themeProvider.toggleTheme();
                Navigator.pop(ctx);
              },
            ),
            const Padding(
              padding: EdgeInsets.fromLTRB(16, 0, 16, 16),
              child: Text(
                'Más opciones de configuración próximamente.',
                style: TextStyle(color: Colors.grey, fontSize: 12),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showAboutDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Sedimcorp App'),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Versión 1.0.0+1'),
            SizedBox(height: 8),
            Text(
              'Gestión de precios y claves del sistema. '
              'Inicia sesión para administrar productos por empresa.',
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cerrar'),
          ),
        ],
      ),
    );
  }
}