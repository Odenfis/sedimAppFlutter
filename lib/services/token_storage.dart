import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

/// Persistencia local de la sesión móvil (tokens JWT + usuario).
///
/// Se usa `shared_preferences` según lo planificado en backend/backend.md.
/// Nota: para producción endurecida considerar `flutter_secure_storage`;
/// la interfaz de esta clase ya aísla la implementación para migrar luego.
class TokenStorage {
  static const String _kAccessToken = 'accessToken';
  static const String _kRefreshToken = 'refreshToken';
  static const String _kUserJson = 'userJson';

  Future<SharedPreferences> get _prefs => SharedPreferences.getInstance();

  /// Guarda la sesión completa (tokens + usuario serializado).
  Future<void> saveSession({
    required String accessToken,
    required String refreshToken,
    required Map<String, dynamic> user,
  }) async {
    final prefs = await _prefs;
    await prefs.setString(_kAccessToken, accessToken);
    await prefs.setString(_kRefreshToken, refreshToken);
    await prefs.setString(_kUserJson, jsonEncode(user));
  }

  /// Guarda solo el par de tokens (sin tocar el usuario persistido).
  Future<void> saveTokens({
    required String accessToken,
    required String refreshToken,
  }) async {
    final prefs = await _prefs;
    await prefs.setString(_kAccessToken, accessToken);
    await prefs.setString(_kRefreshToken, refreshToken);
  }

  /// Guarda solo el usuario serializado (sesiones sin tokens, compatibilidad).
  Future<void> saveUser(Map<String, dynamic> user) async {
    final prefs = await _prefs;
    await prefs.setString(_kUserJson, jsonEncode(user));
  }

  /// Guarda solo el access token (tras un refresh exitoso).
  Future<void> saveAccessToken(String accessToken) async {
    final prefs = await _prefs;
    await prefs.setString(_kAccessToken, accessToken);
  }

  Future<String?> getAccessToken() async => (await _prefs).getString(_kAccessToken);

  Future<String?> getRefreshToken() async => (await _prefs).getString(_kRefreshToken);

  /// Recupera el usuario persistido (o null si no hay sesión).
  Future<Map<String, dynamic>?> getUser() async {
    final raw = (await _prefs).getString(_kUserJson);
    if (raw == null) return null;
    try {
      return jsonDecode(raw) as Map<String, dynamic>;
    } catch (_) {
      return null;
    }
  }

  /// ¿Hay una sesión guardada con tokens?
  Future<bool> hasSession() async {
    final prefs = await _prefs;
    return prefs.getString(_kAccessToken) != null && prefs.getString(_kRefreshToken) != null;
  }

  /// Borra toda la sesión local (logout).
  Future<void> clear() async {
    final prefs = await _prefs;
    await prefs.remove(_kAccessToken);
    await prefs.remove(_kRefreshToken);
    await prefs.remove(_kUserJson);
  }
}
