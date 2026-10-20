/**
 * DTO de claves del sistema (tabla Tablas, n_codtabla = 603).
 * Contracto compartido backend <-> Flutter.
 *
 * Consumido por:
 *  - GET  /api/admin/claves       (web, solo Administrador) -> SystemKeyRow[]
 *  - PUT  /api/admin/claves/:id   (web, solo Administrador)
 *  - GET  /api/mobile/keys        (móvil, solo Administrador) -> MobileKeysResponse
 *  - PUT  /api/mobile/keys/:id    (móvil, solo Administrador)
 */

export interface SystemKeyRow {
  /** Número de la clave (ej: 1302 = CLAVECOMISION). */
  n_numero: number;
  /** Descripción de la clave (ej: 'CLAVECOMISION'). */
  c_describe: string;
  /** Valor actual de la clave (puede venir como string, int o decimal). */
  conversion: string | number;
}

/** Respuesta del endpoint móvil de claves. */
export interface MobileKeysResponse {
  keys: SystemKeyRow[];
  message: string;
}

/** Respuesta de actualización de clave (móvil). */
export interface MobileKeyUpdateResponse {
  message: string;
  clave: number;
  nuevoValor: number;
}
