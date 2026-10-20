/// Catálogo de permisos por módulo del sistema.
/// Refleja la clave de la tabla [Modulos] que llega en `user.permisos[]` del login.
///
/// | Módulo              | Clave                  | Roles típicos                  |
/// |---------------------|------------------------|--------------------------------|
/// | Herramientas        | herramientas           | Administrador, Operador, Sup.  |
/// | Operaciones         | operaciones            | Administrador, Supervisor      |
/// | Reportes            | reportes               | Administrador, Supervisor      |
/// | Auditoría           | auditoria              | Administrador                  |
/// | Recetas             | recetas                | Administrador, Operador        |
/// | Config Actualiz.    | config_actualizaciones | Administrador                  |
class PermissionModel {
  // Claves de módulo (contrato con el backend)
  static const String herramientas = 'herramientas';
  static const String operaciones = 'operaciones';
  static const String reportes = 'reportes';
  static const String auditoria = 'auditoria';
  static const String recetas = 'recetas';
  static const String configActualizaciones = 'config_actualizaciones';

  /// Todos los módulos conocidos (útil para depuración / pantallas de admin).
  static const List<String> todos = [
    herramientas,
    operaciones,
    reportes,
    auditoria,
    recetas,
    configActualizaciones,
  ];

  final Set<String> _permisos;

  PermissionModel(Iterable<String> permisos) : _permisos = Set.from(permisos);

  const PermissionModel.vacio() : _permisos = const <String>{};

  /// ¿El usuario tiene el permiso [permiso]?
  bool tiene(String permiso) => _permisos.contains(permiso);

  /// ¿Tiene alguno de los permisos indicados?
  bool tieneAlguno(Iterable<String> permisos) => permisos.any(_permisos.contains);

  /// Los permisos asignados (solo lectura).
  Set<String> get asignados => Set.unmodifiable(_permisos);

  @override
  String toString() => 'PermissionModel($_permisos)';
}
