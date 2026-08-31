# HANDOFF — 2026-08-31 (2ª sesión) · La app del cliente completa y su rediseño

> Continúa `HANDOFF-2026-08-31.md` (mapa del panel, ajustes del afiliado, backend C-a).
> Esta sesión construyó **toda la app del pasajero** (fases C-b a C-d) y luego la rediseñó
> con Luis en caliente, maqueta a maqueta y APK a APK.

## 0. Estado en una línea

El modo pasajero **funciona completo** (entrar con correo o teléfono, registro, perfil con foto,
cambio y recuperación de clave) y su inicio quedó rediseñado a lo «app de viajes»: mapa
protagonista, tarjeta dorada de destino arriba y hoja de confianza. **APK vigente: 1.0.0 (30)**,
pendiente de que Luis confirme en el teléfono.

## 1. Dónde quedó cada repo

| Repo | Rama | Commit | Estado |
|---|---|---|---|
| `edv-route-backend` | `dev` | `09bfc1c` | **Empujado y DESPLEGADO en Railway** (verificado contra producción) |
| `edv-route-admin` | `dev` | `8c51ffc` | Sin tocar esta sesión |
| `edv-route-mobile` | `main` | `e0a6653` | Empujado (C-b a C-d)… **⚠️ y TODO lo posterior SIN commitear** |

⚠️ **Lo sin commitear en la app** (APKs 26 al 30): la separación editar/clave, los headers con
logo+avatar de las subpantallas del perfil, y el rediseño completo del inicio. Un `git status`
lo lista; se guarda con el próximo `!SAVE`/`!PUSH` cuando Luis dé el visto bueno al APK 30.

## 2. Fases C-b y C-c — la app del pasajero (commit `e0a6653`, APK 25)

- **Modo pasajero encendido** en la selección de modo.
- **Entrar**: un solo campo correo O teléfono. ⚠️ La API compara el teléfono **exacto** contra
  el E.164 guardado (`+584121234567`); `ClientLoginController.normalizeIdentifier` convierte
  «0412 123 4567», «0412-1234567», «4121234567», etc. Tiene su propia prueba
  (`test/client_login_identifier_test.dart`).
- **Crear cuenta**: sin cédula, validaciones del afiliado **extraídas a**
  `shared/validators/person_validators.dart` (importadas por ambos formularios, no copiadas —
  el mismo criterio del backend). Registrarse ya deja la sesión abierta.
- **Shell** con isla de 3 iconos (Inicio · Viajes · Perfil). La isla del afiliado se extrajo a
  `shared/widgets/floating_nav.dart` y ambos modos la comparten.
- **Sesiones**: el token del cliente vive en clave propia (`client_session_token`,
  `TokenStorage` parametrizado). El splash reanuda chofer primero, cliente después; por la UI
  nunca coexisten dos sesiones.
- **Perfil**: foto (bucket privado, URL firmada), «Cliente desde {mes año}», datos, edición.
- Todo lo no funcional **lo dice**: es la regla de la maqueta honesta.

## 3. Fase C-d — recuperación de clave del pasajero (commits `09bfc1c` + `e0a6653`)

**Backend**: los tres pasos (`/client-auth/password-reset/request|verify|confirm`) corren por
la **misma** `PasswordResetService` del chofer, generalizada — no copiada. Lo distinto es
deliberado: la identidad es el **correo solo** (el pasajero no tiene cédula), la búsqueda está
**acotada a `clients`** (un chofer sin lado cliente responde 404: esta puerta no confirma
correos de la lista de afiliados), y el correo de aviso redacta el «entrar» por canal.
3 pruebas nuevas (`tests/client-password-reset.test.ts`) + verificación en producción.
Detalle completo en el decisions-log del backend (entrada 2026-08-31) y en
`docs/api/endpoints.md`, donde además **se añadió la sección completa de `/client-auth`**
que faltaba desde la C-a.

**App**: `PasswordResetRepository` se generalizó con `ResetIdentity` (correo + cédula opcional
— obligatoria en el canal chofer, inexistente en el del cliente); las pantallas 2 y 3 del flujo
**se comparten** entre canales, cada canal aporta su pantalla de identidad, su repositorio y
sus textos. Suite de la app: 88/88.

⚠️ Un afiliado-que-es-cliente comparte **LA clave** (una fila en `users`): recuperarla por
cualquier canal la cambia para ambos lados.

## 4. Ajustes tras la prueba en el teléfono (APK 26, sin commitear)

Decisión de Luis: **editar el perfil y cambiar la clave son mandados distintos**.
- «Editar» → solo datos (nombres, teléfono, correo, dirección).
- «Cambiar mi clave» → pantalla propia (`client_change_password_screen.dart`) con clave
  actual + nueva + repetir, y confirmación al volver.

## 5. El rediseño del inicio (APKs 27→30, sin commitear)

La historia completa, porque explica el resultado:

1. **Estudio de 3 direcciones** (Mapa / Cálida / Enfocada) en un canvas de diseño.
2. Luis eligió **A + la tarjeta dorada de B** compacta → APK 27. También pidió logo+avatar en
   el header de «Editar mis datos» (hecho, y «Cambiar mi clave» recibió el logo).
