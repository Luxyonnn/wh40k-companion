import 'package:flutter/foundation.dart'; // Pour le debugPrint
import 'wability.dart';
import 'weapon.dart';
import 'primarch_ability.dart'; 

class Unit {
  final String id;
  final String name;
  final String faction;
  final int points;
  final int move;
  final int toughness;
  final int save;
  final int wounds;
  final int leadership;
  final int oc;
  final int inv;
  final String description;
  final List<String> keywords;
  final List<String> factionKeywords;
  final String unitComposition;
  final String wargearOptions;
  final String leaderInfo;
  final List<Weapon> weapons;
  final List<Wability> abilities; 
  final List<Wability> wargearAbilities; 
  final List<PrimarchAbility> primarchAbilities; 

  Unit({
    required this.id,
    required this.name,
    required this.faction,
    required this.points,
    required this.move,
    required this.toughness,
    required this.save,
    required this.wounds,
    required this.leadership,
    required this.oc,
    required this.inv,
    required this.description,
    required this.unitComposition, 
    required this.wargearOptions,  
    required this.leaderInfo,      
    required this.keywords,
    required this.factionKeywords,
    required this.weapons,
    required this.abilities,
    required this.wargearAbilities,
    required this.primarchAbilities,
  });

  factory Unit.fromJson(
    Map<String, dynamic> json, 
    Map<String, Weapon> weaponMap, 
    Map<String, Wability> abilityMap,
    Map<String, PrimarchAbility> primarchMap 
  ) {
    
    // --- 1. FONCTION INTELLIGENTE POUR TROUVER LES VALEURS ---
    // Elle cherche la clé, sa version minuscule, et ses abréviations WH40k
    dynamic searchKey(List<String> candidates) {
      for (var key in candidates) {
        if (json.containsKey(key)) return json[key];
        if (json.containsKey(key.toLowerCase())) return json[key.toLowerCase()];
        if (json.containsKey(key.toUpperCase())) return json[key.toUpperCase()];
      }
      return null;
    }

    // --- 2. FONCTION POUR NETTOYER LES NOMBRES ---
    int cleanInt(dynamic value) {
      if (value == null) return 0;
      if (value is int) return value;
      if (value is String) {
        // Enlève tout ce qui n'est pas un chiffre (ex: "3+" devient 3)
        String numbers = value.replaceAll(RegExp(r'[^0-9]'), '');
        return int.tryParse(numbers) ?? 0;
      }
      return 0;
    }

    // --- 3. DEBUG : VÉRIFICATION DES ARMES ---
    var weaponIds = searchKey(['weapons', 'rangedWeapons', 'meleeWeapons']); 
    var weaponsList = <Weapon>[];
    
    if (weaponIds != null && weaponIds is List) {
      for (var id in weaponIds) {
        if (id is String) {
          // On vérifie si l'arme existe dans la map
          if (weaponMap.containsKey(id)) {
            weaponsList.add(weaponMap[id]!);
          } else {
            // SI L'ARME N'APPARAIT PAS, CE MESSAGE S'AFFICHERA DANS LA CONSOLE
            debugPrint("⚠️ ARME MANQUANTE: L'unité '${json['name']}' demande l'arme '$id', mais elle n'est pas dans weapons.json");
          }
        }
      }
    }

    // --- 4. RÉCUPÉRATION DES APTITUDES ---
    var abilitiesList = <Wability>[];
    var primarchList = <PrimarchAbility>[];
    var rawAbilities = searchKey(['abilities', 'Abilities']);

    if (rawAbilities != null && rawAbilities is List) {
      for (var abId in rawAbilities) {
        if (abId is String) {
          if (abilityMap.containsKey(abId)) {
            abilitiesList.add(abilityMap[abId]!);
          } else if (primarchMap.containsKey(abId)) {
            primarchList.add(primarchMap[abId]!);
          } else {
             // DEBUG APTITUDE
             // debugPrint("⚠️ APTITUDE MANQUANTE: '$abId' introuvable.");
          }
        }
      }
    }

    var wargearList = <Wability>[];
    var rawWargear = searchKey(['wargearAbilities', 'wargear', 'Wargear']);
    if (rawWargear != null && rawWargear is List) {
        for (var abId in rawWargear) {
            if (abId is String && abilityMap.containsKey(abId)) {
              wargearList.add(abilityMap[abId]!);
            }
        }
    }

    return Unit(
      id: searchKey(['id', 'ID']) ?? 'unknown',
      name: searchKey(['name', 'Name']) ?? 'Nom Inconnu',
      faction: searchKey(['faction', 'FactionKeyword']) ?? 'Inconnue',
      
      // ON CHERCHE TOUTES LES VARIANTES POSSIBLES POUR LES STATS
      points: cleanInt(searchKey(['points', 'pts', 'Cost'])),
      
      // Mouvement : Move, M
      move: cleanInt(searchKey(['move', 'Move', 'M'])),
      
      // Endurance : Toughness, T
      toughness: cleanInt(searchKey(['toughness', 'Toughness', 'T'])),
      
      // Sauvegarde : Save, Sv, SV
      save: cleanInt(searchKey(['save', 'Save', 'Sv', 'SV'])),
      
      // Points de vie : Wounds, W
      wounds: cleanInt(searchKey(['wounds', 'Wounds', 'W'])),
      
      // Commandement : Leadership, Ld, LD
      leadership: cleanInt(searchKey(['leadership', 'Leadership', 'Ld', 'LD'])),
      
      // Contrôle d'objectif : OC
      oc: cleanInt(searchKey(['oc', 'OC'])),
      
      // Sauvegarde Invulnérable : inv, Inv, Invul
      inv: cleanInt(searchKey(['inv', 'Inv', 'Invul'])),

      description: searchKey(['description', 'Description', 'lore', 'desc']) ?? '',

      unitComposition: searchKey(['unitComposition', 'composition']) ?? '',
      
      wargearOptions: searchKey(['wargearOptions', 'options']) ?? '',
      
      leaderInfo: searchKey(['leaderInfo', 'leader', 'attached']) ?? '',

      keywords: searchKey(['keywords', 'Keywords']) != null ? List<String>.from(searchKey(['keywords', 'Keywords'])) : [],
      factionKeywords: searchKey(['factionKeywords', 'FactionKeywords']) != null ? List<String>.from(searchKey(['factionKeywords', 'FactionKeywords'])) : [],
      
      weapons: weaponsList,
      abilities: abilitiesList,
      wargearAbilities: wargearList,
      primarchAbilities: primarchList,
    );
  }

  String get factionLogoPath => 'assets/logos/${faction.toLowerCase().replaceAll(' ', '_')}.png';
}