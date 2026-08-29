/// Debe coincidir 1:1 con el enum `unidad_medida_producto` de
/// `services/db/schema/01-schema.sql`.
const unidadesMedida = ['kg', 'lb', 'unidad', 'saco', 'litro', 'quintal', 'caja'];

class Producto {
  Producto({
    required this.id,
    required this.proveedorId,
    required this.categoriaId,
    required this.nombre,
    this.descripcion,
    required this.precio,
    required this.unidadMedida,
    required this.stockDisponible,
    this.imagenUrl,
    required this.activo,
  });

  final String id;
  final String proveedorId;
  final int categoriaId;
  final String nombre;
  final String? descripcion;
  final double precio;
  final String unidadMedida;
  final double stockDisponible;
  final String? imagenUrl;
  final bool activo;

  factory Producto.fromJson(Map<String, dynamic> json) => Producto(
        id: json['id'] as String,
        proveedorId: json['proveedor_id'] as String,
        categoriaId: json['categoria_id'] as int,
        nombre: json['nombre'] as String,
        descripcion: json['descripcion'] as String?,
        precio: (json['precio'] as num).toDouble(),
        unidadMedida: json['unidad_medida'] as String,
        stockDisponible: (json['stock_disponible'] as num).toDouble(),
        imagenUrl: json['imagen_url'] as String?,
        activo: json['activo'] as bool,
      );

  Map<String, dynamic> toCreateJson() => {
        'categoria_id': categoriaId,
        'nombre': nombre,
        'descripcion': descripcion,
        'precio': precio,
        'unidad_medida': unidadMedida,
        'stock_disponible': stockDisponible,
        'imagen_url': imagenUrl,
      };
}
