# EDV Route Mobile — Handoff (feature: registro de chofer)

> ⚠️ **ESTADO ACTUAL → [HANDOFF-2026-08-31-app-cliente.md](HANDOFF-2026-08-31-app-cliente.md)**
> (la app del pasajero completa y rediseñada). **Todo lo de abajo es el plan histórico
> (2026-08-03)**: sirve como referencia de arquitectura/gotchas, pero el "estado" y los
> "próximos pasos" ya están superados.

> Documento de continuidad. Léelo completo antes de seguir. Fecha: 2026-08-03.
> Proyecto: `C:\Project\edv\edv-route-mobile` (Flutter + Dart, Material 3).
> Reglas del usuario: chat/explicaciones en **español**, código/comentarios en **inglés**.
> Si el prompt es una **pregunta** (termina en `?`), modo **solo-lectura** (no editar).

---

## 1. Qué es esto

App móvil de EDV Route para **choferes y clientes**, tercer proyecto del monorepo junto a
`edv-route-admin` (Angular 22) y `edv-route-backend` (Fastify 5 + TS ESM + PostgreSQL/PostGIS en
Supabase). La app se **espeja del admin** en marca y reglas. Alcance acordado por ahora:
**login + registro**; el resto (dashboard/perfil) se enriquece después.

Stack: Flutter 3.35.7 · Dart 3.9.2 · Material 3 · deps: `http` + `flutter_secure_storage`.
Org: `com.edvroute`. Package: `com.edvroute.edv_route_mobile`.

## 2. Estado actual — qué está HECHO y funcionando

- **Fase 1 — Pantallas**: selección de modo (Chofer activo / Cliente "Próximamente") + login.
- **Fase 2 — Login end-to-end** (verificado en emulador): chofer por **cédula (V/E/J + dígitos) +
  clave**. Backend módulo `driver-auth` (`POST /driver-auth/login`, `GET /driver-auth/me`), JWT
  con claim `type` (`admin`|`driver`), guards por audiencia. Token en secure storage.
- **Fase 3 — Dashboard + Perfil + Logout** (super simple): `DriverRootScreen` enruta por estado →
  `DriverShell` (nav Inicio/Perfil) con dashboard (saludo + tarjeta Estado/Disponible UI-only +
  tiles placeholder) y perfil (datos + Cerrar sesión con confirmación). `DriverStatusScreen`
  para revisión/bloqueado.
- **Rediseño/pulido**: componente `AuthHeader` unificado (logo grande, glow dorado + líneas de
  velocidad, título/subtítulo consistentes, flecha atrás circular); botón primario con degradado
  + sombra; campos rellenos suaves con ícono; selector V/E/J. Todo hereda **Montserrat**.
- **Backend catálogos para la app** (typecheck OK, probados en local):
  `GET /driver-auth/requirements` (requisitos activos driver+vehicle con `isRequired`) y
  `GET /driver-auth/payment-methods` (activos, **sin `cash_usd`**).

Verificación: `flutter analyze` limpio, tests (incl. golden tests en `test/golden_test.dart`,
PNGs en `test/goldens/`), `flutter build web` OK.

**NADA de la app ni del `driver-auth` está commiteado/pusheado.** No hay repo git de la app aún.
El backend `driver-auth` vive solo local (typecheck OK), **no desplegado a prod**.

## 3. Cómo correr y probar (GOTCHAS críticos)

- **Emulador Android** (Android Studio, AVD `Android_1` = `Medium_Phone.avd`, API 35, disco
  subido a **12 GB** y wipe hecho — ya no falla por espacio).
- **CORRER SIEMPRE ASÍ** (desde `C:\Project\edv\edv-route-mobile`), NO con el botón verde "app":
  ```
  flutter run --dart-define=API_BASE_URL=http://10.0.2.2:3000/api/v1 -d emulator-5554
  ```
  El botón "app" (Gradle) **ignora el `--dart-define`** → la app cae en **prod** (404, el endpoint
  no está desplegado) y además reinstala llenando el emulador. Hay una run config lista en
  `.run/main_local.run.xml` (aparece si abres la carpeta raíz del Flutter, no la `android/`).
- **Emulador → host**: se alcanza por `10.0.2.2` (no `localhost`). Cleartext HTTP habilitado solo
  en debug (`android/app/src/debug/AndroidManifest.xml`).
- **Base URL**: default = **producción** (`https://edv-route-backend.up.railway.app/api/v1`), en
  `lib/core/config/app_config.dart`. Se overridea con `--dart-define=API_BASE_URL=...`.
