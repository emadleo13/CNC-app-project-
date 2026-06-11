class GcodeProgram {
  final String       id;
  final String       title;
  final String       category;
  final String       dialect;
  final String       difficulty; // 'beginner' | 'intermediate' | 'advanced'
  final String       description;
  final String       code;
  final List<String> notes;

  const GcodeProgram({
    required this.id,
    required this.title,
    required this.category,
    required this.dialect,
    required this.difficulty,
    required this.description,
    required this.code,
    required this.notes,
  });

  factory GcodeProgram.fromJson(Map<String, dynamic> json) {
    return GcodeProgram(
      id:          json['id'] as String,
      title:       json['title'] as String,
      category:    json['category'] as String,
      dialect:     json['dialect'] as String,
      difficulty:  json['difficulty'] as String,
      description: json['description'] as String,
      code:        json['code'] as String,
      notes:       List<String>.from(json['notes'] as List),
    );
  }
}
