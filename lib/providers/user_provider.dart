import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import 'package:sedim_app/models/permission_model.dart';
import 'package:sedim_app/models/user_model.dart';
import 'package:sedim_app/services/api_service.dart';
import 'package:sedim_app/services/token_storage.dart';

/// Estado global del usuario autenticado.
///
/// Migrado de sesión (cookies) a tokens JWT según backend/backend.md:
///  - los tokens se persisten con [TokenStorage] (rolling session)
///  - [restoreSession] permite arrancar la app ya autenticado
///  - [hasPermission] alimenta el filtro de UI por rol/módulo
class UserProvider extends ChangeNotifier {
  final TokenStorage _storage = TokenStorage();

  UserModel? _currentUser;
  bool _restaurando = false;
  bool _sesionRestaurada = false;

  UserModel? get user => _currentUser;

  /// ¿Ya se intentó restaurar la sesión persistida? (evita parpadeos de splash)
  bool get sesionRestaurada => _sesionRestaurada;

  /// ¿Hay sesión activa (usuario en memoria)?
  bool get isAuthenticated => _currentUser != null;

  /// Guarda el usuario tras el login junto con sus tokens.
  /// Los tokens son opcionales para compatibilidad con un backend
  /// que aún no emita JWT (se seguiría usando la sesión por cookies).
  Future<void> setUser(
    UserModel user, {
    String? accessToken,
    String? refreshToken,
  }) async {
    _currentUser = user;
    if (accessToken != null && refreshToken != null) {
      await ApiService().guardarTokens(accessToken, refreshToken);
    }
    await _storage.saveUser(user.toJson());
    notifyListeners();
  }

  /// Restaura la sesión persistida al arrancar la app.
  /// Devuelve el usuario restaurado (o null si no había sesión).
  Future<UserModel?> restoreSession() async {
    if (_restaurando) return _currentUser;
    _restaurando = true;
    try {
      final hasTokens = await _storage.hasSession();
      if (!hasTokens) {
        _currentUser = null;
        return null;
      }
      final userJson = await _storage.getUser();
      _currentUser = userJson == null ? null : UserModel.fromJson(userJson);
      return _currentUser;
    } catch (e) {
      debugPrint('Error restaurando sesión: $e');
      _currentUser = null;
      return null;
    } finally {
      _restaurando = false;
      _sesionRestaurada = true;
      notifyListeners();
    }
  }

  /// Cierra sesión: borra usuario y tokens locales.
  /// La revocación del refresh token en el servidor la hace ApiService.logout().
  Future<void> clearUser() async {
    _currentUser = null;
    await ApiService().limpiarTokensLocales();
    await _storage.clear();
    notifyListeners();
  }

  // --------------------------------------------
  //  FILTRO DE UI POR PERMISOS
  // --------------------------------------------

  PermissionModel get permisos => _currentUser?.permissionModel ?? const PermissionModel.vacio();

  /// ¿El usuario actual tiene el permiso [permiso]?
  /// Uso: `context.read<UserProvider>().hasPermission(PermissionModel.herramientas)`
  bool hasPermission(String permiso) => _currentUser?.hasPermission(permiso) ?? false;

  /// ¿El usuario actual es Administrador?
  bool get isAdmin => _currentUser?.esAdministrador ?? false;
}
