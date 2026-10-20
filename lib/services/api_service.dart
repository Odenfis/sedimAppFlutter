import 'package:cookie_jar/cookie_jar.dart';
import 'package:dio/dio.dart';
import 'package:dio_cookie_manager/dio_cookie_manager.dart';
import 'package:flutter/foundation.dart';

import 'package:sedim_app/models/price_model.dart';
import 'package:sedim_app/services/token_storage.dart';

/// Resultado del login: usuario + par de tokens JWT.
/// Los tokens pueden ser null si el backend desplegado aún no emite JWT
/// (compatibilidad hacia atrás: la app seguiría funcionando con cookies).
class LoginResult {
  final Map<String, dynamic>? user;
  final String? accessToken;
  final String? refreshToken;

  const LoginResult({this.user, this.accessToken, this.refreshToken});

  bool get exitoso => user != null;
  bool get conTokens => accessToken != null && refreshToken != null;
}

class ApiService {
  static const String baseUrl = 'https://sedimapp.onrender.com';
  //static const String baseUrl = 'http://45.236.45.96:3000';

  /// Notificador global: se incrementa cuando la sesión expiró y el
  /// refresh token tampoco es válido (la app debe volver al login).
  static final ValueNotifier<int> sesionInvalidada = ValueNotifier<int>(0);

  late Dio _dio;
  final TokenStorage _storage = TokenStorage();
  String? _accessToken;
  String? _refreshToken;
  bool _tokensCargados = false;

  // Refresh en curso: evita que varias peticiones 401 disparen varios refresh
  Future<bool>? _refreshEnCurso;

  //Singleton lo usaré para usar la misma instancia en est app
  static final ApiService _instance = ApiService._internal();
  factory ApiService() => _instance;

  ApiService._internal() {
    _dio = Dio(BaseOptions(
      baseUrl: baseUrl,
      // Render (free tier) puede tardar en arrancar en frío: timeouts holgados
      connectTimeout: const Duration(seconds: 20),
      receiveTimeout: const Duration(seconds: 30),
      headers: {'Content-Type': 'application/json'},
    ));
    _cookieJar = CookieJar();
    _dio.interceptors.add(CookieManager(_cookieJar));
    _dio.interceptors.add(InterceptorsWrapper(
      onRequest: _agregarHeaders,
      onError: _manejarError,
    ));
    _cargarTokens();
  }

  late CookieJar _cookieJar;

  Future<void> _cargarTokens() async {
    if (_tokensCargados) return;
    _accessToken = await _storage.getAccessToken();
    _refreshToken = await _storage.getRefreshToken();
    _tokensCargados = true;
  }

  // ============================================================
  //  INTERCEPTORES (JWT + TIMEZONE)
  // ============================================================

  /// Offset en minutos con convención JavaScript getTimezoneOffset()
  /// (positivo al OESTE de UTC: Perú UTC-5 => 300).
  /// Dart usa la convención contraria (este positivo), por eso se niega.
  static int get _offsetTimezoneCliente => -(DateTime.now().timeZoneOffset.inMinutes);

  void _agregarHeaders(RequestOptions options, RequestInterceptorHandler handler) async {
    // 0. Carga perezosa: evita carrera entre el singleton y el primer request
    if (!_tokensCargados) await _cargarTokens();
    // 1. Authorization: Bearer {token} (si hay sesión JWT)
    if (_accessToken != null) {
      options.headers['Authorization'] = 'Bearer $_accessToken';
    }
    // 2. X-Timezone-Offset: zona horaria del cliente (backend la usa
    //    para precios y auditoría timezone-aware)
    options.headers['X-Timezone-Offset'] = '$_offsetTimezoneCliente';
    handler.next(options);
  }

  Future<void> _manejarError(DioException e, ErrorInterceptorHandler handler) async {
    final codigo = e.response?.statusCode;
    final ruta = e.requestOptions.path.toString();
    final esRutaAuth = ruta.contains('/api/login') ||
        ruta.contains('/api/token/refresh') ||
        ruta.contains('/api/logout');
    final yaReintentado = e.requestOptions.headers['__reintentado'] == true;

    // Solo interceptamos 401 de rutas protegidas con token disponible
    if (codigo != 401 || esRutaAuth || yaReintentado || _refreshToken == null) {
      return handler.next(e);
    }

    // TokenRefreshInterceptor: renueva el accessToken y reintenta 1 vez
    final renovado = await _refrescarToken();
    if (!renovado) return handler.next(e);

    try {
      final opciones = e.requestOptions;
      opciones.headers['__reintentado'] = true;
      opciones.headers['Authorization'] = 'Bearer $_accessToken';
      final respuesta = await _dio.fetch(opciones);
      return handler.resolve(respuesta);
    } on DioException catch (error) {
      return handler.next(error);
    }
  }

  /// Renueva el accessToken usando el refreshToken (single-flight).
  Future<bool> _refrescarToken() {
    _refreshEnCurso ??= _ejecutarRefresh().whenComplete(() => _refreshEnCurso = null);
    return _refreshEnCurso!;
  }

