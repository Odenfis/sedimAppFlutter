import 'package:sedim_app/models/company_model.dart';
import 'package:sedim_app/models/permission_model.dart';

class UserModel {
  final int id;
  final String usuario;
  final String nombre;
  final String rol;
  final List<String> permisos;
  final List<CompanyModel> empresas;

  UserModel({
    required this.id,
    required this.usuario,
    required this.nombre,
    required this.rol,
    this.permisos = const [],
    this.empresas = const [],
  });

  //Usaremos factory para crear el usuario desde el JSON del servidor (azure)
  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['id'] ?? 0,
      usuario: json['usuario'] ?? '',
      nombre: json['nombre'] ?? 'Usuario del Sistema',
      //back devuelve rol
      rol: json['rol'] ?? 'Sin Rol',
      //permisos[] del login (claves de módulos: herramientas, operaciones, ...)
      permisos: (json['permisos'] as List? ?? []).map((e) => e.toString()).toList(),
      //empresas[] del login (Empresas_Acceso: 02 Cocinería, 04 Mar Picante, 06 Abruzzo)
      empresas: (json['empresas'] as List? ?? [])
          .whereType<Map<String, dynamic>>()
          .map(CompanyModel.fromJson)
          .toList(),
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'usuario': usuario,
        'nombre': nombre,
        'rol': rol,
        'permisos': permisos,
        'empresas': empresas.map((e) => e.toJson()).toList(),
      };

  /// Value object de permisos para filtrar la UI por módulo.
  PermissionModel get permissionModel => PermissionModel(permisos);

  /// ¿Tiene el permiso del módulo [permiso]?
  bool hasPermission(String permiso) => permisos.contains(permiso);

  /// ¿Es Administrador? (el backend normaliza el rol a 'administrador')
  bool get esAdministrador => rol.trim().toLowerCase().contains('admin');

  /// Códigos de empresa autorizados (ej: ['02', '04']).
  List<String> get codigosEmpresas => empresas.map((e) => e.codigoProducto).toList();
}
