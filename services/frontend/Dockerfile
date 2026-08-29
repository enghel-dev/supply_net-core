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
RUN flutter build web --release --dart-define=API_BASE_URL=${API_BASE_URL}

# ---------- Serve ----------
FROM nginx:1.27-alpine

COPY --from=build /app/build/web /usr/share/nginx/html
COPY nginx.conf /etc/nginx/conf.d/default.conf

EXPOSE 80
