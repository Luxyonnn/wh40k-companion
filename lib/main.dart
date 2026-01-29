import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';

// Imports des modèles (Assurez-vous qu'ils sont tous dans lib/models/)
import 'models/unit.dart';
import 'models/faction.dart';
import 'models/wability.dart';
import 'models/weapon.dart';
import 'models/primarch_ability.dart'; 
import 'models/compare.dart';

void main() {
  runApp(const WarhammerApp());
}

class WarhammerApp extends StatelessWidget {
  const WarhammerApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'WH40k Companion',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        brightness: Brightness.dark,
        primaryColor: const Color(0xFF8B0000),
        scaffoldBackgroundColor: const Color(0xFF121212),
        cardColor: const Color(0xFF1E1E1E),
        appBarTheme: const AppBarTheme(
          backgroundColor: Colors.transparent,
          elevation: 0,
        ),
      ),
      home: const UnitListScreen(),
    );
  }
}

// =============================================================================
// ÉCRAN 1 : LA BIBLIOTHÈQUE (GRILLE AMÉLIORÉE)
// =============================================================================

class UnitListScreen extends StatefulWidget {
  const UnitListScreen({super.key});

  @override
  State<UnitListScreen> createState() => _UnitListScreenState();
}

class _UnitListScreenState extends State<UnitListScreen> {
  late Future<List<Unit>> _unitsFuture;
  
  List<Unit> allUnits = [];
  
  // -- ÉTATS DES FILTRES --
  String searchQuery = "";
  String? selectedFaction; // Null = Tous
  String? selectedKeyword; // Null = Tous
  bool showFilters = false;

  // -- MODE COMPARATEUR --
  bool isCompareMode = false;
  List<Unit> compareSelection = [];

  // -- ÉTATS DES FAVORIS --
  List<String> favoriteIds = []; // Liste des IDs favoris
  bool showFavoritesOnly = false; // Filtre "Voir favoris" actif ?
  
  Map<String, FactionData> factionMap = {}; 

  // Liste des keywords courants pour le filtrage rapide
  final List<String> commonKeywords = [
    "Character", "Battleline", "Infantry", "Vehicle", "Monster", "Epic Hero", "Fly", "Walker"
  ];

  @override
  void initState() {
    super.initState();
    _unitsFuture = loadGameData();
    _loadFavorites(); // <--- On charge les favoris au démarrage
  }

  void _toggleCompareSelection(Unit unit) {
    setState(() {
      if (compareSelection.contains(unit)) {
        compareSelection.remove(unit);
      } else {
        if (compareSelection.length < 2) {
          compareSelection.add(unit);
        } else {
          // Si on en a déjà 2, on remplace le premier (le plus vieux) par le nouveau
          compareSelection.removeAt(0);
          compareSelection.add(unit);
        }
      }
    });
  }

  // 1. Charger depuis la mémoire
    Future<void> _loadFavorites() async {
      final prefs = await SharedPreferences.getInstance();
      setState(() {
        favoriteIds = prefs.getStringList('favorite_units') ?? [];
      });
    }

  // 2. Ajouter / Retirer un favori
  Future<void> _toggleFavorite(String unitId) async {
    final prefs = await SharedPreferences.getInstance();
    
    setState(() {
      if (favoriteIds.contains(unitId)) {
        favoriteIds.remove(unitId);
        debugPrint("💔 Retiré des favoris : $unitId"); // Message Console
      } else {
        favoriteIds.add(unitId);
        debugPrint("❤️ Ajouté aux favoris : $unitId"); // Message Console
      }
    });
    
    // Sauvegarde
    await prefs.setStringList('favorite_units', favoriteIds);
    debugPrint("💾 Liste sauvegardée : $favoriteIds");
  }
  // ---------------------------

  // LOGIQUE DE FILTRAGE COMBINÉE
  List<Unit> getFilteredUnits() {
    return allUnits.where((unit) {
      // 1. Filtre Recherche Texte
      final matchesSearch = unit.name.toLowerCase().contains(searchQuery.toLowerCase()) || 
                            unit.faction.toLowerCase().contains(searchQuery.toLowerCase());
      
      // 2. Filtre Faction (Boutons du haut)
      final matchesFaction = selectedFaction == null || unit.faction == selectedFaction;

      // 3. Filtre Keyword (Boutons du bas)
      final matchesKeyword = selectedKeyword == null || unit.keywords.contains(selectedKeyword);

      // 4. FAVORIS (Correction logique)
      // Si "showFavoritesOnly" est FAUX, on prend tout (true).
      // Si "showFavoritesOnly" est VRAI, on vérifie si l'ID est dans la liste.
      final matchesFavorites = !showFavoritesOnly || favoriteIds.contains(unit.id);

      return matchesSearch && matchesFaction && matchesKeyword && matchesFavorites;
    }).toList();
  }

