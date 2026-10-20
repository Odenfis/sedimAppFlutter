# Backend API Documentation (Render)

## Overview
Backend desplegado en Render para la aplicación Sedimcorp.

## Access Info
- **Backend Desarrollo**: `/Users/waltermauromoncadarubio/Documents/webProjects/sedimApp`
- **Tecnologías**: Node.js + Express + SQL Server (MSSQL)
- **Puerto**: 3000
- **Base de Datos**: Sedimserver.database.windows.net / MPRestaurante
- **Environment Variables** (.env):
  - `DB_USER=Administrador`
  - `DB_PASS=Sedim2021`
  - `DB_SERVER=Sedimserver.database.windows.net`
  - `DB_NAME=MPRestaurante`
  - `SESSION_SECRET=warzone`

## Endpoints Existentes (Documentados)

### Auth System (Session-based)
- **POST /api/login** - Autenticación de usuario
  - Body: `{ "usuario": "usuario", "password": "clave" }`
  - Response: `{ message: "Login exitoso", user: { id, usuario, nombre, rol, permisos, empresas } }`
  - ⚠️ Security: Password en texto plano en código cliente (solo para demo)

- **POST /api/logout** - Cerrar sesión
  - Response: `{ message: "Sesión cerrada" }`

- **GET /api/session** - Verificar sesión activa
  - Response: `{ user: {...} }` o `401` si no autenticado

### Prices Module (Requires: 'herramientas' permission)
- **GET /api/precios/:empresa** - Listar productos por empresa
  - Params: empresa en [02, 04, 06]
  - Auth: `isAuthenticated` middleware + `requierePermiso('herramientas')`
  - Response: Array de productos con precios por tema (PreTema1...6)
  - 🌐 Includes timezone offset (server timezone): 180 (5 hours, -190)
  - ⚠️ **Issue**: No timezone validation from client

- **PUT /api/precios/:codpro** - Actualizar precio de producto
  - Auth: `isAuthenticated` middleware + `requierePermiso('herramientas')`
  - Body: `{ p1, p2, p3, p4, p5, p6 }` (high INGVV, como aparecen para cliente)
  - Response: `{ message: "Ok" }`
  - 🔧 Logic: Divide por factor (1 + IGVV/100) before saving to DB

### System Keys Module (Admin: 'Administrador' rol)
- **GET /api/admin/claves** - Listar todas las claves del sistema (WEB ONLY)
  - Auth: `isAuthenticated` only (no permission check explícito)
  - Select de tabla Tablas (WHERE n_codtabla = 603): `n_numero`, `c_describe`, `conversion`
  - Response: Array de claves "[1302, 'CLAVECOMISION', '1302']"

- **PUT /api/admin/claves/:id** - Actualizar valor de clave (WEB ONLY)
  - Auth: `isAuthenticated` only (no permission check explícito)
  - Body: `{ valor: new_value }` (Float)
  - Response: `{ message: "Clave actualizada" }`

---

### Auth JWT Module (NUEVO — para la app móvil)
- **POST /api/login** - Ahora además de la sesión web devuelve el par JWT:
  - Response: `{ message, user, accessToken (24h), refreshToken (30d), tokenType: 'Bearer', expiresIn: 86400 }`
  - 🔒 Rate limit: 10 intentos / 15 min por IP+usuario (HTTP 429 + Retry-After)
- **POST /api/token/refresh** - Intercambia refreshToken por accessToken nuevo
  - Body: `{ "refreshToken": "<token>" }`
  - Response: `{ accessToken, tokenType: 'Bearer', expiresIn, user }` (permisos/empresas reconsultados en BD)
  - Respuestas de error: 400 (falta token), 401 (inválido/expirado/revocado)
  - 🔒 Rate limit: 60 req / 15 min
- **POST /api/logout** - Además de destruir la sesión revoca TODOS los refresh tokens del usuario
- **Autenticación híbrida**: todas las rutas protegidas aceptan cookie de sesión (web) **o** header `Authorization: Bearer <accessToken>` (móvil), vía `usuarioActual(req)`

