import 'package:sedim_app/models/product_model.dart';

/// Respuesta de precios con metadatos de zona horaria (endpoints móviles).
///
/// Contrato backend: backend/schemas/price-response.ts
///  - GET /api/mobile/prices/:empresa  -> siempre respuesta enriquecida
///  - GET /api/precios/:empresa        -> array plano (legacy) u objeto si se
///                                        envía el header X-Timezone-Offset
class PriceModel {
  /// Empresa consultada (ej: '02', '04', '06').
  final String empresaCode;

  /// Productos con precios CON IGVV (si Afecto=1).
  final List<Product> productos;

  /// Offset del servidor en minutos (convención JS getTimezoneOffset).
  final int serverOffset;

  /// Offset del cliente en minutos (convención JS).
  final int clientOffset;

  /// Diferencia cliente - servidor en minutos.
  final int diff;

  /// Hora del servidor (ISO 8601 UTC).
  final DateTime? serverTime;

  /// Hora equivalente del cliente (ISO 8601 UTC).
  final DateTime? clientTime;

  const PriceModel({
    required this.empresaCode,
    required this.productos,
    this.serverOffset = 0,
    this.clientOffset = 0,
    this.diff = 0,
    this.serverTime,
    this.clientTime,
  });

  /// Acepta ambas formas de respuesta del backend:
  ///  - objeto enriquecido: { productos: [...], serverOffset, clientOffset, diff, ... }
  ///  - array plano legacy: [ {...}, {...} ]
  factory PriceModel.fromResponse(dynamic data, {required String empresaCode}) {
    if (data is List) {
      // Respuesta legacy (sin timezone): array de productos
      return PriceModel(
        empresaCode: empresaCode,
        productos: data.map((e) => Product.fromJson(e as Map<String, dynamic>)).toList(),
      );
    }
    if (data is Map<String, dynamic>) {
      final productos = (data['productos'] as List? ?? [])
          .map((e) => Product.fromJson(e as Map<String, dynamic>))
          .toList();
      return PriceModel(
        empresaCode: empresaCode,
        productos: productos,
        serverOffset: _toInt(data['serverOffset'] ?? data['serverTimezone']),
        clientOffset: _toInt(data['clientOffset'] ?? data['clientTimezone']),
        diff: _toInt(data['diff']),
        serverTime: _toDate(data['serverTime']),
        clientTime: _toDate(data['clientTime']),
      );
    }
    return PriceModel(empresaCode: empresaCode, productos: const []);
  }

  static int _toInt(dynamic value) {
    if (value is int) return value;
    if (value is num) return value.toInt();
    return int.tryParse('$value') ?? 0;
  }

  static DateTime? _toDate(dynamic value) {
    if (value is! String || value.isEmpty) return null;
    return DateTime.tryParse(value);
  }

  /// Etiqueta legible del cliente, ej: "UTC-05:00".
  String get etiquetaCliente {
    final signo = clientOffset <= 0 ? '+' : '-';
    final abs = clientOffset.abs();
    final h = (abs ~/ 60).toString().padLeft(2, '0');
    final m = (abs % 60).toString().padLeft(2, '0');
    return 'UTC$signo$h:$m';
  }
}