  // Récupère la liste unique des factions présentes dans les données
  List<String> getUniqueFactions() {
    return allUnits.map((u) => u.faction).toSet().toList()..sort();
  }


  Future<List<Unit>> loadGameData() async {
    // ... (Votre code de chargement existant reste IDENTIQUE ici) ...
    // Je le raccourcis pour la lisibilité de la réponse, mais gardez votre bloc loadGameData complet
    final files = await Future.wait([
      rootBundle.loadString('assets/abilities_core.json'),    
      rootBundle.loadString('assets/abilities_army.json'),    
      rootBundle.loadString('assets/abilities_unit.json'),    
      rootBundle.loadString('assets/abilities_wargear.json'), 
      rootBundle.loadString('assets/wabilities.json'),        
      rootBundle.loadString('assets/weapons.json'),           
      rootBundle.loadString('assets/units.json'),             
      rootBundle.loadString('assets/factions.json'),          
      rootBundle.loadString('assets/abilities_primarch.json'),
    ]);

    final Map<String, Wability> masterAbilityMap = {};
    void addAbilitiesToMap(String jsonString) {
      final List<dynamic> list = jsonDecode(jsonString);
      for (var j in list) {
        var ab = Wability.fromJson(j);
        masterAbilityMap[ab.id] = ab;
      }
    }
    addAbilitiesToMap(files[0]); addAbilitiesToMap(files[1]); addAbilitiesToMap(files[2]); 
    addAbilitiesToMap(files[3]); addAbilitiesToMap(files[4]);

    final factionsJson = jsonDecode(files[7]) as List;
    for (var f in factionsJson) {
      var faction = FactionData.fromJson(f);
      factionMap[faction.id] = faction; 
    }

    final Map<String, PrimarchAbility> primarchMap = {};
    final primarchJson = jsonDecode(files[8]) as List;
    for (var p in primarchJson) {
      var pa = PrimarchAbility.fromJson(p);
      primarchMap[pa.id] = pa;
    }

    final weaponsJson = jsonDecode(files[5]) as List;
    final Map<String, Weapon> weaponMap = {};
    for (var j in weaponsJson) {
      var wp = Weapon.fromJson(j, masterAbilityMap);
      weaponMap[wp.id] = wp;
    }

    final unitsJson = jsonDecode(files[6]) as List;
    return unitsJson.map((j) => Unit.fromJson(j, weaponMap, masterAbilityMap, primarchMap)).toList();
  }

