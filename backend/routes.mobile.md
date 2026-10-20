# Mobile API Routes - Implementation Plan

## Overview
Esta documentación contiene la planificación de los nuevos endpoints exclusivos para la móvil reemplazando la migración automática de endpoints de producción.

---

## Endpoints Móviles (NEW)

### 1. Timezone Client Handler

**Endpoint:** `GET /api/mobile/timezone/client`

**Purpose:** Recuperar la zona horaria del cliente móvil para ajustar los precios.

**Routing:**
```javascript
app.get('/api/mobile/timezone/client', mobileAuthMiddleware, async (req, res) => {
  try {
    const timezoneOffset = Number(req.headers['x-timezone-offset']);
    if (!timezoneOffset) {
      return res.json({ serverTimezone: 0, clientTimezone: 0 });
    }
    res.json({
      serverTimezone: 0, // Server en UTC-5 (ej: Perú)
      clientTimezone: timezoneOffset, // Horario del cliente
      message: 'TIMEZONE SUCCESS'
    });
  } catch (error) {
    res.status(500).json({ message: 'Timezone ERROR' });
  }
});
```

**Headers:**
- `X-Timezone-Offset`: número (ej: 180 = -5 horas, -190 = 6 horas)

**Response:**
```json
{
  "serverTimezone": 0,
  "clientTimezone": 180,
  "message": "TIMEZONE SUCCESS"
}
```

**Usage:**
- Móvil envía su offset: `GET /api/mobile/timezone/client` con header
- Móvil recibe server offset y client offset para cálculos

---

### 2. Mobile Prices Handler

**Endpoint:** `GET /api/mobile/prices/:empresa`

**Purpose:** Listar productos por empresa con soporte inicial de zona horaria adaptiva.

**Original:** `/api/prices/:empresa` (mantenido para compatibilidad)

**Modifications:**
```javascript
app.get('/api/mobile/prices/:empresa', mobileAuthMiddleware, async (req, res) => {
  const { empresa } = req.params;
  
  // Validar empresa
  if (!['02', '04', '06'].includes(empresa)) {
    return res.status(400).json({ message: 'Empresa no válida' });
  }

  try {
    const pool = await getConnection();
    
    // OBTENER TIMEZONE DEL CLIENTE
    const timezoneOffset = Number(req.headers['x-timezone-offset']) || 0;
    const serverTimezone = 0; // Server en Perú (UTC-5)
    
    // CÁLCULO DE TIMEZONE
    const timezoneDiff = timezoneOffset - serverTimezone;
    const slowFactor = timezoneDiff * 3600000; // Diferencia en milisegundos

    // Consulta principal con cálculo de timezone
    const query = `
      DECLARE @factor DECIMAL(10, 4) = 1 + (10.50 / 100);
      DECLARE @timezoneDiff INT = ${timezoneDiff};
      
      SELECT 
        p.CodPro, 
        p.Nombre,
        round((
          CASE 
            WHEN p.Afecto = 1 THEN @factor
            ELSE 1 
          END 
        ) * ISNULL(pr.PreTema1, 0), 4) as PreTema1,
        round((
          CASE 
            WHEN p.Afecto = 1 THEN @factor
            ELSE 1 
          END 
        ) * ISNULL(pr.PreTema2, 0), 4) as PreTema2,
        round((
          CASE 
            WHEN p.Afecto = 1 THEN @factor
            ELSE 1 
          END 
        ) * ISNULL(pr.PreTema3, 0), 4) as PreTema3,
        round((
          CASE 
            WHEN p.Afecto = 1 THEN @factor
            ELSE 1 
          END 
        ) * ISNULL(pr.PreTema4, 0), 4) as PreTeme4,
        round((
          CASE 
            WHEN p.Afecto = 1 THEN @factor
            ELSE 1 
          END 
        ) * ISNULL(pr.PreTeme5, 0), 4) as PreTema5,
        round((
          CASE 
            WHEN p.Afecto = 1 THEN @factor
            ELSE 1 
          END 
        ) * ISNULL(pr.PreTeme6, 0), 4) as PreTeme6
      FROM Productos p 
      LEFT JOIN Precios pr ON p.CodPro = pr.Codpro 
      WHERE p.Tipo = 3 
        AND p.CodPro LIKE @prefix + '%' 
        AND p.Eliminado = 0
      ORDER BY p.Nombre ASC
    `;

    const result = await pool.request()
      .input('prefix', sql.VarChar, empresa)
      .query(query);
    
    // Respuesta con timezone data
    res.json({
      serverTimezone: serverTimezone,
      clientTimezone: timezoneOffset,
      diff: timezoneDiff,
      productos: result.recordset,
      message: 'TIMEZONE PRICING RETRIEVED'
    });
  } catch (e) {
    console.error(e);
    res.status(500).json({ message: 'TIMEZONE ERROR' });
  }
});
```

