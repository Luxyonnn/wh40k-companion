import 'package:flutter/material.dart';
import 'unit.dart';
import 'weapon.dart';
import 'wability.dart';

class UnitComparisonScreen extends StatelessWidget {
  final Unit unitA;
  final Unit unitB;

  const UnitComparisonScreen({super.key, required this.unitA, required this.unitB});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF121212),
      appBar: AppBar(
        title: const Text("VS", style: TextStyle(fontWeight: FontWeight.bold, letterSpacing: 1.5)),
        centerTitle: true,
        backgroundColor: const Color(0xFF1E1E1E),
        elevation: 0,
      ),
      body: SingleChildScrollView(
        child: IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // --- COLONNE UNITÉ A ---
              Expanded(
                child: _UnitFullColumn(unit: unitA, color: Colors.blueGrey),
              ),
              
              // --- SÉPARATEUR VERTICAL ---
              Container(width: 1, color: Colors.white24),

              // --- COLONNE UNITÉ B ---
              Expanded(
                child: _UnitFullColumn(unit: unitB, color: Colors.brown),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _UnitFullColumn extends StatelessWidget {
  final Unit unit;
  final Color color;

  const _UnitFullColumn({required this.unit, required this.color});

  @override
  Widget build(BuildContext context) {
    final rangedWeapons = unit.weapons.where((w) => w.range.toLowerCase() != "melee").toList();
    final meleeWeapons = unit.weapons.where((w) => w.range.toLowerCase() == "melee").toList();
    final specificUnitAbilities = unit.abilities.where((a) => a.id.startsWith("UNIT_")).toList();

    return Container(
      padding: const EdgeInsets.only(bottom: 40),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          
          const SizedBox(height: 20),

          // 1. IMAGE (Plus grande : 150px au lieu de 100px)
          Center(
            child: Container(
              height: 150, width: 150, 
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: color.withValues(alpha: 0.5), width: 3),
                boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.5), blurRadius: 15)],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(9),
                child: Image.asset(
                  'assets/images/${unit.id}.png',
                  fit: BoxFit.cover,
                  alignment: Alignment.topCenter,
                  errorBuilder: (c, e, s) => Container(color: Colors.black, child: const Icon(Icons.person, size: 60, color: Colors.white24)),
                ),
              ),
            ),
          ),

          const SizedBox(height: 15),

          // 2. EN-TÊTE (Police agrandie)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12.0),
            child: Column(
              children: [
                Text(
                  unit.name.toUpperCase(),
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18, height: 1.1),
                ),
                const SizedBox(height: 6),
                Text(unit.faction.toUpperCase(), style: TextStyle(color: color, fontSize: 12, fontWeight: FontWeight.bold)),
                const SizedBox(height: 4),
                Text("${unit.points} PTS", style: const TextStyle(color: Colors.amber, fontSize: 14, fontWeight: FontWeight.bold)),
              ],
            ),
          ),

          const SizedBox(height: 20),

          // 3. STATS (Blocs agrandis)
          Container(
            padding: const EdgeInsets.symmetric(vertical: 12),
            color: const Color(0xFF222222),
            child: Wrap(
              alignment: WrapAlignment.center,
              spacing: 8, runSpacing: 8,
              children: [
                _miniStat("M", "${unit.move}\""),
                _miniStat("T", "${unit.toughness}"),
                _miniStat("SV", "${unit.save}+"),
                _miniStat("W", "${unit.wounds}"),
                _miniStat("LD", "${unit.leadership}+"),
                _miniStat("OC", "${unit.oc}"),
                if(unit.inv > 0) _miniStat("INV", "${unit.inv}+", isInv: true),
              ],
            ),
          ),

          // 4. ARMES
          if (rangedWeapons.isNotEmpty) ...[
            _sectionTitle("RANGED", Icons.my_location),
            _weaponHeaderRow("BS"), 
            ...rangedWeapons.map((w) => _tightWeaponRow(w, "BS")),
          ],

          if (meleeWeapons.isNotEmpty) ...[
            _sectionTitle("MELEE", Icons.token),
            _weaponHeaderRow("WS"),
            ...meleeWeapons.map((w) => _tightWeaponRow(w, "WS")),
          ],

          // 5. APTITUDES CLÉS (Core / Army) - AVEC TOOLTIPS
          if (unit.abilities.any((a) => a.id.startsWith("CORE") || a.id.startsWith("ARMY"))) ...[
             _sectionTitle("ABILITIES", Icons.shield),
             Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: unit.abilities.where((a) => a.id.startsWith("CORE") || a.id.startsWith("ARMY")).map((a) => 
                  Padding(
                    padding: const EdgeInsets.only(bottom: 6),
                    // AJOUT TOOLTIP ICI
                    child: Tooltip(
                      message: a.effect,
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(color: const Color(0xFF333333), borderRadius: BorderRadius.circular(8), border: Border.all(color: Colors.white24)),
                      textStyle: const TextStyle(color: Colors.white, fontSize: 14),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.info_outline, size: 14, color: Colors.grey),
                          const SizedBox(width: 6),
                          Flexible(child: Text(a.name, style: const TextStyle(fontSize: 13, color: Colors.white, decoration: TextDecoration.underline, decorationStyle: TextDecorationStyle.dotted))),
                        ],
                      ),
                    ),
                  )
                ).toList(),
              ),
            ),
          ],

          // 6. APTITUDES D'UNITÉ
          if (specificUnitAbilities.isNotEmpty) ...[
            _sectionTitle("UNIT ABILITIES", Icons.star),
            ...specificUnitAbilities.map((a) => _fullWidthAbilityBox(a.name, a.effect)),
          ],

          // 7. PRIMARQUES
          if (unit.primarchAbilities.isNotEmpty) ...[
            ...unit.primarchAbilities.map((p) => Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _sectionTitle(p.name.toUpperCase(), Icons.auto_awesome),
                ...p.options.map((opt) => _fullWidthAbilityBox(opt.name, opt.effect)),
              ],
            ))
          ],
        ],
      ),
    );
  }

  // --- WIDGETS ---

  // Statistique (Case plus grande)
  Widget _miniStat(String label, String val, {bool isInv = false}) {
    return Container(
      width: 45, height: 45, // Agrandissement (32 -> 45)
      decoration: BoxDecoration(
        border: Border.all(color: isInv ? Colors.blueAccent.withValues(alpha: 0.5) : Colors.white12),
        borderRadius: BorderRadius.circular(6),
        color: const Color(0xFF333333)
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(label, style: const TextStyle(fontSize: 10, color: Colors.grey, fontWeight: FontWeight.bold)),
          Text(val, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.white)),
        ],
      ),
    );
  }

  Widget _sectionTitle(String title, IconData icon) {
    return Padding(
      padding: const EdgeInsets.only(top: 20, bottom: 8, left: 8, right: 8),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 6),
        color: Colors.white.withValues(alpha: 0.05),
        child: Row(
          children: [
            Icon(icon, size: 16, color: Colors.amber),
            const SizedBox(width: 8),
            Expanded(child: Text(title, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Colors.amber))),
          ],
        ),
      ),
    );
  }

  // En-tête élargi pour les armes
  Widget _weaponHeaderRow(String skill) {
    return Padding(
      padding: const EdgeInsets.only(right: 4, bottom: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          _hText("R", 30),
          _hText("A", 25),
          _hText(skill, 25),
          _hText("S", 25),
          _hText("AP", 25),
          _hText("D", 25),
        ],
      ),
    );
  }
  
  // Texte d'en-tête plus grand
  Widget _hText(String t, double w) => SizedBox(width: w, child: Text(t, textAlign: TextAlign.center, style: const TextStyle(color: Colors.grey, fontSize: 10, fontWeight: FontWeight.bold)));

  // Ligne d'arme avec Tooltips sur les Keywords
  Widget _tightWeaponRow(Weapon w, String skillLabel) {
    return Container(
      decoration: const BoxDecoration(border: Border(bottom: BorderSide(color: Colors.white10))),
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4), // Plus d'espace vertical
      child: Row(
        children: [
          // GAUCHE : Nom + Keywords (Tooltip)
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(w.name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.white)),
                if (w.wability.isNotEmpty)
                  Wrap(
                    spacing: 4,
                    children: w.wability.map((a) => Tooltip(
                      // AJOUT TOOLTIP SUR LES KEYWORDS D'ARME
                      message: a.effect,
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(color: const Color(0xFF333333), borderRadius: BorderRadius.circular(8), border: Border.all(color: Colors.orangeAccent)),
                      textStyle: const TextStyle(color: Colors.white, fontSize: 13),
                      child: Text(
                        "[${a.name}]", 
                        style: const TextStyle(fontSize: 11, color: Colors.orangeAccent, fontStyle: FontStyle.italic, decoration: TextDecoration.underline, decorationStyle: TextDecorationStyle.dotted),
                      ),
                    )).toList(),
                  ),
              ],
            ),
          ),
          
          // DROITE : Les stats (Largeur fixe augmentée)
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
               _wStat(w.range, 30),
               _wStat("${w.attacks}", 25),
               _wStat(w.bsWs, 25),
               _wStat("${w.strength}", 25),
               _wStat("${w.ap}", 25),
               _wStat(w.damage, 25),
            ],
          ),
        ],
      ),
    );
  }

  Widget _wStat(String val, double width) {
    return SizedBox(
      width: width,
      child: Text(
        val, 
        textAlign: TextAlign.center, 
        style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Colors.white)
      ),
    );
  }

  // Boîte d'aptitude agrandie
  Widget _fullWidthAbilityBox(String name, String effect) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.symmetric(horizontal: 6, vertical: 6),
      padding: const EdgeInsets.all(12), // Padding augmenté
      decoration: BoxDecoration(
        color: const Color(0xFF252525),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: Colors.white12)
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(name.toUpperCase(), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.white)),
          const SizedBox(height: 6),
          Text(effect, style: const TextStyle(color: Colors.grey, fontSize: 12, height: 1.4)),
        ],
      ),
    );
  }
}