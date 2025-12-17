import 'package:hive/hive.dart';

part 'template_checklist.g.dart';

@HiveType(typeId: 12)
class TemplateChecklist extends HiveObject {
  @HiveField(0)
  String id;

  @HiveField(1)
  String nom;

  @HiveField(2)
  String typePanne; // Electrique, Mecanique, Froid

  @HiveField(3)
  List<TemplateItem> items;

  TemplateChecklist({
    required this.id,
    required this.nom,
    required this.typePanne,
    required this.items,
  });

  factory TemplateChecklist.fromJson(Map<String, dynamic> json) {
    return TemplateChecklist(
      id: json['id'] ?? '',
      nom: json['nom'] ?? '',
      typePanne: json['type_panne'] ?? 'Electrique',
      items: (json['items'] as List? ?? [])
          .map((item) => TemplateItem.fromJson(item))
          .toList(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'nom': nom,
      'type_panne': typePanne,
      'items': items.map((item) => item.toJson()).toList(),
    };
  }
}

@HiveType(typeId: 13)
class TemplateItem extends HiveObject {
  @HiveField(0)
  String id;

  @HiveField(1)
  String description;

  @HiveField(2)
  bool obligatoire;

  @HiveField(3)
  int ordre;

  TemplateItem({
    required this.id,
    required this.description,
    this.obligatoire = true,
    required this.ordre,
  });

  factory TemplateItem.fromJson(Map<String, dynamic> json) {
    return TemplateItem(
      id: json['id'] ?? '',
      description: json['description'] ?? '',
      obligatoire: json['obligatoire'] ?? true,
      ordre: json['ordre'] ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'description': description,
      'obligatoire': obligatoire,
      'ordre': ordre,
    };
  }
}