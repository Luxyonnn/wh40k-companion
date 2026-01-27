import 'dart:ui';

class FactionData {
  final String id;
  final Color color;
  final String logoPath;

  FactionData({
    required this.id,
    required this.color,
    required this.logoPath,
  });

  factory FactionData.fromJson(Map<String, dynamic> json) {
    return FactionData(
      id: json['id'],
      color: _hexToColor(json['color']), // Conversion magique
      logoPath: "assets/logos/${json['logo']}", // On prépare le chemin complet ici
    );
  }

  // Petite fonction utilitaire pour convertir "#RRGGBB" en Color(0xFFRRGGBB)
  static Color _hexToColor(String hexString) {
    final buffer = StringBuffer();
    if (hexString.length == 6 || hexString.length == 7) buffer.write('ff');
    buffer.write(hexString.replaceFirst('#', ''));
    return Color(int.parse(buffer.toString(), radix: 16));
  }
}