- **Backend local**: el server en `:3000` suele estar corriendo (otra sesión con `npm run dev`,
  tsx-watch → toma los cambios al guardar). ⚠️ **El `.env` apunta a la BD de PRODUCCIÓN (Supabase
  compartida)** y arrancar el backend dispara el **motor de deuda en el boot**. NO correr la suite
  de tests ni levantar un segundo `npm run dev` a la ligera. Probar endpoints read-only por
  PowerShell (`Invoke-RestMethod http://127.0.0.1:3000/...`) es seguro.
- **Chofer de prueba**: cédula **V-22198958**, clave **123456** (status `approved`, "EDV Route").
- **Supabase MCP `execute_sql`**: bloqueado por permisos (no usar para consultar la BD).
- **Otro agente trabaja el mismo backend** en paralelo (pagos v9 ya pusheado a `main`). Coordinar;
  **no pushear sin que el usuario lo pida**.

## 4. Arquitectura Flutter (estructura de carpetas, ordenada)

```
lib/
  main.dart · app.dart (MaterialApp + rutas)
  core/
    config/app_config.dart        (base URL, dart-define)
    network/api_client.dart       (http JSON, bearer, mapea errores → ApiException)
    network/api_exception.dart
    storage/token_storage.dart    (flutter_secure_storage)
    di.dart                       (composition root: Dependencies.instance.authRepository)
  routing/app_routes.dart         (selection '/', driverLogin '/driver/login')
  theme/app_colors.dart           (tokens de marca exactos, ver §) · app_theme.dart (Material 3)
  shared/widgets/
    auth_header.dart              (cabecera unificada: logo+título+subtítulo+back opcional)
    gradient_header.dart          (degradado marca + decoración)
    primary_button.dart           (pill degradado + sombra)
    brand_text_field.dart · password_field.dart (con prefixIcon)
  features/auth/
    data/ (datasources/auth_remote_data_source, models/driver_dto, repositories/auth_repository_impl)
    domain/ (entities/driver [Driver + DriverStatus], repositories/auth_repository [interfaz])
    presentation/
      controllers/driver_login_controller.dart (ChangeNotifier)
      screens/ (user_type_selection_screen, driver_login_screen)
      widgets/ (user_mode_card, national_id_field [selector V/E/J + dígitos])
  features/home/
    presentation/
      screens/ (driver_root_screen [enruta por estado], driver_shell [nav],
                dashboard_screen, profile_screen, driver_status_screen)
      widgets/dashboard_tile.dart
      status_presentation.dart (status → label+color) · logout_action.dart (confirm + logout)
```

**Marca (tokens en `lib/theme/app_colors.dart`, espejo del admin):** primary `#920606`,
primaryDark `#661212`, gold `#EBCA54`, degradado `#920606 → #1a0303`, tipografía **Montserrat**
(TTF en `assets/fonts/`), logo dorado recortado en `assets/images/edv_logo_gold.png`.

**Patrón de red/estado**: pantalla → controller (ChangeNotifier) → repository (interfaz en domain)
→ data source → `ApiClient`. `Dependencies.instance` en `core/di.dart` es el composition root.

## 5. Backend — lo que existe para la app (módulo `driver-auth`)

`edv-route-backend/src/modules/driver-auth/` (routes/service/repository/schemas). Registrado en
`app.ts` con prefijo `/driver-auth` bajo `/api/v1`.
- `POST /driver-auth/login` (público) → `{ token, driver }`. argon2 vs `users.password_hash` (join
  `drivers`), verificación timing-safe. Login abierto; la app enruta por `status`.
- `GET /driver-auth/me` (guard `authenticateDriver`).
- `GET /driver-auth/requirements` (público) → `[{id,name,description,appliesTo,isRequired}]`.
- `GET /driver-auth/payment-methods` (público) → `[{id,name,type,details}]` activos, sin admin_only.

Guards (`src/plugins/auth.ts`): `authenticate` exige `type==='admin'`; `authenticateDriver` exige
`type==='driver'`. Los tokens de admin ahora llevan `type:'admin'` (los viejos se rechazan → re-login).

Docs backend ya actualizadas: `docs/api/endpoints.md` (sección "Auth chofer") y
`docs/decisions/decisions-log.md` (entrada 2026-08-03 login de chofer).

---

## 6. FEATURE EN CURSO: registro de chofer desde la app

### 6.1 Requisito del usuario
Implementar el registro **adaptando el wizard del admin**, con esta diferencia:
**en la app los 4 pasos son OBLIGATORIOS**; en el admin solo el paso 1 es obligatorio.
Los 4 pasos: **1) Datos personales · 2) Documentos del chofer · 3) Vehículo(s) · 4) Pago**.

### 6.2 Decisiones cerradas (confirmadas por el usuario)
- **Flujo**: registro JSON → **auto-login** (devuelve token de chofer) → subir archivos y pago con
  ese token. (No un multipart gigante.)