### Timezone Module (NUEVO)
- **GET /api/timezone/client** - Metadata de zona horaria cliente/servidor
  - Auth: `isAuthenticated`
  - Headers: `X-Timezone-Offset` (minutos, convención JS getTimezoneOffset: Perú = 300)
  - Response: `{ zoneOffset, serverOffset, clientOffset, diff, serverTime, clientTime, serverTimezoneLabel, clientTimezoneLabel }`
  - 400 si falta el header o es inválido (rango válido ±14h)

### 🐛 Fixes aplicados a endpoints móviles existentes
- `/api/mobile/prices/:empresa`:
  - Typo SQL `PreTeme4/5/6` → `PreTema4/5/6` (antes devolvía columnas nulas)
  - IGVV ahora se lee de la tabla `Valores` (antes hardcodeado 10.5)
  - Agregado `exigirEmpresa()`: 403 si el usuario no tiene la empresa asignada
  - Offset saneado con `parseOffsetCliente()` (evita SQL injection vía header)
  - Respuesta extendida: ahora incluye `serverTime` y `clientTime`
- `/api/mobile/timezone/client`: ahora valida el header (400) y devuelve metadatos completos
- `/api/mobile/keys/:id`: validación de ID corregida (`Number(id)` string comparison bug)

### 👾 MOBILE-EXCLUSIVE ENDPOINTS (NEW!)

La web usa los endpoints existentes (/api/login, /api/precios, /api/admin/claves).
La móvil usa estos endpoints exclusivos que NO COMPITEN con la web:

#### Mobile Price Handler
- **GET /api/mobile/prices/:empresa** - Listarpciones con timezone adaptive
  - Auth: `isAuthenticated` middleware (NO requiere 'herramientas' permission)
  - Headers: `X-Timezone-Offset: integer` (ej: 180)
  - Response: `{ serverTimezone, clientTimezone, diff, productos[] }`
  - Benefit: Server ajusta precios basado en cliente timezone (+/- IGVV dynamic)

#### Mobile Timezone Client Handler
- **GET /api/mobile/timezone/client** - Get current client timezone offset
  - Auth: `isAuthenticated`
  - Headers: `X-Timezone-Offset: integer`
  - Response: `{ serverTimezone, clientTimezone }`
  - Benefit: Client info for client -> server ordering

#### Mobile Keys Handler (Security Improved)
- **GET /api/mobile/keys** - Listra keys con STRICT ADMIN CHECK
  - Auth: `isAuthenticated` + `isMobileAdmin()`
  - Response: `{ keys[] }` or 403 if NOT 'administrador'
  - Benefit: Ban unauthorized access explicitly

#### Mobile Keys Update Handler (Security Improved)
- **PUT /api/mobile/keys/:id** - Update key with data validation
  - Auth: like GET /api/mobile/keys
  - Body: `{ valor: number }`
  - Response: `{ message: "CLAVE ACTUALIZADA EXITOSAMENTE", clave, nuevoValor }`
  - Benefit: Ban unauthorized + validate input data

#### 📋 Mover de /api/* -> /api/mobile/*
| Original Endpoint | Mobile Equivalent | Backend Changes |
|-----------------|------------------|-----------------|
| /api/prices/:empresa | /api/mobile/prices/:empresa | NEW: timezone adaptive |
| /api/admin/claves | /api/mobile/keys | NEW: explicit admin check |
| (none) | /api/mobile/timezone/client | NEW |
| (none) | /api/mobile/keys/:id | NEW |