**Headers:**
- `X-Timezone-Offset`: Opcional, número entero (ej: 180)

**Response:**
```json
{
  "serverTimezone": 0,
  "clientTimezone": 180,
  "diff": 180,
  "productos": [
    {
      "CodPro": "020001",
      "Nombre": "Producto Ejemplo",
      "PreTeme1": 15.5021,
      "PreTeme2": 16.4522,
      ...
    }
  ],
  "message": "TIMEZONE PRICING RETRIEVED"
}
```

**Compatibility:**
- Si NO hay header `X-Timezone-Offset` = Server usa timezone default (mantenemos compatibilidad con lo que ya existe)
- Si SÍ hay header = Server calcula offset

---

### 3. Mobile Keys Handler (Admin Only)

**Endpoint:** `GET /api/mobile/keys`

**Purpose:** Listar claves del sistema con stricto check de permisos ADMIN.

**Modifications:**
```javascript
async function isMobileAdmin(user) {
  const rolNormalizado = String(user?.rol || '').trim().toLowerCase('es-PE');
  return rolNormalizado === 'administrador';
}

app.get('/api/mobile/keys', isAuthenticated, async (req, res) => {
  // Verificación de ROL (ESTAMPAR)
  if (!isMobileAdmin(req.session.user)) {
    return res.status(403).json({ 
      message: 'SOLO ADMINISTRADOR PUEDE ACCEDER'
    });
  }

  try {
    const pool = await getConnection();
    const result = await pool.request()
      .query("SELECT n_numero, c_describe, conversion FROM Tablas WHERE n_codtabla = 603 ORDER BY n_numero");
    
    res.json({
      keys: result.recordset,
      message: 'ADMIN KEYS RETRIEVED'
    });
  } catch (e) {
    console.error(e);
    res.status(500).json({ message: 'ADMIN KEYS ERROR' });
  }
});
```

**Headers:**
- Sesión requiere auth con role `Administrador`

**Response:**
```json
{
  "keys": [
    {
      "n_numero": 1302,
      "c_describe": "CLAVECOMISION",
      "conversion": "1302"
    }
  ],
  "message": "ADMIN KEYS RETRIEVED"
}
```

**Security:**
- ⚠️ Solo roles 'Administrador'
- ⚠️ Deny acceso explícito a otros roles

---

### 4. Mobile Keys Update Handler

**Endpoint:** `PUT /api/mobile/keys/:id`

**Purpose:** Actualizar valor de clave con security improvements.