- **Pago**: replicar EXACTO el sistema del admin (pagos-v9, aprobación manual). El pago queda
  **pendiente** y un admin lo aprueba.

### 6.3 El flujo de pago (DELICADO) — cómo funciona en el admin (a replicar)
Confirmado en `edv-route-admin/src/app/features/drivers/driver-wizard.ts` (método `register`):
1. El admin **siempre registra con `payment: null`** → `DriversService.register` emite el **alta
   como DEUDA** (`enrollDebtOnClient`: membresía + 1 semana, impaga) y el chofer queda `pending`.
2. Sube archivos (documentos, fotos) best-effort.
3. Si hubo pago capturado, lo manda como **payment-submission** con **`purpose='debt'`**
   (`buildDebtForm`, NO envía semanas). El backend deriva `amountUsd = deuda del chofer`. Queda
   **`pending`**. Endpoint: `POST /drivers/:id/payment-submissions` (multipart).
4. Un admin **aprueba el pago** (Facturación → "Por aprobar") → liquida cargos + emite **1 factura**.
5. Un admin **aprueba al chofer** (requiere membresía pagada + tarifa + deuda 0).

**Implicación para la app**: el **paso 4 NO es un selector de plan/semanas**, es una **CAPTURA de
pago** (método + comprobante + datos del pagador) para la deuda del alta. Un único envío pendiente
por chofer a la vez.

**Validación por método** (a replicar de `payment-capture.ts`, método `complete()`):
- Siempre: método + `paidOn` (fecha) + **1 comprobante**.
- `bank_transfer`: + `reference` + `payerBank` (de `VENEZUELAN_BANKS`).
- `pago_movil`: + `reference` + `payerBank` + `payerPhone` (`+58`+10 díg, desde local 04121234567) +
  `payerId` (`V/E/J-díg`).
- `zelle` / `binance`: + `reference` + `payerAccount` (email o texto; si trae `@` valida email).
- `cash_usd`: **admin-only, NO va en la app**.

### 6.4 Contratos exactos
- **`POST /drivers/register`** (admin, `drivers.routes.ts:93-147` + `drivers.service.ts:135-320`):
  person (firstName*, lastName*, middleName, secondLastName, birthDate[≥18], address, email,
  phone[`^\+58\d{10}$`], nationalId[`^[VEJ]-\d{5,9}$`], password[6-72]) + `payment` (null en el
  alta) + `vehicles[]` ({vehicleTypeId,brand,model,year,color,plate,documents:[{requirementId}]}) +
  `documents[]` ([{requirementId,expiresAt}]). Responde detalle + `createdDocumentIds` +
  `createdVehicles:[{id,documentIds}]` + `invoiceNumbers`.
- **`POST /drivers/:id/payment-submissions`** (`payment-submissions.routes.ts`, multipart via
  `req.parts()`): campos `purpose`(`debt`|`advance`|`enroll`|`change_plan`), `paymentMethodId`,
  `reference`, `payerBank`, `paidOn`, `payerPhone`, `payerId`, `payerAccount`, `amountUsd`(solo
  cash), `note`, `periods`, `planId` + **1..5 archivos** (parts `type==='file'`). Hoy fuerza
  `source='admin'`, `submittedBy=req.user.sub`.
- **Subida de archivos** (hoy admin-guard, magic-number, PDF/JPG/PNG, 10MB):
  documento `POST /documents/:id/file` (field `file`); foto vehículo
  `POST /drivers/:id/vehicles/:vehicleId/images` (field `file`).
- **`is_required`**: regla "solo obliga en la app" **NO implementada en backend** — hay que
  aplicarla en la vía nueva de la app (bloquear si falta algún requisito activo `isRequired`).

### 6.5 Lo construido en esta feature (hecho)
- ✅ `GET /driver-auth/requirements` y `GET /driver-auth/payment-methods` (§5). Typecheck OK,
  probados: 3 requisitos driver + 3 vehicle (todos required), 4 métodos (sin cash_usd).

### 6.6 PRÓXIMOS PASOS concretos (en orden)