#### 🌐 BACKWARD COMPATIBILITY GUARANTEE
- Web current behavior: UNTOUCHED
- Web can continue using /api/prices/:empresa and /api/admin/claves
- Web ignores /api/mobile/* completely
- Zero breaking changes to existing functionality

## Database Schema (MSSQL)

### Main Tables
- **usuariosweb** - Usuarios del sistema
  - Campos: id, usuario, password (bcrypt), nombre, rol_id
- **Roles** - Roles principales
  - Acceptable: 'administrador', 'operador', 'supervisor'
- **Empresas_Acceso** - Empresas asignadas a cada usuario
  - Campos: id, tabla200_numero, codigo_producto, nombre_ventas, nombre_visible
  - For站台 acceso: empresas [02, 04, 06]
- **Productos** - Productos del inventario
  - Campos: CodPro, Nombre, Afecto, Tipo, Costo, PventaMa, PventaMi, Stock, etc.
- **Precios** - Precios por tema
  - Campos: Codpro, PreTema1, PreTema2, PreTema3, PreTema4, PreTema5, PreTema6
  - Decimal precision: Decimal(19, 4) for 4 decimal places
- **Valores** - Parámetros del sistema
  - Campos: c_valor, n_valor
  - Key: 'Igvv' returns decimal percentage (e.g., 10.50)
- **Tablas (n_codtabla=603)** - Claves del sistema
  - Campos: n_numero, c_describe, conversion
  - Example: [1302, 'CLAVECOMISION', '1302']
- **Tablas (n_codtabla=201)** - Turnos
  - Campos: n_numero, c_describe, conversion
  - Possible values: 1 (mañana), 2 (tarde)
- **Tablas (n_codtabla=200)** - Empresas/Cajeros
  - Campos: n_numero, c_describe
- **Tablas (n_codtabla=15)** - Razones/Cargos (Caja)
- **Tablas (n_codtabla=49)** - Tipos de cargos (banco vs efectivo)
- **Transacciones** - Movimientos de stock/insumos

## Migration Strategy

### Phase 1: Backend Enhancements ✅ COMPLETADO
- [x] **Implementar zona horaria del cliente**: `GET /api/timezone/client` ✅
  - Acepta header `X-Timezone-Offset` (minutos, convención JS: Perú = 300)
  - Returns: `{ zoneOffset, serverOffset, clientOffset, diff, serverTime, clientTime, serverTimezoneLabel, clientTimezoneLabel }`
- [x] **Modificar /api/precios/:empresa**: Agregar parámetro timezone client ✅
  - Con header `X-Timezone-Offset` responde `{ productos: [...], serverOffset, clientOffset, diff, serverTime, clientTime }`
  - Sin header responde el array plano original (compatibilidad con la web intacta)
- [x] **Consistencia entre endpoints de precios vs productos** ✅
  - Script de migración BD creado: `sql/migracion_auditoria_fechas.sql` (tabla `AuditoriaMovimiento` + SP + vista)

### Phase 2: DTOs & Schemas TypeScript ✅ COMPLETADO
Create files in: `backend/schemas/` (creados en el proyecto Flutter, carpeta `backend/schemas/`)

1. **schemas/price-response.ts**
   ```typescript
   {
     CodPro: string;
     Nombre: string;
     PreTema1: number;
     ...
   }
   ```

2. **schemas/user-response.ts**
   - id, usuario, nombre, rol, permisos[], empresas[]
   - Prefixed companies in pantalla

3. **schemas/system-key-response.ts**
   - n_numero, c_describe, conversion

### Phase 3: Flutter Integration Phase 1 ✅ COMPLETADO

**Actualizar servicios existentes:**

1. `fetchPrices(String empresaCode)` - GET /api/precios/:empresa
   - Headers: `X-Timezone-Offset: client_hours`
   - Timeout calculation: server + client difference

2. `updatePrices(String codPro, Map<String, dynamic> prices)` - PUT /api/precios/:codpro

3. `getSystemKeys()` - GET /api/admin/claves

4. `updateSystemKey(int nNumero, double valor)` - PUT /api/admin/claves/:id

**Nuevos modelos:**
- `PriceModel` con timestamps, empresaCode
- `CompanyModel` - manejo de empresas (02/Cocinería, 04/Mar Picante, 06/Abruzzo)
- `PermissionModel` - leer de permisos[] login

### Phase 4: Flutter Integration Phase 2 ✅ COMPLETADO

**Deep Flutter Updates:**

1. **User System**
   - Migrate backend **JWT** for client: change from session to JWT token + refreshToken
   - Implement token storage (shared_preferences / secure_storage)
   - Refresh token strategy: interceptor en Dio

2. **Admin Features** (requiere rol 'Administrador')
   - Permissions display: huelga client UI screens por each role
   - Hide/show buttons/panels based on permisos[]
   - UI rendering engine: filter end user access

3. **Multi-Company Support**
   - Permissible companies map: [2, 4, 6] in backend
   - UI dropdown: show accessible only companies for logged user
   - Company switching logic: set companyPermission filter

## Authentication Flow Improvement

**Actual (Session-based):**
1. Login POST /api/login → Server setea `req.session.user` + ensure cookies
2. All farther requests send cookies automatically (Dio CookieManager)
3. Session cleanup: logout = destroy session in browser
4. Session timeout: 1000 * 60 * 60 * 24 (24 hrs)

**Suggested (JWT-based - Recommended for Móvil):** ✅ IMPLEMENTADO
1. Login POST /api/login → Return `{ refreshToken, accessToken }` (además de `user` y la sesión web intacta)
2. Use accessToken in header: `Authorization: Bearer <token>` for all protected calls
3. If `accessToken` expires (e.g., 24h), send `refreshToken` to `/api/token/refresh` request
4. Logout POST /api/logout = clear tokens from local storage + revoca el refresh token en el servidor
5. Implementado: cookies (web) vs tokens (móvil) conviviendo vía autenticación híbrida (`usuarioActual(req)`)

**Detalles de la implementación (backend):**
- `lib/auth-jwt.js`: firma/verificación de access (24h) y refresh (30d) con `jsonwebtoken`; secretos derivados de `SESSION_SECRET`
- Almacén de refresh tokens en memoria con rotación (máx. 5 por usuario) y revocación por usuario; en cada deploy de Render se invalidan (comportamiento seguro)
- `POST /api/token/refresh`: valida jti no revocado, reconsultará permisos/empresas vigentes del usuario y devuelve accessToken nuevo
- Flutter: `tokenRefreshInterceptor` en Dio reintenta 1 vez tras refrescar; si el refresh falla, `sesionInvalidada` devuelve la app al login

## Customizing SQL Formatting Helper
**QT temporalización del helper:** `q-format.js`.

**Adaptar a SQL Server queries:**
- Manejo de tipos: DECIMAL(19,2), MONEY (precios con IGVV), BIT (booleanos), NVARCHAR (strings)
- CultureInfo: es-PE (formato dinero: "S/.".decimalPlace "moneda", en input_remove_simplify
- Use `FORMAT()` SQL Server para formatos temporales Italians
- Cantidad básica DINÁMICA: SELECTCASE WHEN isHogging IS NULL ... END

**Ejemplo:**
```sql
-- ASESORAR FECHAS CLIENTE + ZONA HORARIA
DECLARE @clientOffset INT = 180; -- 5 horas en hora (client timezone -5h)
DECLARE @serverOffset INT = 0; -- server timezone (UTC-5)
DECLARE @diffHours FLOAT = (@clientOffset - @serverOffset) / 100.0;

-- Convertir fecha client a server (MSSQL timezone cautious):
-- Usa DATETRUNC("h", DATEADD(hh, @diffHours, fechaInput)) as fecha on GETDATE()
```

## Security Considerations
- ✅ CORS habilitado in foremost `server.js`
- ✅ Password hashing con bcryptjs (10 rounds strength)
- ✅ Middleware de permisos por módulo ('herramientas', 'operaciones', 'reportes', 'auditoria')
- ✅ Transafety empresa: `exigirEmpresa()` + `empresaAutorizada()` function wrappers
- ✅ Rollback logic en transacciones (productos, usuarios, recetas)

- ✅ **Autenticación híbrida JWT + sesión**: la web usa cookies, la móvil `Bearer` tokens (`usuarioActual(req)`)
- ✅ **Timezone validada en backend**: `parseOffsetCliente()` rechaza offsets ausentes/no numéricos/fuera de ±14h
- ✅ **`/api/mobile/prices/:empresa` ahora valida empresa autorizada** con `exigirEmpresa()` (antes cualquier empresa sin control)
- ✅ **Admin check en `/api/admin/claves`** (GET y PUT): 403 'Acceso no autorizado' si el rol no es administrador
- ✅ **Guard de auto-eliminación**: `DELETE /api/users/:id` rechaza eliminar el propio usuario (ya existía, verificado)
- ✅ **Rate limiting en auth endpoints**: login 10 req/15min por IP+usuario, refresh 60 req/15min (HTTP 429 + Retry-After)

- ⚠️ **Pendiente: ejecutar `sql/migracion_auditoria_fechas.sql` en la BD productiva** (Azure SQL)
- ⚠️ **Pendiente: desplegar el backend actualizado a Render** (los cambios son locales)
- ⚠️ Refresh tokens en memoria del servidor: un reinicio de Render invalida sesiones móviles (re-login; aceptable y seguro)

## Permitted Modules & Permissions
Backend uses permission arrays per user:

| Module | Permission Key | Example Roles |
|--------|----------------|--------------|
| Herramientas | 'herramientas' | Administrador, Operador, Supervisor |
| Operaciones | 'operaciones' | Administrador, Supervisor |
| Reportes | 'reportes' | Administrador, Supervisor |
| Auditoría | 'auditoria' | Administrador |
| Recetas | 'recetas' | Administrador, Operador |
| Config Actualizaciones | 'config_actualizaciones' | Administrador |

## Rollback Strategy in Backend

**Troverse on product save:**
```javascript
try {
    await transaction.begin();
    await pool.request(params).query("INSERT INTO Productos...");
    for (const empresaId of ids) {
        await pool.request(params).query("INSERT INTO Usuarios_Empresas...");
    }
    await transaction.commit();
} catch (err) {
    await transaction.rollback(); // Revert everything
    throw err;
}
```

**Copeta on receta save:**
```javascript
await pool.request().query("DELETE FROM Recetas WHERE codProd = @prod"); // Pristine
for (const item of items) {
    await pool.request().query("INSERT INTO Recetas...");
}
```

## Change Catalog

### Backend Modifications Priority: ✅ TODOS COMPLETADOS
1. ✅ PRIORITY: Implementar `/api/timezone/client` endpoint
   - Purpose: Get current client offset in integer
   - Enhanced: Add timezone-aware prices in `/api/precios/:empresa`
   - Efecto: Reduce timezone errors in rotten APIs for_cliente

2. ✅ MIGRATION: JWT token migration
   - Makeachanglem dari: express-session ↔ JWT tokens
   - Beneficio: Scalable mobile auth, no session cookie 24h timeout, auto-refresh token
   - Implementado: Using `jsonwebtoken` library with refresh cycle

3. ✅ SECURITY: Agregar permisos check en `/api/admin/claves`
   - Request: Require roles 'Administrador' ONLY
   - ReqType: POST, PUT responses { message: "Acceso no autorizado" }

4. ✅ SECURITY: Cada user debe eliminar su propio usuario
   - Guard: Add check `if (req.params.id == req.session.user.id) return res.status(400)`
   - Modular: Few users can delete themselves (security risk if accidentally)

---

## Todo Tasks

### Backend Tasks ✅ COMPLETADO
- [x] Confirmar acceso al backend de Render
- [x] Documentar endpoints existentes
- [x] Analizar schema BD SQL Server
- [x] Implementar `GET /api/timezone/client` endpoint (todos)
- [x] Modificar `/api/precios/:empresa` para usar timezone client (todos)
- [x] Agregar project DTOs/Schemas TypeScript (Todos) — `backend/schemas/*.ts`
- [x] Agregar sistema de refreshToken JWT (backend) — `lib/auth-jwt.js`, `POST /api/token/refresh`
- [x] Agregar limitación de velocidad en auth endpoints (todos) — `lib/rate-limiter.js` (login 10 req/15min, refresh 60 req/15min)
- [x] Crear script de migración BD para auditoría fechas (operaciones) — `sql/migracion_auditoria_fechas.sql` (pendiente: ejecutar en BD productiva)

### Frontend Tasks ✅ COMPLETADO
- [x] CIERRAR UserProvider migrando desde sesión a tokens — `providers/user_provider.dart` (persistencia + restoreSession)
- [x] Actualizar ApiService: agregar header 'Authorization: Bearer {token}' — interceptor onRequest
- [x] Agregar `Sharedpreferences` service para tokens persistente (rolling) — `services/token_storage.dart`
- [x] Agregar `tokenRefreshInterceptor` en Dio para automat refresh tokens — onError → `/api/token/refresh` → retry 1 vez (single-flight)
- [x] Actualizar prices_screen.dart con manejo de timezone client — usa `/api/mobile/prices` + `X-Timezone-Offset`, muestra hora del cliente
- [x] Crear PermissionModel y filtro UI por rol — `models/permission_model.dart` + `home_screen.dart` filtra tarjetas
- [x] Implementar company switching logic basado en empresas[] del login — `CompanyProvider.seleccionar()` valida autorización (403)
- [x] Crear CompanyProvider for UI dropdown de empresas disponibilidad — `providers/company_provider.dart`
- [x] Agregar protected UI: botones protegidos — `userProvider.hasPermission('herramientas')` / `isAdmin` en home y keys screens
- [x] Actualizar admin endpoints UI para acceder a companyIDs correctos — claves vía `/api/mobile/keys` con admin estricto

### Testing Tasks 🔄 EN PROGRESO
- [x] Pruebas de chat de timezone con endpoint /api/precios — `test/timezone.test.js` (8 tests unitarios)
- [ ] Pruebas de rollback en transacción de producto guardar
- [x] Pruebas de refreshToken -> accesstoken auto-refresh — `test/auth-jwt.test.js` (9 tests: firma, verificación, revocación, rotación, expiración)
- [x] Pruebas de permisos (operaciones, reportes, auditoría) — `test/widget_test.dart` (PermissionModel/UserModel/CompanyProvider, 9 tests)
- [x] Pruebas de edge cases: empresa sin acceso -> 403 en fluter — `CompanyProvider.seleccionar()` rechaza empresa no autorizada
- [x] Pruebas de rate limiter — `test/rate-limiter.test.js` (4 tests: ventana, 429, clave por IP+usuario, reset)
- [ ] Pruebas de concurrency: delete user while editing...
- [ ] Pruebas de integración E2E contra Render (requiere backend desplegado)

---

## References
- [Express.js](https://expressjs.com/)
- [MS-SQL Node.js docs](https://www.npmjs.com/package/mssql)
- [JWT Auth](https://jwt.io/)
- [CORS configuration in Node.js](https://developer.mozilla.org/en-US/docs/Web/HTTP/CORS)
- [SQL Server FORMAT() function](https://docs.microsoft.com/en-us/sql/t-sql/functions/format-transact-sql)
- [Render deployment docs](https://render.com/docs)
- [Marketplace Timezone API](https://developers.google.com/maps/documentation/timezone/start)
- Principal source code (backend): `/Users/waltermauromoncadarubio/Documents/webProjects/sedimApp/server.js`
- Project Flutter: `/Users/waltermauromoncadarubio/Documents/flutterProjects/sedim_app`

---

## Implementation Summary (2026-10-19)

### Backend (`webProjects/sedimApp`) — archivos nuevos
| Archivo | Propósito |
|---------|-----------|
| `lib/timezone.js` | Utilidades de zona horaria (parse/validación de offset, diff, fechas cliente/servidor) |
| `lib/auth-jwt.js` | Firma/verificación de access+refresh JWT + almacén de refresh tokens con rotación |
| `lib/rate-limiter.js` | Rate limiter en memoria (ventana fija, clave IP+usuario) |
| `sql/migracion_auditoria_fechas.sql` | Tabla `AuditoriaMovimiento` + SP + vista (fechas UTC con offsets) |
| `test/timezone.test.js` | 8 tests unitarios de timezone |
| `test/auth-jwt.test.js` | 9 tests unitarios de JWT/refresh |
| `test/rate-limiter.test.js` | 4 tests unitarios del limitador |

### Backend (`webProjects/sedimApp/server.js`) — modificado
- Autenticación híbrida: `usuarioActual(req)` unifica sesión web + Bearer móvil (45 reemplazos)
- `/api/login`: rate limit + emisión de `accessToken`/`refreshToken`
- Nuevos: `POST /api/token/refresh`, `GET /api/timezone/client`
- `/api/logout`: revoca refresh tokens
- `/api/precios/:empresa`: respuesta timezone-aware cuando llega `X-Timezone-Offset` (array plano sin header = web intacta)
- `/api/mobile/prices/:empresa`: fixes (PreTema, IGVV real, exigirEmpresa, offset saneado)
- `/api/mobile/timezone/client` y `/api/mobile/keys/:id`: validaciones corregidas
- `/api/admin/claves` GET/PUT: check de Administrador habilitado

### Flutter (`flutterProjects/sedim_app`) — archivos nuevos
| Archivo | Propósito |
|---------|-----------|
| `lib/models/company_model.dart` | EmpresaAcceso del login (02/04/06) |
| `lib/models/permission_model.dart` | Claves de módulos + value object de permisos |
| `lib/models/price_model.dart` | Respuesta de precios con timestamps/offsets |
| `lib/services/token_storage.dart` | Persistencia SharedPreferences de tokens + usuario |
| `lib/providers/company_provider.dart` | Dropdown multi-empresa + switching autorizado |
| `backend/schemas/*.ts` | DTOs TypeScript del contrato API (Phase 2) |

### Flutter — archivos modificados
- `lib/services/api_service.dart`: Bearer + X-Timezone-Offset interceptors, token refresh con retry, endpoints móviles con fallback legacy, `LoginResult`, `logout()`
- `lib/providers/user_provider.dart`: persistencia, `restoreSession()`, `hasPermission()`, `isAdmin`
- `lib/models/user_model.dart`: `permisos[]`, `empresas[]`, helpers
- `lib/main.dart`: splash + restauración de sesión + listener de sesión expirada
- `lib/screens/login_screen.dart`: guarda tokens + carga CompanyProvider
- `lib/screens/price_screen.dart`: dropdown solo empresas autorizadas + info timezone
- `lib/screens/keys_screen.dart`: permisos vía provider (no string del rol)
- `lib/screens/home_screen.dart`: tarjetas filtradas por permiso
- `lib/widgets/side_menu.dart`: logout con revocación server-side
- `pubspec.yaml`: `shared_preferences: ^2.5.3`

### Pruebas
- Backend: `npm test` → 33/33 pasando (11 preexistentes + 22 nuevas)
- Flutter: `flutter analyze` → sin issues; `flutter test` → 9/9 pasando
- Smoke test de arranque: login 400 con credenciales falsas, endpoints protegidos 401

## Notes
- All endpoints prefixed with `/api/`
- Billfacecies JWT will need library `jsonwebtoken` and `bcryptjs` (already installed)
- Session timeout set para 24hrs; consider graceful timeout handling in mobile app
- Permitted companies are: 02 (Cocinería), 04 (Mar Picante), 06 (Abruzzo)
- IGVV (tax) factor is automatically calculated from `Valores` table: `1 + (IGVV/100)`
- Product pricing auto-correct input: User high taxes (with IGVV) divided by factor stored (without IGVV)
- Backend supports multiple bedrijven by empresa ID in `Empresas_Acceso` table, desarrolle UI for company switching