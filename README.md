# EDV Route — App móvil

App Flutter con **dos modos**: el del afiliado (chofer) y el del cliente
(pasajero), separados por carpeta dentro de `features/`. Habla **solo** con el
backend propio (`edv-route-backend`); nunca toca la base de datos ni el bucket
de archivos.

## Estructura

La regla es una sola: **las dependencias apuntan hacia adentro**. Una sección
puede usar el dominio y lo compartido; el dominio no sabe que existen las
secciones.

```
lib/
  core/         Infraestructura: config, cliente HTTP, almacenamiento del token,
                utilidades puras (fechas) y el contenedor de dependencias.
  domain/       Entidades y contratos de repositorio. Sin Flutter, sin HTTP.
  data/         Implementación: datasources (HTTP), modelos (JSON) y repositorios.
  features/
    auth/       Entrar: selección de perfil, login/registro del chofer, splash.
    enrollment/ La solicitud: checklist, documentos, vehículos, pago del alta,
                membresía.
    profile/    Perfil del afiliado: estado de cuenta, editar datos, foto.
    home/       Lo que envuelve al chofer: shell con la isla inferior, enrutado
                por estado y pantalla de estado.
    client/     El modo pasajero completo, con el mismo corte interno:
      auth/     Entrar (correo o teléfono) y crear cuenta.
      home/     Shell del cliente e inicio de maqueta (marcado como vista previa).
      trips/    Pestaña Viajes: aviso honesto de "aún no", hasta que exista.
      profile/  Perfil del cliente: datos, foto y edición.
  shared/       Lo que usa más de una sección: widgets (avatar de foto, selector
                de imagen, campos de formulario, tarjetas del checklist) y
                acciones (cerrar sesión).
  routing/      Nombres de rutas. Cuando el grafo crezca, aquí entra go_router.
  theme/        Colores y tema de la marca.
```

### Dónde va lo nuevo

- ¿Una pantalla o un widget que **solo** usa una sección? Dentro de esa sección.
- ¿Lo usa una segunda sección? Se mueve a `shared/` **en ese momento**, no después.
- ¿Un dato que viene del backend? Entidad en `domain/entities`, mapeo en
  `data/models`, llamada en `data/datasources`.
- Nada de que una sección importe de otra. La única excepción tolerada hoy es la
  navegación de entrada (`auth` → `home/driver_root_screen`), y desaparece cuando
  la navegación pase por `routing/`.

## Convenciones

- **Textos de la interfaz en español; código y comentarios en inglés.**
- Ningún archivo pasa de **1000 líneas**.
- Sin `intl`: las dos únicas fechas que se muestran salen de
  `core/utils/date_format.dart`.
- Las fotos y documentos llegan como **URL firmadas que caducan** (el bucket es
  privado). Si una falla, la interfaz cae a su alternativa (iniciales, ícono),
  nunca a una imagen rota.

## Comandos

| Comando | Qué hace |
|---|---|
| `flutter run` | Levanta la app en el dispositivo conectado |
| `flutter analyze` | Análisis estático (debe salir limpio) |
| `flutter test` | Suite de pruebas |
| `flutter build apk --release` | APK de entrega |

El backend al que apunta se configura en `lib/core/config/app_config.dart`.

## Historial

Las notas de cada sesión están en [`docs/`](docs/) (`HANDOFF-*.md`). Las
decisiones de negocio y de arquitectura del sistema completo viven en
`edv-route-backend/docs/decisions/decisions-log.md`.