> **✅ ACTUALIZACIÓN 2026-08-04 — el BACKEND (pasos 1 y 2) YA ESTÁ HECHO** (otra sesión, dueña del
> backend; verificado por typecheck, **sin pushear aún**). La app **solo consume** estas URLs, todas
> bajo `/driver-auth` con el token del chofer (**no** manda `driverId` por URL: sale del token). NO
> crear rutas de backend desde la app.
> - `POST /driver-auth/register` (público): body = persona + `vehicles[]` + `documents[]` (los 4
>   pasos; el backend exige credenciales, ≥1 vehículo y todos los requisitos `isRequired`). Responde
>   `{ token, driver, createdDocumentIds, createdVehicles }`. Alta como deuda; chofer `pending`.
> - Con ese token: `POST /driver-auth/documents/:id/file` (archivo del documento propio, field
>   `file`), `POST /driver-auth/vehicles/:vehicleId/images` (foto de vehículo propio, field `file`),
>   `POST /driver-auth/payment-submissions` (multipart: pago del alta, `purpose=debt`; queda pendiente).
> - Un alta a medias se **reanuda** (el login de un `pending` devuelve token); si no se completa, un
>   job la purga a los 7 días. **Para la app solo queda el paso 3 (Flutter).**

1. **`POST /driver-auth/register`** (público, en el módulo `driver-auth`):
   - **Reutilizar `DriversService.register`** (un solo camino de dinero). Requiere parametrizar el
     origen: hoy `register(input, extras, adminId)` fuerza `source:'admin'` y usa `adminId` como
     `registeredBy`; y `DriversRepository.insertUserAndDriver` **hardcodea `source='admin'`**
     (`drivers.repository.ts:164-167`). Cambios mínimos y backward-compatible:
     - `insertUserAndDriver`: aceptar `source` en `CreateDriverData` (default `'admin'`).
     - `register`: aceptar `opts?: { source?: 'admin'|'app'; enforceRequired?: boolean }`; usar
       `registeredBy = source==='app' ? null : adminId`, audit con `source`, y si `enforceRequired`
       exigir que estén todos los requisitos activos `isRequired` (driver y, por vehículo, vehicle).
   - Endpoint: valida person + vehicles + documents (los 4 pasos), llama `register` con
     `{source:'app', enforceRequired:true}` y `adminId=null`, hashea clave (ya lo hace register),
     **emite token de chofer** (`app.jwt.sign({sub:userId, type:'driver'})`) y devuelve
     `{ token, driver, createdDocumentIds, createdVehicles }`.
2. **Subidas con token de chofer** (nuevas rutas driver-audience con verificación de propiedad =
   el recurso pertenece a `req.user.sub`): documento, foto de vehículo, y **payment-submission**
   (`source='app'`, `submittedBy=null`, `purpose='debt'`). Para el submission se puede refactorizar
   `payment-submissions.routes.ts` para exponer una variante driver, o una ruta nueva en
   `driver-auth` que llame a `PaymentSubmissionsService.create(...)` con `source:'app'`.
3. **Flutter — wizard de 4 pasos** (`features/auth/presentation` o nueva `features/registration`):
   Datos (reusar `NationalIdField`, validaciones del §6.4) · Documentos (por cada requisito
   `isRequired` de driver, pedir archivo; usar `image_picker`/`file_picker`) · Vehículo(s) (campos
   + fotos + docs de vehículo required) · Pago (captura por método, validación `complete()` del
   §6.3). Submit: `register` → subir archivos con token → payment-submission → navegar a
   `DriverStatusScreen` (pending → "solicitud en revisión"). Añadir deps `image_picker` y/o
   `file_picker`.
4. Verificar en local (chofer nuevo con cédula distinta a V-22198958) y luego, cuando el usuario
   lo pida, desplegar backend a prod.

### 6.7 Archivos de referencia (leer al implementar)
Admin: `edv-route-admin/src/app/features/drivers/` → `driver-wizard.ts`/`.html`, `person-form.ts`,
`document-draft-modal.ts`, `vehicle-draft-modal.ts`, `payment-draft-modal.ts`, `payment-capture.ts`;
`src/app/core/models/payment-method.model.ts` (tipos, `VENEZUELAN_BANKS`, `PAYMENT_METHOD_FIELDS`).
Backend: `src/modules/drivers/drivers.{routes,service,repository}.ts`,
`src/modules/payment-submissions/` (routes/service/repository),
`src/modules/driver-auth/`, `src/plugins/auth.ts`.
Contrato de pagos v9: `edv-route-backend/docs/proposals/pagos-aprobacion/README.md` (es EL contrato
para la app). API: `edv-route-backend/docs/api/endpoints.md`.

## 7. Warnings / NO hacer
- No correr `npm test` del backend ni un segundo `npm run dev` sin cuidado (BD compartida de prod +
  motor de deuda en boot).
- No pushear nada sin que el usuario lo pida (otra sesión trabaja el backend).
- No usar el botón "app" (Gradle) para correr la app (cae en prod). Usar `flutter run --dart-define`.
- No editar `src/db/models/**` a mano (se regeneran). No tocar `.env`.
- Si el prompt del usuario es pregunta (`?`), modo solo-lectura.
