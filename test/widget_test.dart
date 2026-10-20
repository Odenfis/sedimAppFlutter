// Pruebas unitarias de los modelos y providers nuevos
// (migración JWT + multi-empresa según backend/backend.md).

import 'package:flutter_test/flutter_test.dart';
import 'package:sedim_app/models/company_model.dart';
import 'package:sedim_app/models/permission_model.dart';
import 'package:sedim_app/models/user_model.dart';
import 'package:sedim_app/providers/company_provider.dart';

void main() {
  group('PermissionModel', () {
    test('reconoce permisos asignados por módulo', () {
      final permisos = PermissionModel(['herramientas', 'operaciones']);
      expect(permisos.tiene(PermissionModel.herramientas), isTrue);
      expect(permisos.tiene(PermissionModel.operaciones), isTrue);
      expect(permisos.tiene(PermissionModel.auditoria), isFalse);
      expect(permisos.tieneAlguno([PermissionModel.auditoria, PermissionModel.recetas]), isFalse);
    });

    test('el modelo vacío no concede ningún permiso', () {
      const permisos = PermissionModel.vacio();
      for (final modulo in PermissionModel.todos) {
        expect(permisos.tiene(modulo), isFalse);
      }
    });
  });

  group('UserModel (login con permisos y empresas)', () {
    test('parsea permisos[] y empresas[] del login', () {
      final user = UserModel.fromJson({
        'id': 7,
        'usuario': 'wmoncada',
        'nombre': 'Walter Moncada',
        'rol': 'Administrador',
        'permisos': ['herramientas', 'auditoria'],
        'empresas': [
          {'id': 1, 'tabla200_numero': 2, 'codigo_producto': '02', 'nombre_visible': 'Cocinería'},
          {'id': 2, 'tabla200_numero': 4, 'codigo_producto': '04', 'nombre_visible': 'Mar Picante'},
        ],
      });

      expect(user.esAdministrador, isTrue);
      expect(user.hasPermission('herramientas'), isTrue);
      expect(user.hasPermission('reportes'), isFalse);
      expect(user.codigosEmpresas, ['02', '04']);
      expect(user.empresas.first.displayName, 'Cocinería');
    });

    test('tolera un backend sin permisos ni empresas (compatibilidad)', () {
      final user = UserModel.fromJson({'id': 1, 'usuario': 'x', 'nombre': 'X', 'rol': 'Operador'});
      expect(user.permisos, isEmpty);
      expect(user.empresas, isEmpty);
      expect(user.esAdministrador, isFalse);
    });

    test('round-trip toJson/fromJson para persistencia de sesión', () {
      final original = UserModel.fromJson({
        'id': 3,
        'usuario': 'op',
        'nombre': 'Operador Uno',
        'rol': 'Operador',
        'permisos': ['herramientas'],
        'empresas': [
          {'id': 3, 'tabla200_numero': 6, 'codigo_producto': '06', 'nombre_visible': 'Abruzzo'},
        ],
      });
      final restaurado = UserModel.fromJson(original.toJson());
      expect(restaurado.usuario, original.usuario);
      expect(restaurado.permisos, original.permisos);
      expect(restaurado.codigosEmpresas, original.codigosEmpresas);
    });
  });

  group('CompanyProvider (multi-empresa)', () {
    final empresas = [
      const CompanyModel(id: 1, tabla200Numero: 2, codigoProducto: '02', nombreVisible: 'Cocinería'),
      const CompanyModel(id: 2, tabla200Numero: 4, codigoProducto: '04', nombreVisible: 'Mar Picante'),
    ];

    test('carga empresas y autoselecciona la primera', () {
      final provider = CompanyProvider();
      provider.setEmpresas(empresas);
      expect(provider.codigoSeleccionado, '02');
      expect(provider.codigosAutorizados, ['02', '04']);
      expect(provider.sinEmpresas, isFalse);
    });

    test('solo permite seleccionar empresas autorizadas', () {
      final provider = CompanyProvider();
      provider.setEmpresas(empresas);

      expect(provider.seleccionar('04'), isTrue);
      expect(provider.codigoSeleccionado, '04');

      // Empresa sin acceso: el backend respondería 403 (exigirEmpresa)
      expect(provider.seleccionar('06'), isFalse);
      expect(provider.codigoSeleccionado, '04');
    });

    test('resuelve nombres visibles con fallback al catálogo', () {
      final provider = CompanyProvider();
      provider.setEmpresas([empresas.first]);
      expect(provider.nombreVisible('02'), 'Cocinería');
      // No autorizada pero conocida por el catálogo
      expect(provider.nombreVisible('06'), 'Abruzzo');
      // Desconocida: código crudo
      expect(provider.nombreVisible('99'), '99');
    });

    test('limpiar() resetea el estado (logout)', () {
      final provider = CompanyProvider();
      provider.setEmpresas(empresas);
      provider.limpiar();
      expect(provider.empresas, isEmpty);
      expect(provider.codigoSeleccionado, isNull);
      expect(provider.sinEmpresas, isTrue);
    });
  });
}
