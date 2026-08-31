class Categoria {
  Categoria({required this.id, required this.nombre, this.descripcion, this.parentId});

  final int id;
  final String nombre;
  final String? descripcion;
  final int? parentId;

  factory Categoria.fromJson(Map<String, dynamic> json) => Categoria(
        id: json['id'] as int,
        nombre: json['nombre'] as String,
        descripcion: json['descripcion'] as String?,
        parentId: json['parent_id'] as int?,
      );
}
