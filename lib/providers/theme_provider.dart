import 'package:flutter/material.dart';

class ThemeProvider extends ChangeNotifier {
  //inicio en tema oscuro por defecto
  bool _isDark = true;
  bool get isDark => _isDark;
  //Func. para cambiar de tema
  void toogleTheme(){
    _isDark = !_isDark;
    notifyListeners(); //listener para avisar cambios en toda la app
  }
}