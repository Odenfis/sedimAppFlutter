/// Modelo de empresa accesible por el usuario.
/// Refleja las filas de la tabla [Empresas_Acceso] que devuelve el login.
///
/// Empresas permitidas por el backend: 02 (Cocinería), 04 (Mar Picante), 06 (Abruzzo).
class CompanyModel {
  final int id;
  final int tabla200Numero;
  final String codigoProducto;
  final String? nombreVentas;
  final String? nombreVisible;

  const CompanyModel({
    required this.id,
    required this.tabla200Numero,
    required this.codigoProducto,
    this.nombreVentas,
    this.nombreVisible,
  });

  factory CompanyModel.fromJson(Map<String, dynamic> json) {
    return CompanyModel(
      id: (json['id'] ?? 0) is int ? json['id'] ?? 0 : int.tryParse('${json['id']}') ?? 0,
      tabla200Numero: json['tabla200_numero'] is int
          ? json['tabla200_numero']
          : int.tryParse('${json['tabla200_numero']}') ?? 0,
      codigoProducto: (json['codigo_producto'] ?? '').toString(),
      nombreVentas: json['nombre_ventas']?.toString(),
      nombreVisible: json['nombre_visible']?.toString(),
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'tabla200_numero': tabla200Numero,
        'codigo_producto': codigoProducto,
        'nombre_ventas': nombreVentas,
        'nombre_visible': nombreVisible,
      };

  factory CompanyModel.fromJsonMap(Map<String, dynamic> json) => CompanyModel.fromJson(json);

  /// Nombre a mostrar en la UI: nombre_visible > nombre_ventas > código.
  String get displayName =>
      (nombreVisible?.isNotEmpty == true ? nombreVisible : null) ??
      (nombreVentas?.isNotEmpty == true ? nombreVentas : null) ??
      codigoProducto;

  /// Nombre comercial conocido del catálogo Sedimcorp (fallback de la UI).
  String get nombreComercial {
    switch (codigoProducto) {
      case '02':
        return 'Cocinería';
      case '04':
        return 'Mar Picante';
      case '06':
        return 'Abruzzo';
      default:
        return displayName;
    }
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) || (other is CompanyModel && other.codigoProducto == codigoProducto);

  @override
  int get hashCode => codigoProducto.hashCode;
}
