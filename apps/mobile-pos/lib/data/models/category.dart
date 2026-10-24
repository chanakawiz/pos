class CategoryModel {
  final int? id;
  final String uuid;
  final String name;
  final String slug;
  final int displayOrder;
  final bool isActive;
  final int version;

  const CategoryModel({
    this.id,
    required this.uuid,
    required this.name,
    required this.slug,
    this.displayOrder = 0,
    this.isActive = true,
    this.version = 1,
  });

  factory CategoryModel.fromJson(Map<String, dynamic> json) {
    return CategoryModel(
      id: json['id'] is int ? json['id'] : null,
      uuid: json['uuid']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
      slug: json['slug']?.toString() ?? '',
      displayOrder: (json['display_order'] is int) ? json['display_order'] : 0,
      isActive: json['is_active'] == null || json['is_active'] == true || json['is_active'] == 1,
      version: (json['version'] is int) ? json['version'] : 1,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'uuid': uuid,
      'name': name,
      'slug': slug,
      'display_order': displayOrder,
      'is_active': isActive ? 1 : 0,
      'version': version,
    };
  }

  factory CategoryModel.fromDbMap(Map<String, dynamic> map) {
    return CategoryModel(
      id: map['id'] as int?,
      uuid: map['uuid'] as String,
      name: map['name'] as String,
      slug: map['slug'] as String,
      displayOrder: (map['display_order'] as int?) ?? 0,
      isActive: (map['is_active'] != 0),
      version: (map['version'] as int?) ?? 1,
    );
  }

  Map<String, dynamic> toDbMap() {
    return {
      'uuid': uuid,
      'name': name,
      'slug': slug,
      'display_order': displayOrder,
      'is_active': isActive ? 1 : 0,
      'version': version,
    };
  }
}
