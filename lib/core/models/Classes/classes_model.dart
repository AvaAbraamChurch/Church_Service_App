/// Simple model representing a Class with only `id` and `name`.
/// Kept minimal intentionally to match the requested shape.
class Model {
  final String? id;
  final String? name;
  final String? description;

  const Model({this.id, this.name, this.description});

  factory Model.fromJson(Map<String, dynamic> json) {
    return Model(
      id: json['id'] as String?,
      name: json['name'] as String?,
      description: json['description'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'description': description,
    };
  }


  @override
  String toString() => 'Model(id: $id, name: $name, description: $description)';

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Model && other.id == id && other.name == name && other.description == description;
  }

  @override
  int get hashCode => Object.hash(id, name, description);

  Model copyWith({
    String? id,
    String? name,
    String? description,
  }) {
    return Model(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
    );
  }
}
