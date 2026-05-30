/// Model matching OpenCode's `Skill.Info` schema returned by `GET /skill`.
///
/// Server response shape:
/// ```json
/// {
///   "name": "skill-name",
///   "description": "optional description",
///   "location": "/path/to/SKILL.md",
///   "content": "skill markdown content"
/// }
/// ```
class Skill {
  final String name;
  final String? description;
  final String location;
  final String content;

  const Skill({
    required this.name,
    this.description,
    required this.location,
    required this.content,
  });

  factory Skill.fromJson(Map<String, dynamic> json) => Skill(
    name: json['name'] as String,
    description: json['description'] as String?,
    location: json['location'] as String,
    content: json['content'] as String,
  );

  Map<String, dynamic> toJson() => {
    'name': name,
    if (description != null) 'description': description,
    'location': location,
    'content': content,
  };
}
