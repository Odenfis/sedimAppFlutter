# PROGRESS.md — Roadmap sedim_app

> Última actualización: 2026-10-19
> Dispositivo prueba: HONOR ALT NX3 (ACNNBB4C06901747) — Android 15, API 35
> Entorno: macOS ARM64, Flutter 3.47.2, Dart 3.13.2, Android SDK 37.0.0

## 1. Estado actual

- [x] App base Flutter (models/, providers/, screens/, services/, widgets/)
- [x] Deps: dio, dio_cookie_manager, cookie_jar, google_fonts, font_awesome_flutter, provider, **shared_preferences** (nueva 2026-10-19)
- [x] Toolchain Android reparado
- [x] Build `app-debug.apk` exitoso
- [x] Instalación verificada en HONOR (`adb install` → Success)
- [x] `flutter doctor` sin issues
- [x] `flutter analyze --suggestions` → java/gradle/agp/kgp compatible
- [x] **Autenticación JWT móvil**: accessToken 24h + refreshToken 30d, persistencia con SharedPreferences y refresco automático en Dio (2026-10-19)
- [x] **Precios timezone-aware**: header `X-Timezone-Offset` + endpoint móvil `/api/mobile/prices` con metadatos de zona horaria (2026-10-19)
- [x] **Multi-empresa**: dropdown solo con empresas autorizadas del login (`CompanyProvider`), switching validado → 403 (2026-10-19)
- [x] **Filtro UI por permisos**: tarjetas del home y claves según `permisos[]` / `isAdmin` (2026-10-19)
- [x] **Sesión persistida**: arranque restaura usuario + empresas (splash → Home o Login) (2026-10-19)
- [x] **Compatibilidad web auditada**: cero impacto en el sistema web adjunto al backend (2026-10-19)

## 2. Fix despliegue HONOR (2026-10-09)

### Causa raíz
1. Android Studio 2026.1 trae JDK 25.0.2, incompatible con Gradle 8.12 (`BUILD FAILED in 328ms`).
2. Flutter 3.47.2 exige Gradle 9.3.1 + AGP 9.1.0 + KGP 2.4.0 + Java 17. El proyecto tenía Gradle 8.12 + AGP 8.9.1 + KGP 2.1.0 + Java 11 con DSL antiguo.

### Cambios aplicados
- Instalado `openjdk@21` vía brew en `/opt/homebrew/opt/openjdk@21` (aislado, sin tocar Android Studio).
- `flutter config --jdk-dir="/opt/homebrew/opt/openjdk@21/libexec/openjdk.jdk/Contents/Home"` → Java 21.0.12.1.
- `flutter doctor --android-licenses` aceptadas.
- `android/gradle/wrapper/gradle-wrapper.properties`: `8.12` → `9.3.1`.
- `android/settings.gradle.kts`: AGP `8.9.1` → `9.1.0`, Kotlin `2.1.0` → `2.4.0`.
- `android/app/build.gradle.kts`: Java `11` → `17`, eliminado `id("kotlin-android")`, `kotlinOptions` → `kotlin { compilerOptions { jvmTarget = JVM_17 } }`.
- `flutter clean + pub get + build apk --debug` → `✓ Built app-debug.apk`.

### Comando para correr
```bash
flutter run -d ACNNBB4C06901747
```

## 3. Backend Render + integración móvil (2026-10-19)

> Hitos de `backend/backend.md` completados: todo lo propuesto (Phases 1–4, Backend/Frontend tasks, seguridad).

### Backend (`webProjects/sedimApp`) — nuevos módulos
| Archivo | Propósito |
|---------|-----------|
| `lib/timezone.js` | Offset cliente/servidor (convención JS, ±14h), diff, fechas UTC↔cliente |
| `lib/auth-jwt.js` | JWT access 24h + refresh 30d (`jsonwebtoken`), almacén con rotación (máx. 5/usuario) y revocación |
| `lib/rate-limiter.js` | Rate limit en memoria por IP+usuario: login 10/15min, refresh 60/15min (429 + Retry-After) |
| `sql/migracion_auditoria_fechas.sql` | Tabla `AuditoriaMovimiento` (fecha_utc + offsets + fecha_cliente persistida), SP, vista, índices — idempotente |
| `test/{timezone,auth-jwt,rate-limiter}.test.js` | 21 tests unitarios nuevos (`npm test` → 33/33) |

### Backend — `server.js` modificado
- **Auth híbrida**: `usuarioActual(req)` unifica sesión web + `Authorization: Bearer` móvil (45 accesos migrados). La web no cambia (cookie primero, navegador nunca envía Bearer).
- `POST /api/login` → rate limit + devuelve `accessToken`/`refreshToken` (la web ignora los campos extra).
- **Nuevos**: `POST /api/token/refresh` (reconsulta permisos/empresas en BD), `GET /api/timezone/client`.
- `POST /api/logout` → revoca todos los refresh tokens del usuario.
- `GET /api/precios/:empresa` → respuesta enriquecida `{productos, serverOffset, clientOffset, diff, serverTime, clientTime}` **solo** con header `X-Timezone-Offset`; sin header = array plano (web intacta).
- **Fixes `/api/mobile/*`**: typo SQL `PreTeme4/5/6` → `PreTema4/5/6`, IGVV real desde tabla `Valores` (estaba 10.5 hardcodeado), `exigirEmpresa()` faltante (403), offset saneado.
- **Seguridad**: `/api/admin/claves` GET/PUT ahora exige Administrador (403); `trust proxy` para Render (req.ip real).
- `package.json`: + `jsonwebtoken@9.0.3`.

