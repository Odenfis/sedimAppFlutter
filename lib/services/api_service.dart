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
  Future<bool> login(String user, String pass) async {
    try{
      await _dio.post('/api/login', data: {'usuario':user, 'password': pass});
      return true;
    } catch(e){
      return false;
    }
  }
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

}