  @override
  Widget build(BuildContext context) {
    // Vérifie si un filtre est actif pour colorer l'icône
    bool isFilterActive = selectedFaction != null || selectedKeyword != null;

    return Scaffold(
      // APPBAR SIMPLIFIÉE
      appBar: AppBar(
        title: const Text("BIBLIOTHÈQUE", style: TextStyle(fontWeight: FontWeight.bold, letterSpacing: 1.5)),
        centerTitle: true,
        actions: [
          // BOUTON BALANCE POUR ACTIVER LE MODE
          IconButton(
            icon: Icon(Icons.balance, color: isCompareMode ? Colors.amber : Colors.grey),
            tooltip: "Mode Comparaison",
            onPressed: () {
              setState(() {
                isCompareMode = !isCompareMode;
                compareSelection.clear(); // On vide quand on change de mode
              });
            },
          ),
          const SizedBox(width: 10),
        ],
      ),

      // BOUTON FLOTTANT QUI APPARAIT QUAND 2 UNITÉS SONT SÉLECTIONNÉES
      floatingActionButton: (isCompareMode && compareSelection.length == 2) 
        ? FloatingActionButton.extended(
            backgroundColor: Colors.amber,
            onPressed: () {
              // Navigation vers le nouveau fichier compare.dart
              Navigator.push(context, MaterialPageRoute(
                builder: (c) => UnitComparisonScreen(
                  unitA: compareSelection[0], 
                  unitB: compareSelection[1]
                )
              ));
            },
            label: const Text("COMPARER", style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
            icon: const Icon(Icons.compare_arrows, color: Colors.black),
          )
        : null,

      body: FutureBuilder<List<Unit>>(
        future: _unitsFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator(color: Color(0xFF8B0000)));
          } else if (snapshot.hasError) {
             return Center(child: Text("Erreur: ${snapshot.error}", style: const TextStyle(color: Colors.red)));
          } else if (snapshot.hasData) {
            if (allUnits.isEmpty) {
              allUnits = snapshot.data!;
            }
            
            // On calcule la liste filtrée à la volée
            final displayedUnits = getFilteredUnits();
            final availableFactions = getUniqueFactions();

            return Column(
              children: [
                // 1. ZONE DE RECHERCHE + BOUTON FILTRE
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  child: TextField(
                    onChanged: (val) => setState(() => searchQuery = val),
                    decoration: InputDecoration(
                      hintText: "Rechercher...",
                      prefixIcon: const Icon(Icons.search, color: Colors.grey),
                      
                      // LE BOUTON MAGIQUE POUR OUVRIR/FERMER
                      suffixIcon: IconButton(
                        icon: Icon(showFilters ? Icons.filter_list_off : Icons.filter_list),
                        // Si un filtre est actif, l'icône devient ROUGE pour alerter l'utilisateur
                        color: isFilterActive ? const Color(0xFF8B0000) : Colors.grey,
                        onPressed: () {
                          setState(() {
                            showFilters = !showFilters;
                          });
                        },
                      ),
                      
                      filled: true,
                      fillColor: const Color(0xFF1E1E1E),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.grey.shade800)),
                      contentPadding: const EdgeInsets.symmetric(vertical: 0),
                    ),
                  ),
                ),

                // 2. ZONE DE FILTRES (VISIBLE SEULEMENT SI showFilters est TRUE)
                if (showFilters) ...[
                  Container(
                    width: double.infinity,
                    color: const Color(0xFF151515), // Fond légèrement plus sombre pour marquer la zone
                    padding: const EdgeInsets.only(bottom: 10),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        
                        // -- SECTION FAVORIS (NOUVEAU) --
                        const Padding(
                          padding: EdgeInsets.only(left: 16, top: 10, bottom: 5),
                          child: Text("FILTRE RAPIDE", style: TextStyle(color: Colors.grey, fontSize: 10, fontWeight: FontWeight.bold)),
                        ),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 12),
                          child: Row(
                            children: [
                              // LE BOUTON CŒUR
                              _filterChip(
                                "♥  MES FAVORIS", 
                                showFavoritesOnly, 
                                () => setState(() => showFavoritesOnly = !showFavoritesOnly),
                                isFavoriteBtn: true // Style spécial rouge
                              ),
                            ],
                          ),
                        ),
                        
                        // Titre discret
                        const Padding(
                          padding: EdgeInsets.only(left: 16, top: 10, bottom: 5),
                          child: Text("FACTIONS", style: TextStyle(color: Colors.grey, fontSize: 10, fontWeight: FontWeight.bold)),
                        ),
                        // Liste Factions
                        SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          padding: const EdgeInsets.symmetric(horizontal: 12),
                          child: Row(
                            children: [
                              _filterChip("TOUS", selectedFaction == null, () => setState(() => selectedFaction = null)),
                              ...availableFactions.map((f) => _filterChip(
                                f.toUpperCase(), 
                                selectedFaction == f, 
                                () => setState(() => selectedFaction = (selectedFaction == f ? null : f))
                              )),
                            ],
                          ),
                        ),

                        // Titre discret
                        const Padding(
                          padding: EdgeInsets.only(left: 16, top: 10, bottom: 5),
                          child: Text("RÔLES & MOTS-CLÉS", style: TextStyle(color: Colors.grey, fontSize: 10, fontWeight: FontWeight.bold)),
                        ),
                        // Liste Keywords
                        SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          padding: const EdgeInsets.symmetric(horizontal: 12),
                          child: Row(
                            children: commonKeywords.map((k) => _filterChip(
                              k.toUpperCase(), 
                              selectedKeyword == k, 
                              () => setState(() => selectedKeyword = (selectedKeyword == k ? null : k)),
                              isSecondary: true
                            )).toList(),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const Divider(height: 1, color: Colors.white10),
                ],

                // 4. LA GRILLE (EXPANDED POUR PRENDRE LE RESTE DE LA PLACE)
                Expanded(
                  child: displayedUnits.isEmpty 
                  ? const Center(child: Text("Aucune unité trouvée", style: TextStyle(color: Colors.grey)))
                  : GridView.builder(
                      padding: const EdgeInsets.all(12),
                      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 4,
                        crossAxisSpacing: 8,
                        mainAxisSpacing: 8,
                        childAspectRatio: 0.7,
                      ),
                      itemCount: displayedUnits.length,
                      itemBuilder: (context, index) => _unitGridCard(context, displayedUnits[index]),
                    ),
                ),
              ],
            );
          }
          return const Center(child: Text("Aucune donnée"));
        },
      ),
    );
  }

  // WIDGET BOUTON FILTRE (Mis à jour pour le bouton Favori)
  Widget _filterChip(String label, bool isSelected, VoidCallback onTap, {bool isSecondary = false, bool isFavoriteBtn = false}) {
    // Si c'est le bouton favori : Rouge vif si actif, Rouge sombre si inactif
    // Sinon : Rouge ou Gris
    Color activeColor = isSecondary ? Colors.white24 : const Color(0xFF8B0000);
    if (isFavoriteBtn) activeColor = Colors.redAccent;

    final inactiveColor = const Color(0xFF1E1E1E);
    final borderColor = isSelected ? activeColor : Colors.grey.shade800;
    
    return Padding(
      padding: const EdgeInsets.only(right: 8.0),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            color: isSelected ? activeColor : inactiveColor,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: borderColor),
          ),
          child: Text(
            label,
            style: TextStyle(
              color: isSelected ? Colors.white : Colors.grey,
              fontWeight: isSelected || isFavoriteBtn ? FontWeight.bold : FontWeight.normal,
              fontSize: 11,
            ),
          ),
        ),
      ),
    );
  }

  Widget _unitGridCard(BuildContext context, Unit unit) {
    FactionData? style;
    for (var key in factionMap.keys) {
      if (unit.faction.contains(key)) {
        style = factionMap[key];
        break;
      }
    }
    final Color finalColor = style?.color ?? Colors.grey;
    final bool isFav = favoriteIds.contains(unit.id);
    
    // NOUVEAU : Est-ce sélectionné ?
    final bool isSelectedCompare = compareSelection.contains(unit);

    return GestureDetector(
      onTap: () {
        if (isCompareMode) {
          _toggleCompareSelection(unit); // Mode Comparaison
        } else {
          // Mode Normal : On ouvre la fiche
          Navigator.push(context, MaterialPageRoute(builder: (context) => UnitDetailScreen(unit: unit, factionStyle: style)));
        }
      },
      child: Container(
        decoration: BoxDecoration(
          color: const Color(0xFF1E1E1E),
          borderRadius: BorderRadius.circular(12),
          // BORDURE : Jaune épais si sélectionné, sinon couleur de faction
          border: isSelectedCompare 
              ? Border.all(color: Colors.amber, width: 3) 
              : Border.all(color: finalColor.withValues(alpha: 0.5), width: 1.5),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(height: 4, decoration: BoxDecoration(color: finalColor, borderRadius: const BorderRadius.vertical(top: Radius.circular(12)))),
            Expanded(
              child: Stack(
                children: [
                  Positioned.fill(
                    child: ClipRRect(
                      borderRadius: const BorderRadius.vertical(top: Radius.zero),
                      child: Image.asset(
                        'assets/images/${unit.id}.png',
                        fit: BoxFit.cover,
                        filterQuality: FilterQuality.high,
                        alignment: Alignment.topCenter,
                        errorBuilder: (context, error, stackTrace) => const Icon(Icons.photo_library, color: Colors.white10, size: 30),
                      ),
                    ),
                  ),
                  // On cache le cœur en mode comparaison pour ne pas surcharger
                  if (!isCompareMode)
                  Positioned(
                    top: 0, right: 0,
                    child: IconButton(
                      icon: Icon(isFav ? Icons.favorite : Icons.favorite_border, color: isFav ? Colors.redAccent : Colors.white70, shadows: const [Shadow(color: Colors.black, blurRadius: 4)]),
                      onPressed: () => _toggleFavorite(unit.id),
                    ),
                  ),
                  // Indicateur de sélection (Coche Jaune)
                  if (isSelectedCompare)
                  Container(
                    color: Colors.black45,
                    child: const Center(child: Icon(Icons.check_circle, color: Colors.amber, size: 40)),
                  )
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(unit.name.toUpperCase(), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 11), maxLines: 1, overflow: TextOverflow.ellipsis),
                  const SizedBox(height: 4),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(child: Text(unit.faction, style: const TextStyle(color: Colors.grey, fontSize: 9), overflow: TextOverflow.ellipsis)),
                      Text("${unit.points} PTS", style: const TextStyle(color: Color(0xFF8B0000), fontWeight: FontWeight.bold, fontSize: 10)),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}


// =============================================================================
// ÉCRAN 2 : LA FICHE DÉTAILLÉE
// =============================================================================

class UnitDetailScreen extends StatelessWidget {
  final Unit unit;
  final FactionData? factionStyle;

  const UnitDetailScreen({super.key, required this.unit, this.factionStyle});

  @override
  Widget build(BuildContext context) {
    final Color primaryColor = factionStyle?.color ?? const Color(0xFF8B0000);
    final String logoPath = factionStyle?.logoPath ?? unit.factionLogoPath;
    final Color cardBackground = const Color(0xFF1E1E1E);

    final coreAbilities = unit.abilities.where((a) => a.id.startsWith("CORE_")).toList();
    final armyAbilities = unit.abilities.where((a) => a.id.startsWith("ARMY_")).toList();
    final specificUnitAbilities = unit.abilities.where((a) => a.id.startsWith("UNIT_")).toList();
    final rangedWeapons = unit.weapons.where((w) => w.range.toLowerCase() != "-").toList();
    final meleeWeapons = unit.weapons.where((w) => w.range.toLowerCase() == "-").toList();

    return Scaffold(
      appBar: AppBar(
        leadingWidth: 140,
        leading: TextButton.icon(
          onPressed: () => Navigator.pop(context),
          icon: const Icon(Icons.arrow_back_ios, color: Colors.white, size: 20),
          label: const Text("Retour", style: TextStyle(color: Colors.white, fontSize: 16)),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            
            // --- HEADER ---
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Container(
                            width: 50, height: 50,
                            margin: const EdgeInsets.only(right: 12),
                            child: Image.asset(
                              logoPath,
                              color: primaryColor,
                              colorBlendMode: BlendMode.srcIn,
                              filterQuality: FilterQuality.high,
                              errorBuilder: (c, e, s) => Icon(Icons.shield, size: 40, color: Colors.grey.shade800),
                            ),
                          ),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  unit.name.toUpperCase(),
                                  style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, height: 1.0),
                                  maxLines: 2, overflow: TextOverflow.ellipsis,
                                ),
                                const SizedBox(height: 6),
                                Row(
                                  children: [
                                    Text(unit.faction, style: const TextStyle(color: Colors.grey, fontSize: 13)),
                                    const SizedBox(width: 12),
                                    Text("${unit.points} PTS", style: TextStyle(color: primaryColor, fontWeight: FontWeight.bold, fontSize: 14)),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      const Divider(height: 1),
                      const SizedBox(height: 12),
                      Wrap(
                        spacing: 8, runSpacing: 8,
                        children: [
                          _statBox("M", "${unit.move}\"", primaryColor),
                          _statBox("T", "${unit.toughness}", primaryColor),
                          _statBox("SV", "${unit.save}+", primaryColor),
                          if (unit.inv > 0) _statBox("INV", "${unit.inv}+", Colors.blueAccent),
                          _statBox("W", "${unit.wounds}", primaryColor),
                          _statBox("LD", "${unit.leadership}+", primaryColor),
                          _statBox("OC", "${unit.oc}", primaryColor),
                        ],
                      ),
                      // --- DESCRIPTION EN ITALIQUE ---
                      if (unit.description.isNotEmpty) ...[
                        const SizedBox(height: 12),
                        Text(
                          unit.description,
                          style: const TextStyle(
                            fontStyle: FontStyle.italic, // C'est ici qu'on met l'italique
                            color: Colors.white70,       // Un gris clair pour le différencier
                            fontSize: 13,
                            height: 1.4, // Un peu d'espacement entre les lignes pour la lisibilité
                          ),
                          textAlign: TextAlign.justify, // Justifié pour faire propre
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                Container(
                  width: 250, height: 250,
                  clipBehavior: Clip.antiAlias,
                  decoration: BoxDecoration(
                    color: const Color(0xFF151515),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.grey.shade800, width: 1.5),
                  ),
                  child: Image.asset(
                    'assets/images/${unit.id}.png',
                    fit: BoxFit.cover,
                    filterQuality: FilterQuality.high,
                    alignment: Alignment.topCenter,
                    errorBuilder: (context, error, stackTrace) => Container(
                      color: Colors.black26,
                      child: const Icon(Icons.broken_image, size: 40, color: Colors.white10),
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 25),

            // ARMES
            if (rangedWeapons.isNotEmpty) ...[
              _sectionTitle("RANGED WEAPONS", Icons.my_location),
              _weaponHeader("BS"),
              ...rangedWeapons.map((w) => _weaponRow(w)),
              const SizedBox(height: 20),
            ],
            if (meleeWeapons.isNotEmpty) ...[
              _sectionTitle("MELEE WEAPONS", Icons.token),
              _weaponHeader("WS"),
              ...meleeWeapons.map((w) => _weaponRow(w)),
              const SizedBox(height: 20),
            ],

            // ABILITIES
            if (coreAbilities.isNotEmpty || armyAbilities.isNotEmpty) ...[
              _sectionTitle("ABILITIES", Icons.shield),
              Container(
                width: double.infinity, padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(color: const Color(0xFF222222), borderRadius: BorderRadius.circular(4), border: Border.all(color: Colors.grey.shade800)),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    ...coreAbilities.map((a) => _compactAbilityLine("Core: ", a, logoPath, primaryColor)),
                    ...armyAbilities.map((a) => _compactAbilityLine("Army: ", a, logoPath, primaryColor)),
                  ],
                ),
              ),
              const SizedBox(height: 20),
            ],

            // UNIT ABILITIES
            if (specificUnitAbilities.isNotEmpty) ...[
              ...specificUnitAbilities.map((ability) => _abilityCard(ability, cardBackground)),
              const SizedBox(height: 20),
            ],

            // PRIMARCH ABILITIES
            if (unit.primarchAbilities.isNotEmpty) ...[
              ...unit.primarchAbilities.map((primarch) => Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _sectionTitle(primarch.name.toUpperCase(), Icons.auto_awesome),
                  ...primarch.options.map((option) => Container(
                    width: double.infinity,
                    margin: const EdgeInsets.only(bottom: 10),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(color: const Color(0xFF2A2A2A), borderRadius: BorderRadius.circular(6), border: Border.all(color: primaryColor.withValues(alpha:0.5))),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(option.name.toUpperCase(), style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: primaryColor)),
                        const SizedBox(height: 4),
                        Text(option.effect, style: const TextStyle(color: Colors.grey, fontSize: 13, height: 1.3)),
                      ],
                    ),
                  )),
                  const SizedBox(height: 10),
                ],
              )),
            ],

            // WARGEAR
            if (unit.wargearAbilities.isNotEmpty) ...[
              _sectionTitle("WARGEAR ABILITIES", Icons.backpack),
              ...unit.wargearAbilities.map((ability) => _abilityCard(ability, cardBackground)),
              const SizedBox(height: 20),
            ],

            // KEYWORDS
            const Divider(height: 40, color: Colors.grey),
            _keywordBlock("FACTION KEYWORDS", unit.factionKeywords, primaryColor),
            const SizedBox(height: 10),
            _keywordBlock("KEYWORDS", unit.keywords, Colors.white),
            const SizedBox(height: 40),

            const SizedBox(height: 30),
            
            _infoTextBlock("UNIT COMPOSITION", unit.unitComposition, Icons.groups, primaryColor),
            _infoTextBlock("WARGEAR OPTIONS", unit.wargearOptions, Icons.swap_horiz, primaryColor),
            _infoTextBlock("LEADER", unit.leaderInfo, Icons.person_add, primaryColor),
            
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  // --- WIDGETS ---

  Widget _compactAbilityLine(String prefix, Wability a, String logoPath, Color color) {
    bool isArmy = prefix.contains("Army");
    return Padding(
      padding: const EdgeInsets.only(bottom: 6.0),
      child: Tooltip(
        message: a.effect,
        triggerMode: TooltipTriggerMode.tap,
        textStyle: const TextStyle(color: Colors.white),
        decoration: BoxDecoration(color: const Color(0xFF333333), borderRadius: BorderRadius.circular(8), border: Border.all(color: isArmy ? color : Colors.grey)),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (isArmy) ...[
              Image.asset(logoPath, width: 14, height: 14, color: color, colorBlendMode: BlendMode.srcIn, errorBuilder: (c, e, s) => const SizedBox()),
              const SizedBox(width: 6),
            ],
            RichText(
              text: TextSpan(children: [
                TextSpan(text: prefix, style: TextStyle(fontWeight: FontWeight.bold, color: isArmy ? color : Colors.grey, fontSize: 14)),
                TextSpan(text: a.name, style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white, fontSize: 14, decoration: TextDecoration.underline, decorationStyle: TextDecorationStyle.dotted)),
              ]),
            ),
          ],
        ),
      ),
    );
  }

  Widget _statBox(String label, String value, Color borderColor) {
    return Container(
      width: 60, height: 60,
      decoration: BoxDecoration(color: const Color(0xFF222222), borderRadius: BorderRadius.circular(8), border: Border.all(color: borderColor.withValues(alpha:0.7), width: 2)),
      child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
        Text(label, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: Colors.grey)),
        Text(value, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white)),
      ]),
    );
  }

  Widget _sectionTitle(String title, IconData icon,{Color? iconColor}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10.0),
      child: Row(children: [
        Icon(icon, size: 18, color: iconColor ?? Colors.grey),
        const SizedBox(width: 8),
        Text(title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.grey)),
        const SizedBox(width: 8),
        const Expanded(child: Divider(color: Colors.grey)),
      ]),
    );
  }

  Widget _weaponHeader(String skillName) => Padding(
    padding: const EdgeInsets.only(bottom: 8.0, right: 8.0),
    child: Row(children: [const Expanded(child: SizedBox()), _hCell("Rng", 45), _hCell("A", 35), _hCell(skillName, 35), _hCell("S", 35), _hCell("AP", 35), _hCell("D", 35)]),
  );

  Widget _hCell(String t, double w) => SizedBox(width: w, child: Text(t, textAlign: TextAlign.center, style: const TextStyle(color: Colors.grey, fontSize: 11, fontWeight: FontWeight.bold)));

  Widget _weaponRow(Weapon weapon) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 10.0, horizontal: 8.0),
      decoration: const BoxDecoration(border: Border(bottom: BorderSide(color: Colors.white12))),
      child: Row(children: [
        Expanded(child: Wrap(crossAxisAlignment: WrapCrossAlignment.center, children: [
          Text(weapon.name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
          ...weapon.wability.map((a) => Padding(padding: const EdgeInsets.only(left: 6), child: Tooltip(message: a.effect, triggerMode: TooltipTriggerMode.tap, textStyle: const TextStyle(color: Colors.white), decoration: BoxDecoration(color: const Color(0xFF333333), borderRadius: BorderRadius.circular(8)), child: Text("[${a.name}]", style: const TextStyle(color: Colors.orangeAccent, fontSize: 12, fontStyle: FontStyle.italic))))),
        ])),
        _dCell(weapon.range, 45), _dCell(weapon.attacks, 35), _dCell(weapon.bsWs, 35), _dCell("${weapon.strength}", 35), _dCell("${weapon.ap}", 35), _dCell(weapon.damage, 35),
      ]),
    );
  }

  Widget _dCell(String t, double w) => SizedBox(width: w, child: Text(t, textAlign: TextAlign.center, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)));

  Widget _abilityCard(Wability a, Color bg) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 10), padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(6), border: Border.all(color: Colors.white10)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(a.name.toUpperCase(), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
        const SizedBox(height: 4),
        Text(a.effect, style: const TextStyle(color: Colors.grey, fontSize: 13, height: 1.3)),
      ]),
    );
  }

  Widget _keywordBlock(String label, List<String> items, Color color) {
    if (items.isEmpty) return const SizedBox();
    return RichText(text: TextSpan(children: [
      TextSpan(text: "$label: ", style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.grey, fontSize: 11)),
      TextSpan(text: items.join(", ").toUpperCase(), style: TextStyle(fontWeight: FontWeight.bold, color: color, fontSize: 11)),
    ]));
  }
  Widget _infoTextBlock(String title, String content, IconData icon, Color color) {
    if (content.isEmpty) return const SizedBox();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _sectionTitle(title, icon, iconColor: color),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: const Color(0xFF1A1A1A),
            borderRadius: BorderRadius.circular(6),
            border: Border.all(color: Colors.white12),
          ),
          child: Text(
            content,
            style: const TextStyle(color: Colors.white70, fontSize: 13, height: 1.5),
          ),
        ),
        const SizedBox(height: 20),
      ],
    );
  }

}