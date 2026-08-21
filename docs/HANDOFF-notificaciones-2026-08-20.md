# HANDOFF — SISTEMA DE AVISOS · 2026-08-20 (sesión 2)

> Continúa `HANDOFF-2026-08-20.md`, cuyo §6 marcaba esto como la próxima tarea. **Ese §6 ya está
> hecho salvo Firebase.** Cubre backend y app (el panel no se tocó).
>
> **Todo commiteado, empujado y desplegado.** Backend `38dcb23` · app `401021c`.
> **APK nuevo: 1.0.0 (8)** — sin probar en el teléfono todavía.
>
> El documento completo del sistema, con el porqué de cada decisión, es
> **[edv-route-backend/docs/features/notifications.md](../../edv-route-backend/docs/features/notifications.md)**.
> Esto es solo el estado y lo que sigue.

## 0. Estado en una línea

El afiliado ya **se entera de lo que le pasa**: cada hecho de dinero y de aprobación escribe su
aviso dentro de la misma transacción, la app tiene una bandeja y el header una campana. Lo único
que falta es que el teléfono **suene** — la Fase 4, Firebase, que es puro transporte.

---

## 1. Lo que se construyó (4 commits)

| Fase | Commit | Contenido |
|---|---|---|
| **1 · Tablas y buzón** | `93fde1f` | Migración `1752450000000`: `notifications` (bandeja **y** buzón en una sola tabla) y `device_tokens`; enums `notification_type` (15 casos), `notification_push_status`, `device_platform`; ajuste `notifications_enabled` **apagado**. `notification-writer.ts` (recibe el **cliente de la transacción**), `push-sender.ts` (interfaz + enviador de mentira) y `notification-dispatcher.ts` (quinto scheduler) |
| **1b · Dónde nacen** | `342eb47` | Los 15 avisos enganchados a su hecho. `notification-messages.ts` con toda la redacción. `reject` de pago y `reviewVehicle` pasaron a ser transaccionales |
| **2 · Bandeja (API)** | `38dcb23` | `GET/POST /driver-auth/me/notifications[/:id/read \| /read-all]` y `unreadNotifications` dentro de `/me/account` |
| **2 y 3 · App** | `401021c` | Capa de dominio y datos, pantalla de avisos apilada y **campana dorada en el header** |

**Pruebas**: backend **55/55** (22 nuevas en tres suites), app **58/58**, `flutter analyze` limpio.

---

## 2. Las decisiones que más pesan

Las de detalle están en el documento del sistema y en `decisions-log.md`. Estas cuatro son las que
hay que tener presentes para no romper nada:

1. **El aviso viaja dentro de la transacción del hecho.** Si el pago se revierte, el aviso se va
   con él. Por eso `notify` recibe el **cliente**, no el pool. **Nunca** llamar al proveedor de
   push dentro de una transacción de dinero: colgaría el tick del motor y avisaría de algo que
   puede no ocurrir.
2. **`deliver_after` separa el AVISO del HECHO sin perder atomicidad.** El motor marca la mora a
   las 00:05 y en esa misma transacción programa el mensaje para las **7:00 am**.
3. **La bandeja lista solo lo que ya ocurrió** (`deliver_after <= now()`). El recordatorio del
   domingo no está en la bandeja hasta que sea domingo.
4. **El texto se redacta en el servidor y se guarda en la fila.** La app pinta `title`/`body` tal
   como llegan; del `type` solo deriva icono y color. Si el teléfono redactara, la bandeja y el
   push dirían cosas distintas y corregir una palabra exigiría publicar un APK.

---

## 3. ⚠️ Los candados que NO se pueden tocar

**Producción y desarrollo comparten la misma base de datos.**

- El despachador **no arranca fuera de `NODE_ENV=production`**. En tu máquina verás en el log
  `notification dispatcher NOT started`. **Es correcto, no es un fallo.** Sin ese candado, probar
  un rechazo de pago en local manda el monto a un chofer real.
