import 'dart:convert';

import 'package:json_annotation/json_annotation.dart';

@JsonSerializable(createFactory: false, createToJson: false)
class Command {
  final String name;
  final String? description;
  final String? agent;
  final String? model;
  final bool? mcp;

  /// Origin of this command: "command", "mcp", or "skill".
  final String? source;
  final String template;
  final bool? subtask;
  final List<String> hints;

  const Command({
    required this.name,
    this.description,
    this.agent,
    this.model,
    this.mcp,
    this.source,
    required this.template,
    this.subtask,
    required this.hints,
  });

  factory Command.fromJson(Map<String, dynamic> json) => Command(
    name: json['name'] as String,
    description: json['description'] as String?,
    agent: json['agent'] as String?,
    model: json['model'] as String?,
    mcp: json['mcp'] as bool?,
    source: json['source'] as String?,
    template: _parseTemplate(json['template']),
    subtask: json['subtask'] as bool?,
    hints: _parseHints(json['hints']),
  );

  /// Parse template: server sends String for command/skill templates,
  /// but may also send nested objects (Map) for MCP prompts or null —
  /// flatten to a string representation gracefully.
  static String _parseTemplate(dynamic value) {
    if (value == null) return '';
    if (value is String) return value;
    if (value is Map) return jsonEncode(value);
    return value.toString();
  }

  /// Parse hints: the server typically sends a List<String>, but
  /// individual items can also be Maps or other types — coerce
  /// each element to String.
  static List<String> _parseHints(dynamic value) {
    if (value == null) return const [];
    if (value is! List) return const [];
    return value
        .cast<dynamic>()
        .map((e) {
          if (e is String) return e;
          if (e is Map) return jsonEncode(e);
          return e.toString();
        })
        .toList();
  }

  Map<String, dynamic> toJson() => {
    'name': name,
    if (description != null) 'description': description,
    if (agent != null) 'agent': agent,
    if (model != null) 'model': model,
    if (mcp != null) 'mcp': mcp,
    if (source != null) 'source': source,
    'template': template,
    if (subtask != null) 'subtask': subtask,
    'hints': hints,
  };
}
