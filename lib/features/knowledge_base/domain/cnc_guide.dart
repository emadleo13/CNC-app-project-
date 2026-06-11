class GuideSection {
  final String heading;
  final String body;

  const GuideSection({required this.heading, required this.body});

  factory GuideSection.fromJson(Map<String, dynamic> json) {
    return GuideSection(
      heading: json['heading'] as String,
      body:    json['body'] as String,
    );
  }
}

class CncGuide {
  final String             id;
  final String             title;
  final String             category;
  final String             icon;
  final String             summary;
  final List<GuideSection> sections;

  const CncGuide({
    required this.id,
    required this.title,
    required this.category,
    required this.icon,
    required this.summary,
    required this.sections,
  });

  factory CncGuide.fromJson(Map<String, dynamic> json) {
    return CncGuide(
      id:       json['id'] as String,
      title:    json['title'] as String,
      category: json['category'] as String,
      icon:     json['icon'] as String,
      summary:  json['summary'] as String,
      sections: (json['sections'] as List)
          .map((e) => GuideSection.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }
}