- `app_settings.notifications_enabled` está **apagado**. Los avisos se escriben y se ven en la
  bandeja, pero **no sale ningún push** (hoy tampoco existiría: el enviador es el de mentira).
- **Riesgo que los candados no cubren**: un aviso escrito desde tu backend local queda en la BD
  compartida y **producción lo despacharía**. Mientras el interruptor esté apagado da igual;
  encenderlo significa que ya no se prueba a ciegas contra prod.
- El interruptor lo lee **el plugin**, no la función de despacho, para que la suite pruebe la
  entrega sin tocar la fila global (el 18/08 correr las pruebas apagó el motor de deuda en
  producción sin que nadie se enterara).

---

> ✅ **La Fase 4 se hizo el 2026-08-21 y está ENCENDIDA en producción.** Ese día además se
> arreglaron once problemas salidos de usar la app en el teléfono. Continúa en
> **[HANDOFF-2026-08-21.md](HANDOFF-2026-08-21.md)**.

## 4. ~~LO QUE SIGUE~~: Fase 4 — Firebase ✅ HECHA

Es lo único que falta del bloque. Nada de lo anterior depende de ello.

1. **Cuenta y proyecto Firebase**. `google-services.json` en la app: es identificador público y
   **sí se versiona**. La clave de servidor va **solo** en `edv-route-backend/.env` (regla 3).
2. **`FcmPushSender`** implementando `PushSender`. Es la **única** pieza que cambia — el
   despachador, el buzón y la bandeja no se tocan. Mandar **mensajes de notificación** (los pinta
   el sistema), **no** de datos: sobreviven mucho mejor a Xiaomi/Oppo/Vivo y funcionan con la app
   cerrada.
3. **Endpoints de `device_tokens`**: registrar al abrir y al rotar; **revocar al cerrar sesión**.
   ⚠️ Si no se revoca, el siguiente que use ese teléfono recibe los montos y los motivos de
   rechazo del anterior. El `UNIQUE` global del token tapa el otro lado (reapunta la fila cuando
   otro chofer entra en el mismo aparato), pero **hay que cerrar las dos puertas**.
4. **Permiso de notificaciones en Android 13+**: es explícito y se puede negar. Y los Huawei
   posteriores a 2019 no tienen Play Services y **nunca** recibirán push. Para todos ellos la
   bandeja es el único canal — por eso no era opcional.
5. **Encender `notifications_enabled`**, y solo entonces salen push reales.

**Coste**: FCM gratis. iOS pediría los $99/año de Apple; hoy solo hay APK Android.

---

## 5. Cómo probarlo ahora mismo (sin Firebase)

**APK 1.0.0 (8)**: `build/app/outputs/flutter-apk/app-release.apk` (51,2 MB, apunta a producción).

La bandeja solo tiene contenido si **ya ocurrió algo**. Una cuenta recién creada la verá vacía.
Para llenarla, con el chofer de prueba **V-22198958 / 123456**:

1. Desde el panel (**admin / EdvRoute2026**), rechaza uno de sus pagos con un motivo.
2. Abre la app: la campana debe mostrar **1** en dorado sobre el header rojo.
3. Toca la campana → aparece el aviso **«Pago rechazado»** con el motivo dentro del texto.
4. Al abrirlo deja de estar en negrita y el contador baja; al volver atrás la campana ya está
   apagada, **sin recargar nada**.

Otra vía rápida: aprobarle un documento o un vehículo desde el panel produce su aviso al instante.

**Marcos Gonzales V-23654789** ya tiene un pago rechazado con motivo y el vehículo `TST9099` en
revisión — sirve para ver los dos tipos de tarjeta.

---

## 6. Otros pendientes (heredados, por orden de daño)

1. **Probar en el teléfono el flujo completo del vehículo** (§3 del handoff anterior) y ahora
   también la campana y la bandeja.
