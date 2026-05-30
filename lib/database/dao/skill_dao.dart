import 'dart:convert';

import 'package:sqflite/sqflite.dart';

import '../../service/api/models/command.dart';

class SkillDao {
  static const String tableName = 'skills';
  static const String columnName = 'name';
  static const String columnDescription = 'description';
  static const String columnSource = 'source';
  static const String columnAgent = 'agent';
  static const String columnModel = 'model';
  static const String columnTemplate = 'template';
  static const String columnHints = 'hints';
  static const String columnEnabled = 'enabled';
  static const String columnUpdatedAt = 'updated_at';

  final Database db;

  SkillDao(this.db);

  /// Returns all skills from local cache.
  Future<List<Command>> getAllSkills() async {
    final result = await db.query(tableName);
    return result.map(_rowToCommand).toList();
  }

  /// Returns only enabled skills.
  Future<List<Command>> getEnabledSkills() async {
    final result = await db.query(
      tableName,
      where: '$columnEnabled = ?',
      whereArgs: [1],
    );
    return result.map(_rowToCommand).toList();
  }

  /// Returns the enabled state for a skill by name.
  Future<bool> isSkillEnabled(String name) async {
    final result = await db.query(
      tableName,
      columns: [columnEnabled],
      where: '$columnName = ?',
      whereArgs: [name],
    );
    if (result.isEmpty) return true;
    return result.first[columnEnabled] == 1;
  }

  /// Inserts or replaces a skill in the cache.
  Future<void> upsertSkill(Command command) async {
    await db.insert(
      tableName,
      _commandToRow(command),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  /// Batch upsert — syncs server skills into local cache.
  Future<void> upsertSkills(Iterable<Command> commands) async {
    final list = commands.toList();
    if (list.isEmpty) return;

    await db.transaction((txn) async {
      final batch = txn.batch();
      for (final command in list) {
        batch.insert(
          tableName,
          _commandToRow(command),
          conflictAlgorithm: ConflictAlgorithm.replace,
        );
      }
      await batch.commit(noResult: true);
    });
  }

  /// Toggle the enabled flag for a skill.
  Future<void> setSkillEnabled(String name, bool enabled) async {
    await db.update(
      tableName,
      {
        columnEnabled: enabled ? 1 : 0,
        columnUpdatedAt: DateTime.now().millisecondsSinceEpoch,
      },
      where: '$columnName = ?',
      whereArgs: [name],
    );
  }

  /// Remove skills whose names are no longer present on the server.
  Future<void> deleteSkillsNotIn(Set<String> names) async {
    if (names.isEmpty) {
      await db.delete(tableName);
      return;
    }
    final placeholders = List.filled(names.length, '?').join(',');
    await db.delete(
      tableName,
      where: '$columnName NOT IN ($placeholders)',
      whereArgs: names.toList(),
    );
  }

  Map<String, dynamic> _commandToRow(Command command) {
    return {
      columnName: command.name,
      columnDescription: command.description,
      columnSource: command.source,
      columnAgent: command.agent,
      columnModel: command.model,
      columnTemplate: command.template,
      columnHints: jsonEncode(command.hints),
      columnEnabled: 1,
      columnUpdatedAt: DateTime.now().millisecondsSinceEpoch,
    };
  }

  Command _rowToCommand(Map<String, dynamic> row) {
    final hintsRaw = row[columnHints] as String? ?? '[]';
    List<String> hints;
    try {
      hints = (jsonDecode(hintsRaw) as List<dynamic>)
          .map((e) => e as String)
          .toList();
    } catch (_) {
      hints = [];
    }

    return Command(
      name: row[columnName] as String,
      description: row[columnDescription] as String?,
      source: row[columnSource] as String?,
      agent: row[columnAgent] as String?,
      model: row[columnModel] as String?,
      template: row[columnTemplate] as String? ?? '',
      hints: hints,
    );
  }
}
