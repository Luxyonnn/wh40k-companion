import 'wability.dart';

class Weapon {
  final String id;
  final String name;
  final String range;
  final String attacks;
  final String bsWs;
  final int strength;
  final int ap;
  final String damage;
  final List<Wability> wability; // Les aptitudes de l'arme (ex: Blast, Heavy)

  Weapon({
    required this.id,
    required this.name,
    required this.range,
    required this.attacks,
    required this.bsWs,
    required this.strength,
    required this.ap,
    required this.damage,
    required this.wability,
  });

  factory Weapon.fromJson(Map<String, dynamic> json, Map<String, Wability> abilityMap) {
    // On récupère les aptitudes de l'arme via leurs IDs
    var abilityIds = List<String>.from(json['abilities'] ?? []);
    var abilitiesList = <Wability>[];
    
    for (var id in abilityIds) {
      if (abilityMap.containsKey(id)) {
        abilitiesList.add(abilityMap[id]!);
      }
    }

    return Weapon(
      id: json['id'],
      name: json['name'],
      range: json['range'],
      attacks: "${json['attacks']}", // Force en String au cas où ce serait un int
      bsWs: json['bs_ws'] ?? "+",
      strength: json['strength'] is int ? json['strength'] : int.tryParse("${json['strength']}") ?? 0,
      ap: json['ap'] is int ? json['ap'] : int.tryParse("${json['ap']}") ?? 0,
      damage: "${json['damage']}",
      wability: abilitiesList,
    );
  }
}