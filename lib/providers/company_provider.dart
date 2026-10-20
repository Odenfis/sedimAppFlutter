import 'package:flutter/foundation.dart';

import 'package:sedim_app/models/company_model.dart';

/// Estado global de empresas del usuario (multi-empresa).
///
/// Según backend/backend.md:
///  - el dropdown solo muestra las empresas autorizadas en el login
///    (tabla Empresas_Acceso: 02 Cocinería, 04 Mar Picante, 06 Abruzzo)
///  - el cambio de empresa queda centralizado aquí para toda la app
class CompanyProvider extends ChangeNotifier {
  /// Catálogo de nombres comerciales (fallback si el backend no envía nombre_visible).
  static const Map<String, String> catalogoNombres = {
    '02': 'Cocinería',
    '04': 'Mar Picante',
    '06': 'Abruzzo',
  };

  List<CompanyModel> _empresas = const [];
  String? _codigoSeleccionado;

  /// Empresas autorizadas para el usuario actual.
  List<CompanyModel> get empresas => List.unmodifiable(_empresas);

  /// Código de la empresa seleccionada (ej: '04').
  String? get codigoSeleccionado => _codigoSeleccionado;

  /// Códigos autorizados (ej: ['02', '04', '06']).
  List<String> get codigosAutorizados => _empresas.map((e) => e.codigoProducto).toList();

  /// ¿El usuario no tiene empresas asignadas?
  bool get sinEmpresas => _empresas.isEmpty;

  /// Carga las empresas del usuario tras login/restauración.
  /// Autoselecciona la primera autorizada.
  void setEmpresas(List<CompanyModel> nuevasEmpresas) {
    _empresas = List.unmodifiable(nuevasEmpresas);
    _codigoSeleccionado = _empresas.isNotEmpty ? _empresas.first.codigoProducto : null;
    notifyListeners();
  }

  /// Limpia el estado (logout).
  void limpiar() {
    _empresas = const [];
    _codigoSeleccionado = null;
    notifyListeners();
  }

  /// ¿El usuario tiene acceso a la empresa [codigo]?
  bool estaAutorizada(String codigo) => codigosAutorizados.contains(codigo);

  /// Intenta seleccionar una empresa.
  /// Devuelve false (sin cambiar nada) si el usuario no tiene acceso:
  /// el backend respondería 403 (exigirEmpresa).
  bool seleccionar(String codigo) {
    if (!estaAutorizada(codigo)) return false;
    if (_codigoSeleccionado != codigo) {
      _codigoSeleccionado = codigo;
      notifyListeners();
    }
    return true;
  }

  /// Nombre visible para la UI: Empresas_Acceso > catálogo > código crudo.
  String nombreVisible(String codigo) {
    for (final empresa in _empresas) {
      if (empresa.codigoProducto == codigo) {
        final visible = empresa.displayName;
        if (visible.isNotEmpty) return visible;
        return empresa.nombreComercial;
      }
    }
    return catalogoNombres[codigo] ?? codigo;
  }
}
