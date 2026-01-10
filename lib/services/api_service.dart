import 'package:cookie_jar/cookie_jar.dart';
import 'package:dio/dio.dart';
import 'package:dio_cookie_manager/dio_cookie_manager.dart';


class ApiService {
  static const String baseUrl = 'https://sedimapp.onrender.com';
  //static const String baseUrl = 'http://45.236.45.96:3000';
  late Dio _dio;
  late CookieJar _cookieJar;
  //Singleton lo usaré para usar la misma instancia en est app
  static final ApiService _instance = ApiService._internal();
  factory ApiService() => _instance;

  ApiService._internal(){
    _dio = Dio(BaseOptions(
      baseUrl: baseUrl,
      connectTimeout: const Duration(seconds: 5),
      receiveTimeout: const Duration(seconds: 5),
      headers: {'Content-Type': 'application/json'}
    ));
    _cookieJar = CookieJar();
    _dio.interceptors.add(CookieManager(_cookieJar));
  }
  
  //Manejo del login
  Future<Map<String, dynamic>?> login(String user, String pass) async {
    try{
      final response = await _dio.post('/api/login', data: {
        'usuario' : user,
        'password' : pass
      });
      //server tiene estructura solo devolveremos usuario
      return response.data['user'];
    } catch (e){
      return null;
    }
  }
  /*
  Future<Map<String, dynamic>?> login(String user, String pass) async {
    try {
      print("🔵 Intentando conectar a: $baseUrl/api/login"); // LOG 1
      
      final response = await _dio.post('/api/login', data: {
        'usuario': user, 
        'password': pass
      });
      
      print("🟢 Respuesta del servidor: ${response.data}"); // LOG 2
      return response.data['user']; 

    } catch (e) {
      print("🔴 ERROR GRAVE: $e"); // <--- ESTO ES LO QUE NECESITAMOS VER
      if (e is DioException) {
         print("Tipo de error Dio: ${e.type}");
         print("Mensaje: ${e.message}");
         print("Respuesta del server: ${e.response}");
      }
      return null;
    }
  }*/

  //Obtener productos de empresa
  Future<List<dynamic>> getProducts(String empresaCode) async {
    try{
      final response = await _dio.get('/api/precios/$empresaCode');
      return response.data;
    } catch(e){
      throw Exception('Error cargando productos...');
    }
  }
  //update de los productos
  Future<bool> updatePrices(String codPro, Map<String, dynamic> prices) async {
    try{
      await _dio.put('/api/precios/$codPro', data: prices);
      return true;
    } catch(e){
      return false;
    }
  }
  //gestion de claves
  //como obtengo la lista
  Future<List<dynamic>> getSystemKeys() async {
    try{
      final response = await _dio.get('/api/admin/claves');
      return response.data;
    } catch(e){
      throw Exception('Error cargando claves');
    }
  }
  //update de claves web
  Future<bool> updateSystemKey(int nNumero, double valor) async {
    try{
      await _dio.put('/api/admin/claves/$nNumero', data: {'valor': valor});
      return true;
    } catch(e){
      return false;
    }
  }

}