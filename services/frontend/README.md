# Servicio: frontend

Cliente de SupplyNet, construido en **Flutter** — un solo código para Windows y Android
(y, de paso, web para la demo).
## Configuración

La URL del backend se pasa en tiempo de build/run con `--dart-define` (ver `lib/core/api/api_client.dart`):

- Windows / web: `API_BASE_URL=http://localhost:${BACKEND_PORT:-3000}` (por defecto si no se pasa nada)
- Emulador Android: `API_BASE_URL=http://10.0.2.2:${BACKEND_PORT:-3000}` (así ve el emulador el "localhost" del host)

## Primera vez (generar el andamiaje nativo)

Este repo trae `pubspec.yaml` y todo `lib/` a mano, pero **no** las carpetas nativas
(`android/`, `windows/`, `web/`) — esas las genera el toolchain real de Flutter:

```bash
cd services/frontend
flutter create --platforms=android,windows,web --org com.byteflow .
flutter pub get
```

Esto agrega el andamiaje nativo sin tocar `lib/`/`pubspec.yaml` que ya existen.

## Correr en desarrollo

```bash
flutter run -d windows --dart-define=API_BASE_URL=http://localhost:3000
flutter run -d chrome  --dart-define=API_BASE_URL=http://localhost:3000
flutter run -d <emulador-android> --dart-define=API_BASE_URL=http://10.0.2.2:3000
```

## Builds

```bash
flutter build windows --dart-define=API_BASE_URL=http://localhost:3000   # .exe en build/windows/
flutter build apk --dart-define=API_BASE_URL=<url del backend en prod>   # .apk en build/app/outputs/
flutter build web --dart-define=API_BASE_URL=<url del backend en prod>   # para servir con Docker/nginx
```

El `.exe` de Windows y el `.apk` de Android se distribuyen como build nativo aparte — no se
sirven por contenedor. El build web sí, vía el servicio `frontend` de `docker-compose.yml`.

## Cómo levantarlo en el deploy (build web)

El servicio `frontend` de `docker-compose.yml` ya está activo, con su `Dockerfile` multi-stage
(build con la imagen oficial de Flutter, genera el andamiaje de `web/` y sirve `build/web` con
nginx). Para levantar todo el stack de una vez:

```bash
docker compose up -d --build
```

O solo el frontend (si `db`/`redis`/`backend` ya están arriba): `docker compose up -d --build frontend`.

## Identidad visual

Definida en Figma (archivo del equipo) y reflejada en `lib/core/theme/`: índigo `#2B3A67`
(primario), naranja `#F97316` (acento/CTA), verde `#16A34A` (verificado), tipografía Inter.

## Notas para quien lo corra por primera vez

- Sigue el patrón estándar de un proyecto Flutter (Material 3, `provider`, `dio`, `go_router`).
  Si `flutter analyze` marca algo al correrlo por primera vez con el SDK instalado,
  probablemente sea un detalle menor de nombres de API entre versiones de Flutter.
- Tras el `flutter create` inicial, revisa `android/app/src/main/AndroidManifest.xml`: el
  template de Flutter agrega el permiso de `INTERNET` automáticamente para builds debug, pero
  en **release** hay que confirmar que quede `<uses-permission android:name="android.permission.INTERNET" />`
  explícito, o los requests a la API fallan en silencio en el APK firmado.
- El backend ya trae CORS abierto (`allow_origins=["*"]`) para que el build web funcione sin
  configuración extra — ver `services/backend/app/main.py`.
- El selector de ubicación (perfil de proveedor) permite marcar el punto tocando el mapa o con
  el botón de GPS (`geolocator`, con permiso del usuario). En **Android**, tras el `flutter
  create` inicial hay que agregar a `android/app/src/main/AndroidManifest.xml`:
  `<uses-permission android:name="android.permission.ACCESS_FINE_LOCATION" />` (y
  `ACCESS_COARSE_LOCATION` si se quiere permitir precisión aproximada), o el botón de GPS falla
  en silencio. En **web** no hace falta nada — el navegador pide el permiso solo, y funciona
  sobre `http://localhost` sin necesitar HTTPS.