```javascript
app.put('/api/mobile/keys/:id', isAuthenticated, async (req, res) => {
  const { id } = req.params;
  const { valor } = req.body; // Nuevo valor en formato string

  // SECURITY CHECK
  if (!isMobileAdmin(req.session.user)) {
    return res.status(403).json({ 
      message: 'SOLO ADMINISTRADOR PUEDE ACCEDER'
    });
  }

  // VALIDACIÓN DE DATOS
  if (!Number.isInteger(Number(id)) || id <= 0) {
    return res.status(400).json({ 
      message: 'ID de clave válido requerido' 
    });
  }

  try {
    const pool = await getConnection();
    
    // CONVERTIR valor a float con método seguro
    const valorFloat = parseFloat(valor);
    if (isNaN(valorFloat)) {
      return res.status(400).json({ 
        message: 'Valor numérico inválido' 
      });
    }

    const result = await pool.request()
      .input('id', sql.Int, id)
      .input('val', sql.Float, valorFloat)
      .query("UPDATE Tablas SET conversion = @val WHERE n_codtabla = 603 AND n_numero = @id");

    if (result.rowsAffected[0] === 0) {
      return res.status(404).json({ 
        message: 'No se encontró la clave solicitada' 
      });
    }

    res.json({
      message: 'CLAVE ACTUALIZADA EXITOSAMENTE',
      clave: id,
      nuevoValor: valorFloat
    });
  } catch (e) {
    console.error(e);
    res.status(500).json({ message: 'ERROR AL ACTUALIZAR CLAVE' });
  }
});
```

**Headers:**
- Sesión requiere auth con role `Administrador`
- Body: `{ "valor": 1500.50 }`

**Response (Success):**
```json
{
  "message": "CLAVE ACTUALIZADA EXITOSAMENTE",
  "clave": 1302,
  "nuevoValor": 1500.5
}
```

**Response (Error):**
```json
{
  "message": "SOLO ADMINISTRADOR PUEDE ACCEDER"
}
```

---

## Web Compatibility Notes

### Routes MANTENIDAS (Web Still Works)
```
GET  /api/login           → Session-based login
POST /api/login           → 
GET  /api/logout          → Session destroy
POST /api/logout          → 
GET  /api/prices/:empresa → Server timezone default (EXISTING)
PUT  /api/prices/:codpro  → 
GET  /api/admin/claves    → Auth only, no permission check (EXISTING)
PUT  /api/admin/claves/:id→ Auth only, no permission check (EXISTING)
```

### Rutas NUEVAS (Mobile Only)
```
GET  /api/mobile/timezone/client   → TIMEZONE NEW (MOBILE)
GET  /api/mobile/prices/:empresa   → TIMEZONE MOBILE
GET  /api/mobile/keys              → SECURITY MOBILE
PUT  /api/mobile/keys/:id          → SECURITY MOBILE
```

---

## Authentication Strategy

### Current Web (Session)
```javascript
POST /api/login → Server setea req.session.user
```

### Proposed Mobile (JWT)
```javascript
POST /api/mobile/auth/login → Return { accessToken, refreshToken }
GET  /api/mobile/some/endpoint → Header: Authorization: Bearer <token>
```

**Nota:** Este cambio será implementado en Phase 2 (separado de este archivo)

---

## Migration Checklist

- [ ] Crear nuevas rutas móviles bajo `/api/mobile/*`
- [ ] Implementar timezone header parsing en móviles
- [ ] Migrar móvil a usar seus endpoints (reemplaza /api/admin/claves)
- [ ] Evaluar migrar móvil a JWT en Phase 2
- [ ] Test de compatibilidad: Web AND Móvil coexistiran perfectamente
- [ ] Deploy en Render: Backend sin cambios de BREAKPOINTS

---

## Testing Commands

### Timezone Client
```bash
curl -H "X-Timezone-Offset: 180" http://localhost:3000/api/mobile/timezone/client
```

### Mobile Prices
```bash
curl -H "X-Timezone-Offset: 180" http://localhost:3000/api/mobile/prices/02
```

### Mobile Keys (Admin Only)
```bash
curl -v -X PUT http://localhost:3000/api/mobile/keys/1302 \
  -H "Content-Type: application/json" \
  -d '{"valor": "1500.50"}'
```

---

**Status:** 🔄 PENDING IMPLEMENTATION (Next Phase)