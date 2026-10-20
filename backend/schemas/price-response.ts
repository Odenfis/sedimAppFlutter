/**
 * DTO de respuesta de precios por empresa.
 * Contracto compartido backend (Node/Express) <-> Flutter (Dio).
 *
 * Consumido por:
 *  - GET /api/precios/:empresa (legacy web: array plano de PriceRow)
 *  - GET /api/precios/:empresa con header X-Timezone-Offset (móvil: PriceResponse)
 *  - GET /api/mobile/prices/:empresa (móvil: siempre PriceResponse)
 */

/** Fila de producto con precios por tema (CON IGVV aplicado si Afecto=1). */
export interface PriceRow {
  /** Código del producto (ej: '0400010001'). */
  CodPro: string;
  Nombre: string;
  PreTema1: number;
  PreTema2: number;
  PreTema3: number;
  PreTema4: number;
  PreTema5: number;
  PreTema6: number;
}

/** Bloque de metadatos de zona horaria incluido en respuestas móviles. */
export interface TimezoneMeta {
  /** Offset del servidor en minutos (convención JS getTimezoneOffset: Perú = 300). */
  serverOffset: number;
  /** Offset del cliente en minutos (header X-Timezone-Offset). */
  clientOffset: number;
  /** Diferencia cliente - servidor en minutos. */
  diff: number;
  /** Hora del servidor en ISO UTC. */
  serverTime: string;
  /** Hora equivalente del cliente en ISO UTC. */
  clientTime: string;
}

/** Respuesta enriquecida cuando el cliente envía X-Timezone-Offset. */
export interface PriceResponse extends TimezoneMeta {
  productos: PriceRow[];
}