2. **`authenticateDriver` no valida el status** (`src/plugins/auth.ts:51`): solo firma y
   audiencia. Un rechazado o suspendido opera hasta 8 h más. Importa el doble porque `canOperate`
   se enchufa ahí cuando llegue Viajes.
3. **No hay «olvidé mi clave»**: usuario = cédula, clave puesta por un admin.
4. **Límite de 1000 líneas violado**: `drivers.service.ts` (**1160**, subió ~39 en la Fase 1b) y
   `enrollment.repository.ts` (1174). Ya violaban antes; conviene partirlos por responsabilidad
   antes de añadirles nada más.
5. **La numeración de facturas tiene huecos grandes** (saltó de 29 a 664): las transacciones
   abortadas consumen números de secuencia y la suite corre contra la misma base.
6. **Módulo de Viajes**: lo único grande que falta. **Bloqueado por una decisión de producto**:
   los viajes necesitan **pasajeros** y `clients` no existe. La primera pregunta es de dónde salen
   (app propia, operadora por WhatsApp, central).
7. **Crédito de Railway**: quedaban 7 días / $4.44 el 2026-08-20.

---

## 7. Gotchas (siguen vigentes)

- **prod = dev, misma BD.** No correr dos backends: `buildApp()` abre pool de **10**.
- **La suite del backend NO es determinista** (el scheduler de prod tickea sobre la misma base).
  Si `debt-engine.test.ts` falla suelto, vuelve a correrlo aislado antes de investigar.
- **Chofer de prueba**: V-22198958 / 123456 · **Admin**: admin / EdvRoute2026.
- **Para probar como un chofer sin su clave**: firmar un token con el `JWT_SECRET` del `.env`
  (`{sub: userId, type: 'driver'}`, HS256).
- **El MCP de Supabase no tiene permisos** para `execute_sql`: usar un script node con `pg`.
- **No usar `node -e` con backticks** para editar archivos desde bash: el shell se los come.
- ⚠️ **Backticks dentro de un template literal de SQL** cortan la cadena y dan un error de sintaxis
  de TypeScript desconcertante (`TS1005`) a decenas de líneas del sitio real. Pasó escribiendo un
  comentario SQL en el motor de deuda.
- **Fastify serializa contra el schema**: un campo que no esté declarado en la respuesta **se
  borra en silencio**. Pasó con `rejected`, con `tariffStartsAt` y casi con `unreadNotifications`.
- ⚠️ **`exactOptionalPropertyTypes` está activo**: un campo opcional que pueda recibir `undefined`
  hay que declararlo `T | undefined` explícitamente.
- Postgres: no existe `min(uuid)`, `make_interval` no acepta `numeric`, dentro de `RETURNING` la
  columna **ya trae el valor nuevo**, y reusar el mismo parámetro como valor de columna **y** como
  operando de comparación da `42P08` ("text versus integer") — hay que castear.

---

## 8. Línea de contexto para retomar

> Retomamos EDV Route (C:\Project\edv). Lee `edv-route-mobile/docs/HANDOFF-notificaciones-2026-08-20.md`
> y `edv-route-backend/docs/features/notifications.md`. Los **tres** repos están limpios, empujados
> y **desplegados** (backend `38dcb23`, app `401021c`, panel `5f93740`); **APK vigente 1.0.0 (8)**,
> sin probar en el teléfono. El **sistema de avisos está hecho salvo Firebase**: buzón
> transaccional, los 15 avisos enganchados a sus hechos, bandeja en la app y campana en el header;
> backend 55/55 y app 58/58. **Siguiente tarea: la Fase 4 (Firebase)** — §4 de ese handoff.
> Ojo: prod y dev comparten BD (el despachador no arranca fuera de `NODE_ENV=production` y
> `notifications_enabled` sigue apagado), la suite es no determinista por lo mismo, y a Railway le
> quedaban 7 días de crédito el 20/08.
