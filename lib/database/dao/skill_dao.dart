import 'package:sqflite/sqflite.dart';

import '../../service/api/models/skill.dart';

class SkillDao {
  static const String tableName = 'skills';
  static const String columnName = 'name';
  static const String columnDescription = 'description';
  static const String columnLocation = 'location';
  static const String columnContent = 'content';
  static const String columnEnabled = 'enabled';
  static const String columnStarred = 'starred';
  static const String columnUpdatedAt = 'updated_at';

  final Database db;

  SkillDao(this.db);

  /// Returns all skills from local cache.
  Future<List<Skill>> getAllSkills() async {
    final result = await db.query(tableName);
    return result.map(_rowToSkill).toList();
  }

  /// Returns only enabled skills.
  Future<List<Skill>> getEnabledSkills() async {
    final result = await db.query(
      tableName,
      where: '$columnEnabled = ?',
      whereArgs: [1],
    );
    return result.map(_rowToSkill).toList();
  }

  /// Returns only starred skills.
  Future<List<Skill>> getStarredSkills() async {
    final result = await db.query(
      tableName,
      where: '$columnStarred = ?',
      whereArgs: [1],
    );
    return result.map(_rowToSkill).toList();
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

  /// Returns the starred state for a skill by name.
  Future<bool> isSkillStarred(String name) async {
    final result = await db.query(
      tableName,
      columns: [columnStarred],
      where: '$columnName = ?',
      whereArgs: [name],
    );
    if (result.isEmpty) return false;
    return result.first[columnStarred] == 1;
  }

  /// Inserts or replaces a skill in the cache.
  Future<void> upsertSkill(Skill skill) async {
    await db.insert(
      tableName,
      _skillToRow(skill),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  /// Batch upsert — syncs server skills into local cache.
  Future<void> upsertSkills(Iterable<Skill> skills) async {
    final list = skills.toList();
    if (list.isEmpty) return;

    await db.transaction((txn) async {
      final batch = txn.batch();
      for (final skill in list) {
        batch.insert(
          tableName,
          _skillToRow(skill),
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

  /// Set the starred flag for a skill.
  Future<void> setSkillStarred(String name, bool starred) async {
    await db.update(
      tableName,
      {
        columnStarred: starred ? 1 : 0,
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

  Map<String, dynamic> _skillToRow(Skill skill) {
    return {
      columnName: skill.name,
      columnDescription: skill.description,
      columnLocation: skill.location,
      columnContent: skill.content,
      columnEnabled: 1,
      columnUpdatedAt: DateTime.now().millisecondsSinceEpoch,
    };
  }

  Skill _rowToSkill(Map<String, dynamic> row) {
    return Skill(
      name: row[columnName] as String,
      description: row[columnDescription] as String?,
      location: row[columnLocation] as String? ?? '',
      content: row[columnContent] as String? ?? '',
    );
  }
}
