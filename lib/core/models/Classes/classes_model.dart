/// Simple model representing a Class with only `id` and `name`.
/// Kept minimal intentionally to match the requested shape.
class Model {
  final String? id;
  final String? name;

  const Model({this.id, this.name});

  factory Model.fromJson(Map<String, dynamic> json) {
    return Model(
      id: json['id'] as String?,
      name: json['name'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
    };
  }

  @override
  String toString() => 'Model(id: $id, name: $name)';

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Model && other.id == id && other.name == name;
  }

  @override
  int get hashCode => Object.hash(id, name);
}
