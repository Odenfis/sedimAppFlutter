import 'package:flutter/material.dart';
import 'package:sedim_app/models/user_model.dart';

class UserProvider extends ChangeNotifier{
  UserModel? _currentUser;
  UserModel? get user => _currentUser;

  //guardamos usuario
  void setUser(UserModel user){
    _currentUser = user;
    notifyListeners();
  }

  //Borrar usuario al cerrar sesión
  void clearUser(){
    _currentUser = null;
    notifyListeners();
  }
  
}