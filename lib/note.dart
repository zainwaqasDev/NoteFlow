class Note {
  int? key;

  String title;
  String description;
  DateTime createdAt;
  bool isPinned;

  Note({
    this.key,
    required this.title,
    required this.description,
    required this.createdAt,
    this.isPinned = false,
  });
}