  Future<bool> _ejecutarRefresh() async {
    try {
      final response = await _dio.post('/api/token/refresh', data: {'refreshToken': _refreshToken});
      final nuevo = response.data['accessToken'] as String?;
      if (nuevo == null || nuevo.isEmpty) return false;
      _accessToken = nuevo;
      await _storage.saveAccessToken(nuevo);
      debugPrint('🔄 AccessToken renovado');
      return true;
    } on DioException catch (e) {
      debugPrint('🔴 Refresh token inválido (${e.response?.statusCode}): sesión expirada');
      await limpiarTokensLocales();
      sesionInvalidada.value++; // notifica a la app para volver al login
      return false;
    }
  }

  Future<void> limpiarTokensLocales() async {
    _accessToken = null;
    _refreshToken = null;
    await _storage.clear();
  }

  /// Sincroniza los tokens que entrega el login del backend.
  Future<void> guardarTokens(String accessToken, String refreshToken) async {
    _accessToken = accessToken;
    _refreshToken = refreshToken;
    _tokensCargados = true;
    await _storage.saveTokens(accessToken: accessToken, refreshToken: refreshToken);
  }

  // ============================================================
  //  AUTENTICACIÓN
  // ============================================================

  //Manejo del login (ahora devuelve usuario + tokens JWT)
  Future<LoginResult> login(String user, String pass) async {
    try {
      final response = await _dio.post('/api/login', data: {
        'usuario': user,
        'password': pass,
      });
      final data = response.data;
      return LoginResult(
        user: data is Map<String, dynamic> && data['user'] is Map<String, dynamic>
            ? data['user'] as Map<String, dynamic>
            : null,
        accessToken: data?['accessToken'],
        refreshToken: data?['refreshToken'],
      );
    } catch (e) {
      return const LoginResult();
    }
  }

  /// Cierra sesión: revoca tokens en el servidor y limpia el local.
  Future<void> logout() async {
    try {
      await _dio.post('/api/logout');
    } catch (_) {
      // aunque falle la red, limpiamos local
    }
    await limpiarTokensLocales();
  }

  /// Valida la sesión actual contra el servidor (cookies o Bearer).
  Future<Map<String, dynamic>?> verificarSesion() async {
    try {
      final response = await _dio.get('/api/session');
      return response.data is Map<String, dynamic> ? response.data['user'] : null;
    } catch (_) {
      return null;
    }
  }

  // ============================================================
  //  PRECIOS (timezone-aware)
  // ============================================================

  /// Obtiene los precios de una empresa usando el endpoint móvil
  /// (respuesta con timezone). Fallback automático al endpoint legacy.
  Future<PriceModel> getPrices(String empresaCode) async {
    try {
      final response = await _dio.get('/api/mobile/prices/$empresaCode');
      return PriceModel.fromResponse(response.data, empresaCode: empresaCode);
    } on DioException catch (e) {
      // Backend desplegado sin los endpoints móviles aún: usar legacy
      if (e.response?.statusCode == 404 || e.response?.statusCode == 405) {
        final legacy = await _dio.get('/api/precios/$empresaCode');
        return PriceModel.fromResponse(legacy.data, empresaCode: empresaCode);
      }
      rethrow;
    } catch (e) {
      rethrow;
    }
  }

  //update de los productos
  Future<bool> updatePrices(String codPro, Map<String, dynamic> prices) async {
    try {
      await _dio.put('/api/precios/$codPro', data: prices);
      return true;
    } catch (e) {
      return false;
    }
  }

  // ============================================================
  //  CLAVES DEL SISTEMA (solo Administrador)
  // ============================================================

  //gestion de claves via endpoints móviles (admin estricto)
  Future<List<dynamic>> getSystemKeys() async {
    try {
      final response = await _dio.get('/api/mobile/keys');
      return response.data['keys'] as List? ?? [];
    } on DioException catch (e) {
      if (e.response?.statusCode == 404 || e.response?.statusCode == 405) {
        // fallback legacy (requiere rol Administrador en el backend)
        final legacy = await _dio.get('/api/admin/claves');
        return legacy.data as List? ?? [];
      }
      rethrow;
    }
  }

  //update de claves via endpoints móviles (admin estricto + validación)
  Future<bool> updateSystemKey(int nNumero, double valor) async {
    try {
      await _dio.put('/api/mobile/keys/$nNumero', data: {'valor': valor});
      return true;
    } on DioException catch (e) {
      if (e.response?.statusCode == 404 || e.response?.statusCode == 405) {
        try {
          await _dio.put('/api/admin/claves/$nNumero', data: {'valor': valor});
          return true;
        } catch (_) {
          return false;
        }
      }
      return false;
    } catch (e) {
      return false;
    }
  }

  // ============================================================
  //  ZONA HORARIA
  // ============================================================

  /// GET /api/timezone/client: valida el offset del cliente contra el servidor.
  Future<Map<String, dynamic>?> getTimezoneCliente() async {
    try {
      final response = await _dio.get('/api/timezone/client');
      return response.data is Map<String, dynamic> ? response.data : null;
    } catch (_) {
      return null;
    }
  }
}
