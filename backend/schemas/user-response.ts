/**
 * DTO del usuario autenticado.
 * Contracto compartido backend <-> Flutter.
 *
 * Consumido por:
 *  - POST /api/login  -> { message, user: UserResponse, accessToken, refreshToken, tokenType, expiresIn }
 *  - POST /api/token/refresh -> { accessToken, tokenType, expiresIn, user: UserResponse }
 *  - GET /api/session -> { user: UserResponse }
 */

/** Empresa accesible por el usuario (tabla Empresas_Acceso). */
export interface EmpresaAcceso {
  id: number;
  /** Número de la tabla 200 (cajero/empresa). */
  tabla200_numero: number;
  /** Prefijo de producto (ej: '02', '04', '06'). */
  codigo_producto: string;
  nombre_ventas: string | null;
  nombre_visible: string | null;
}

/** Módulos con permiso para el rol del usuario (tabla Modulos.clave). */
export type PermisoModulo =
  | 'herramientas'
  | 'operaciones'
  | 'reportes'
  | 'auditoria'
  | 'recetas'
  | 'config_actualizaciones';

export interface UserResponse {
  id: number;
  usuario: string;
  nombre: string;
  rol: string; // 'Administrador' | 'Operador' | 'Supervisor'
  permisos: PermisoModulo[];
  empresas: EmpresaAcceso[];
}

/** Respuesta completa del login (incluye par JWT para la app móvil). */
export interface LoginResponse {
  message: string;
  user: UserResponse;
  accessToken: string;
  refreshToken: string;
  tokenType: 'Bearer';
  /** Vigencia del accessToken en segundos (86400 = 24h). */
  expiresIn: number;
}

/** Respuesta del refresh de token. */
export interface TokenRefreshResponse {
  accessToken: string;
  tokenType: 'Bearer';
  expiresIn: number;
  user: UserResponse;
}