3. Segunda ronda: **el mapa manda**. Se revisó el sector (Uber pone el destino arriba;
   inDrive/Yango/Bolt/Ridery/Yummy abajo). Luis eligió la **Propuesta 1 (buscador arriba,
   patrón Uber)** → APK 28:
   - «Aún no tienes viajes» se mudó a la pestaña **Viajes** (ya tenía su pantalla).
   - «Choferes verificados» vive en un **escudo flotante** que abre la hoja «Viaja con
     confianza» (funcional de verdad, con «Entendido»).
   - Una sola píldora honesta sobre el mapa: «Vista previa · el mapa real llega con los viajes».
4. Header v2 (nombre+avatar arriba a la derecha, campana abajo) → APK 29. **A Luis le pareció
   horrible.** Decisión final: **el header del inicio es el MISMO del perfil** (logo izquierda,
   campana donde el perfil pone «Editar», avatar grande + nombre completo debajo) → **APK 30**.

**El registro del diseño aprobado** (maqueta final + hoja de confianza) vive en el canvas
«Inicio del pasajero»: https://claude.ai/code/artifact/3ad133c5-009c-4de7-aaba-3bb169d869ce
(el canvas de las 4 pantallas originales de la C-b es otro:
https://claude.ai/code/artifact/557fdad7-571d-4970-a5c4-12096dc6bf1e).

**Piezas técnicas nuevas**: el mapa y el carrito son **CustomPainters**
(`client/home/presentation/widgets/home_illustrations.dart`) — escalan a cualquier teléfono y
no pesan nada; cuando exista el módulo de Viajes, ese espacio pasa a ser el mapa real sin
rediseñar. `initialsOf()` quedó en `core/utils/initials.dart` (lo usaban ya tres pantallas).

### ⚠️ El gotcha que costó una vuelta: «instalé la nueva y la veo igual»

El APK se genera **siempre con el mismo nombre en la misma ruta**
(`build/app/outputs/flutter-apk/app-release.apk`). Si se reutiliza la copia que ya estaba en
el teléfono (WhatsApp/Drive/cable), se reinstala la vieja. **Verificación obligada**: Perfil →
pie de pantalla → debe decir el build esperado (hoy: `1.0.0 (30)`; confirmado con
`aapt dump badging` que el archivo en disco es versionCode 30). Cada build de esta sesión
subió el número justamente para esto.

## 6. Pendiente

1. **Luis confirma el APK 30 en el teléfono** (el 29 le disgustó el header; el 30 lo corrige).
2. **Commitear y empujar la app** (`!SAVE`/`!PUSH`): APKs 26–30 son trabajo local.
3. **Panel de clientes** (ver/buscar/suspender): hoy un cliente problemático solo se para a
   mano en la BD.
4. **Módulo de Viajes** — sigue bloqueado por producto. El diseño del inicio ya le dejó el
   sitio (el mapa) y el patrón.
5. Los pendientes heredados: tres archivos de +1000 líneas, pruebas del panel, Supabase de
   producción separado.

## 7. Preguntas abiertas

1. La tarjeta dorada quedó sin saludo (el nombre subió al header). ¿Lo quiere Luis también en
   la tarjeta? Se le avisó; no respondió.
2. La opción C (Enfocada) usaba wordmark de texto en vez del logo — ya no aplica, descartada.

## 8. Datos de prueba vivos

- **Cliente real**: Luis se registró como pasajero con su Gmail
  (`luis.david.villegas.vargas@gmail.com`) y teléfono `+584122651144`, con foto de perfil
  puesta. Sirve para probar login por correo Y por teléfono, y la recuperación. (No se
  verificó si quedó como cliente puro o adjunto a un `users` ya existente.)
- **Chofer**: `V-22198958`, `overdue`, activo (su clave no es `123456`).
- **Admin del panel**: `admin` / `EdvRoute2026`.
- ⚠️ El conector de Supabase de la sesión apunta a otro proyecto; la BD se consulta con
  `DATABASE_URL` del `.env` del backend.

## 9. Línea de contexto para retomar

> Retomamos EDV Route (C:\Project\edv). Lee `edv-route-mobile/docs/HANDOFF-2026-08-31-app-cliente.md`.
> **La app del pasajero está COMPLETA** (C-b a C-d): entrar con correo o teléfono (normalizado
> a E.164), registro sin cédula, perfil con foto, cambiar clave en pantalla propia y
> recuperación por correo (misma maquinaria del chofer, identidad = correo solo, acotada a
> `clients`). Backend `09bfc1c` en `dev` DESPLEGADO y verificado; app `e0a6653` en `main` —
> **⚠️ todo lo posterior (APKs 26–30: separación editar/clave, headers, y el rediseño del
> inicio con mapa ilustrado + tarjeta dorada arriba + escudo de confianza) está SIN
> commitear**. APK vigente 1.0.0 (30), pendiente de visto bueno de Luis (ojo: verificar el
> build en el pie del Perfil — reinstalar una copia vieja del APK es el gotcha de la sesión).
> El diseño aprobado vive en el canvas «Inicio del pasajero». Siguen pendientes el panel de
> clientes y el módulo de Viajes.
