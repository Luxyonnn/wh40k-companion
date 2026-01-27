class PrimarchAbility {
  final String id;
  final String name; // Le titre général (ex: Author of the Codex)
  final List<PrimarchOption> options; // Les 3 choix

  PrimarchAbility({
    required this.id,
    required this.name,
    required this.options,
  });

  factory PrimarchAbility.fromJson(Map<String, dynamic> json) {
    var list = json['options'] as List;
    List<PrimarchOption> optionsList = list.map((i) => PrimarchOption.fromJson(i)).toList();

    return PrimarchAbility(
      id: json['id'],
      name: json['name'],
      options: optionsList,
    );
  }
}

class PrimarchOption {
  final String name;
  final String effect;

  PrimarchOption({required this.name, required this.effect});

  factory PrimarchOption.fromJson(Map<String, dynamic> json) {
    return PrimarchOption(
      name: json['name'],
      effect: json['effect'],
    );
  }
}