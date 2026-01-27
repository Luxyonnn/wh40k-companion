class Wability {
  final String id;
  final String name;
  final String effect;

  Wability({required this.id, required this.name, required this.effect});

  factory Wability.fromJson(Map<String, dynamic> json) {
    return Wability(
      id: json['id'] ?? '',
      name: json['name'] ?? 'Inconnu',
      effect: json['effect'] ?? '',
    );
  }
}