class Event {
  final String id;
  final String nomblague;
  String blague;
  final List<String> like;
  final String user;
  final List<String> suppression;

  Event({
    required this.id,
    required this.nomblague,
    required this.blague,
    required this.like,
    required this.user,
    required this.suppression,
  });

  factory Event.fromData(Map<String, dynamic> data) {
    return Event(
      id: data['id'] ?? '',
      nomblague: data['nom_blague'] ?? '',
      blague: data['blague'] ?? '',
      like: List<String>.from(data['like'] ?? []),
      user: data['createur'] ?? '',
      suppression: List<String>.from(data['suppression'] ?? []),
    );
  }
}
