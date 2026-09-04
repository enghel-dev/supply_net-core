# Servicio: redis (cache de lecturas)

Redis se agrega para acelerar las lecturas más frecuentes de la app y
reducir carga sobre Postgres.  Casos de uso sugeridos para el backend:

- **Catálogo de productos / categorías**: cachear listados (`GET /productos`, `GET /categorias`) con TTL corto (30–120s), invalidar la key al crear/editar un producto.
- **Búsqueda de proveedores cercanos**: cachear resultados por combinación de `lat,lng,radio` con TTL corto (la geolocalización cambia poco en minutos).
- **Sesiones / tokens**: con JWT esto no aplica, pero si se necesita invalidar sesiones o guardar refresh tokens, Redis es buen lugar.

