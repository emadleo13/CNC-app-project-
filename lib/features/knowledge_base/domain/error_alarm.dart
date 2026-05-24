class ErrorAlarm {
  final String code;
  final String machine; // 'haas' | 'sinumerik'
  final String title;
  final String description;
  final List<String> possibleCauses;
  final List<String> solutions;
  final String severity; // 'info' | 'warning' | 'error' | 'critical'

  const ErrorAlarm({
    required this.code,
    required this.machine,
    required this.title,
    required this.description,
    required this.possibleCauses,
    required this.solutions,
    required this.severity,
  });

  factory ErrorAlarm.fromJson(Map<String, dynamic> json, String machine) {
    return ErrorAlarm(
      code:           json['code'] as String,
      machine:        machine,
      title:          json['title'] as String,
      description:    json['description'] as String,
      possibleCauses: List<String>.from(json['possible_causes'] as List),
      solutions:      List<String>.from(json['solutions'] as List),
      severity:       json['severity'] as String,
    );
  }
}
