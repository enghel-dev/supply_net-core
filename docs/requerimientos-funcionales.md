# Requerimientos Funcionales — SupplyNet

> Copia de `DOCUMENTOS/Requerimientos.txt` (carpeta raíz del hackatón), guardada
> aquí también para que el equipo de desarrollo la tenga a la mano junto al
> código. Si se actualiza el original, actualizar también esta copia.

**Equipo:** ByteFlow · **Categoría:** Aficionado · **Institución:** UDM, Managua
**Temática:** Emprendimiento · **Reto:** Plataforma de proveedores y productos finales

---

## 1. Objetivo del proyecto

SupplyNet es una plataforma que conecta **proveedores de insumos/materia prima** con
**compradores** (emprendedores, pequeños negocios, empresas) que necesitan abastecerse.
Resuelve tres problemas concretos:

1. Los compradores no saben qué proveedores existen cerca de ellos.
2. Pedir cotizaciones a varios proveedores a la vez es lento y manual (llamadas, WhatsApp, etc.).
3. No hay forma de saber si un proveedor es confiable antes de comprarle.

SupplyNet lo resuelve con: **búsqueda geolocalizada de proveedores**, **cotización múltiple (RFQ)**
y un **sello de verificación**.

## 2. Alcance para el hackatón

Dado el tiempo disponible, el MVP se enfoca en el flujo completo **comprador pide cotización →
proveedores ofertan → comprador elige** con verificación básica. Fuera de alcance para esta
versión: pagos en línea, logística/envíos, chat en tiempo real (se reemplaza con mensaje simple
dentro de la oferta), app móvil nativa.

## 3. Actores del sistema

| Actor | Descripción |
|---|---|
| **Comprador** | Usuario que busca proveedores y publica solicitudes de cotización (RFQ). |
| **Proveedor** | Usuario con perfil de empresa, publica catálogo y responde a RFQs con ofertas. |
| **Admin** | Revisa y aprueba/rechaza las verificaciones de los proveedores. |

## 4. Requerimientos funcionales

### RF-01 · Registro y autenticación
- El sistema debe permitir registrarse como **comprador** o **proveedor** con nombre, email y contraseña.
- El sistema debe permitir iniciar sesión y mantener la sesión activa.
- El sistema debe restringir las acciones disponibles según el rol del usuario (comprador / proveedor / admin).

### RF-02 · Perfil de proveedor
- Un usuario con rol proveedor debe poder crear su perfil de empresa: nombre, descripción, dirección, teléfono de contacto y ubicación (latitud/longitud).
- El perfil debe mostrar si el proveedor está **verificado** o no.

### RF-03 · Catálogo de productos
- El proveedor debe poder crear, editar, activar/desactivar y eliminar productos de su catálogo.
- Cada producto debe tener: nombre, categoría, descripción, precio, unidad de medida y stock disponible.
- El precio y el stock no pueden ser negativos (regla de negocio del modelo de datos).
- Los productos deben poder filtrarse por categoría.

### RF-04 · Búsqueda geolocalizada de proveedores
- El comprador debe poder buscar proveedores dentro de un radio de distancia desde su ubicación.
- Los resultados deben mostrarse ordenados por cercanía (distancia en km).
- El comprador debe poder ver el catálogo de un proveedor desde su perfil.

### RF-05 · Solicitud de cotización múltiple (RFQ)
- El comprador debe poder publicar una solicitud de cotización indicando: categoría, descripción, cantidad y fecha límite.
- Una solicitud debe tener un estado: **abierta**, **cerrada** o **cancelada**.
- Varios proveedores deben poder ver y responder a la misma solicitud (de ahí "cotización múltiple").

### RF-06 · Ofertas de proveedores
- Un proveedor debe poder responder a una solicitud abierta con: precio ofertado, tiempo de entrega y mensaje opcional.
- Un proveedor **solo puede ofertar una vez** por cada solicitud (regla de negocio).
- El comprador debe poder ver todas las ofertas recibidas para una solicitud, comparar precios y tiempos de entrega, y **aceptar o rechazar** una oferta.

### RF-07 · Verificación / sello de confianza
- Un proveedor debe poder subir un documento de verificación (cédula RUC, registro sanitario, licencia de operación, u otro).
- El admin debe poder revisar la solicitud y marcarla como **aprobada** o **rechazada**.
- Cuando se aprueba, el perfil del proveedor debe mostrar el **sello de verificado** automáticamente (ya implementado vía trigger en la base de datos).

### RF-08 · Panel del proveedor
- El proveedor debe poder ver en un solo lugar: sus productos, las solicitudes de cotización abiertas relevantes a su categoría, y el estado de sus ofertas enviadas (pendiente/aceptada/rechazada).

### RF-09 · Panel del comprador
- El comprador debe poder ver en un solo lugar: sus solicitudes de cotización publicadas y, por cada una, las ofertas recibidas para compararlas.

## 5. Reglas de negocio (ya reflejadas en la base de datos)

- Un email de usuario no se puede repetir.
- Un producto pertenece a un solo proveedor y una sola categoría.
- Un proveedor no puede enviar dos ofertas a la misma solicitud.
- El precio, el precio ofertado, el stock y la cantidad solicitada deben ser mayores o iguales a cero (según el caso).
- Las coordenadas de un proveedor deben ser geográficamente válidas (latitud entre -90 y 90, longitud entre -180 y 180).
- El sello de verificación de un proveedor se actualiza solo cuando el admin aprueba o rechaza una verificación — no se edita manualmente.

## 6. Priorización (MoSCoW) para el tiempo del hackatón

| Prioridad | Requerimientos |
|---|---|
| **Must have** (sin esto no hay demo) | RF-01, RF-02, RF-03, RF-05, RF-06 |
| **Should have** | RF-04 (geolocalización), RF-08, RF-09 |
| **Could have** | RF-07 (verificación) — si el tiempo aprieta, se puede mostrar como "próximamente" en la demo |
| **Won't have (esta versión)** | Pagos en línea, chat en tiempo real, notificaciones push |

## 7. Requerimientos no funcionales (básicos)

- La aplicación debe ser usable desde el navegador (responsive, mobile-first para la demo).
- Las contraseñas deben guardarse cifradas (hash), nunca en texto plano.
- Las búsquedas por cercanía deben responder en menos de 2 segundos con datos de prueba.
