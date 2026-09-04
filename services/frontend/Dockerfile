# ---------- Build ----------
FROM ghcr.io/cirruslabs/flutter:stable AS build

WORKDIR /app

COPY pubspec.yaml pubspec.lock ./
RUN flutter pub get

COPY . .

# El repo no trae el andamiaje nativo de "web/" (se genera con el toolchain
# real de Flutter, ver README) — lo generamos acá para que el build funcione
# aunque no exista todavía en el árbol copiado.
RUN flutter create --platforms=web --org com.byteflow .

ARG API_BASE_URL=http://localhost:3000
# --pwa-strategy=none: sin service worker. Con él, el navegador puede
# quedar sirviendo un bundle viejo cacheado tras un rebuild/redeploy (la
# app se queda "pegada" hasta que el SW decide actualizar) — para un
# proyecto que se reconstruye seguido no vale la pena el offline-first.
RUN flutter build web --release --pwa-strategy=none --dart-define=API_BASE_URL=${API_BASE_URL}

# ---------- Serve ----------
FROM nginx:1.27-alpine

COPY --from=build /app/build/web /usr/share/nginx/html
COPY nginx.conf /etc/nginx/conf.d/default.conf

EXPOSE 80