### Flutter — archivos nuevos
| Archivo | Propósito |
|---------|-----------|
| `lib/models/company_model.dart` | EmpresaAcceso del login (02 Cocinería / 04 Mar Picante / 06 Abruzzo) |
| `lib/models/permission_model.dart` | Claves de módulos ('herramientas', 'operaciones', …) + value object |
| `lib/models/price_model.dart` | Respuesta precios con timestamps/offsets (acepta objeto móvil y array legacy) |
| `lib/services/token_storage.dart` | Persistencia SharedPreferences: tokens + usuario |
| `lib/providers/company_provider.dart` | Dropdown multi-empresa + `seleccionar()` validado |
| `backend/schemas/*.ts` | DTOs TypeScript del contrato API (price/user/system-key response) |

### Flutter — modificados
- `api_service.dart`: interceptores Bearer + `X-Timezone-Offset` (conversión Dart→JS: se niega `timeZoneOffset`), **tokenRefreshInterceptor** (401 → refresh single-flight → retry ×1), `logout()` con revocación, endpoints móviles con fallback legacy, timeouts 20s/30s (cold start Render), `sesionInvalidada` → vuelve al login.
- `user_provider.dart`: `restoreSession()`, `setUser(tokens)`, `hasPermission()`, `isAdmin`.
- `user_model.dart`: `permisos[]`, `empresas[]`, helpers.
- `main.dart`: splash + restauración de sesión + listener sesión expirada.
- `login_screen.dart` / `price_screen.dart` / `keys_screen.dart` / `home_screen.dart` / `side_menu.dart`: tokens, dropdown autorizado + info timezone, permisos vía provider, logout con revocación.
- `pubspec.yaml`: `shared_preferences: ^2.5.3`.

### Verificación
| Prueba | Resultado |
|---|---|
| `npm test` (backend) | 33/33 (21 nuevos) |
| `flutter analyze` | 0 issues |
| `flutter test` | 9/9 (PermissionModel, UserModel, CompanyProvider) |
| Smoke test servidor | 401 protegidos, 400 login falso, 429 tras 10 intentos, DB Azure accesible |
| Auditoría web (`public/`) | Sin impacto: web no envía Bearer ni X-Timezone-Offset, no usa `/api/admin/claves`, login muestra el 429 correctamente |

### Pendientes de este hito
- [ ] Desplegar backend a Render (`git push` en sedimApp) — cambios locales
- [ ] Ejecutar `sql/migracion_auditoria_fechas.sql` en Azure SQL (MPRestaurante)
- [ ] Pruebas E2E contra Render + casos concurrencia/rollback

## 4. Roadmap

### Fase 1 — Estabilizar Android (actual)
- [x] Toolchain compatible
- [ ] Cambiar `applicationId`/`namespace` de `com.example.sedim_app` a ID real
- [ ] Revisar `minSdk/targetSdk` vs Android 15 del HONOR
- [ ] Firma release real (hoy usa debug keys)
- [ ] Probar `flutter build apk --release` + `flutter run --release`

### Fase 2 — Calidad código
- [x] `flutter analyze` limpio (0 issues — 2026-10-19)
- [x] Tests en `test/` (`flutter test` → 9/9 — 2026-10-19)
- [ ] Actualizar deps con `flutter pub outdated` (hay 23 con versiones nuevas: dio, google_fonts, flutter_lints, etc.)

### Fase 3 — Producto
- [x] Roles/permisos definidos: `PermissionModel` + filtro UI por `permisos[]` + middleware backend por módulo (2026-10-19)
- [ ] Gestión de contraseñas en la app (validación/cambio — endpoint `/api/validate-password` existe en backend)
- [ ] Temas + menú lateral (ver commit `fb34431`)
- [ ] Icono, splash y nombre real de app
- [ ] Permisos en `AndroidManifest.xml` auditados

## 5. Notas técnicas
- No usar JDK 25 de Android Studio para builds Flutter hasta que Gradle/AGP lo soporten. Mantener `flutter config --jdk-dir` en JDK 21.
- No bajar Gradle a 8.x: Flutter 3.47.2 exige mínimo 8.14, template 9.3.1.
- `adb` está en `~/Library/Android/sdk/platform-tools` (no está en PATH por defecto).
- **Backend desplegar**: `cd webProjects/sedimApp && git push` activa JWT/refresh/timezone en Render. Hasta entonces la app funciona con el fallback legacy (cookies + `/api/precios`).
- **Rate limit login**: 10 intentos/15min por IP+usuario (429). Si la app muestra "Demasiados intentos", esperar la ventana.
- **Refresh tokens en memoria del servidor**: cada reinicio/deploy de Render invalida sesiones móviles → re-login (seguro por diseño; si se quiere persistente, mover el almacén a BD en un futuro).
- **Timezone**: la app envía `X-Timezone-Offset` en minutos convención JS (`-DateTime.now().timeZoneOffset.inMinutes`; Perú UTC-5 = 300).
