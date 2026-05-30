import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../database/database_helper.dart';
import '../database/dao/skill_dao.dart';
import '../service/api/skill_api.dart';
import '../service/api/models/skill.dart';

part 'skill_provider.g.dart';

@Riverpod(keepAlive: true)
DatabaseHelper skillDatabaseHelper(Ref ref) {
  return DatabaseHelper();
}

@Riverpod(keepAlive: true)
Future<SkillDao> skillDao(Ref ref) async {
  final dbHelper = ref.watch(skillDatabaseHelperProvider);
  final db = await dbHelper.database;
  return SkillDao(db);
}

/// A local-cached skill record that carries its enabled state.
class SkillRecord {
  final Skill skill;
  final bool enabled;

  const SkillRecord({required this.skill, required this.enabled});

  SkillRecord copyWith({Skill? skill, bool? enabled}) {
    return SkillRecord(
      skill: skill ?? this.skill,
      enabled: enabled ?? this.enabled,
    );
  }
}

@Riverpod(keepAlive: true)
class SkillNotifier extends _$SkillNotifier {
  @override
  Future<List<SkillRecord>> build() async {
    final dao = await ref.watch(skillDaoProvider.future);
    final cached = await dao.getAllSkills();

    // Kick off a background sync from server so cache stays fresh.
    _syncFromServer();

    // If we have cached skills, return them immediately with their
    // enabled state from the local DB.
    if (cached.isNotEmpty) {
      return _loadWithEnabledState(dao, cached);
    }

    // No cache yet — wait for the server sync to complete.
    final serverSkills = await ref.watch(skillsProvider.future);

    if (serverSkills.isNotEmpty) {
      await dao.upsertSkills(serverSkills);
    }
    return _loadWithEnabledState(dao, serverSkills);
  }

  Future<List<SkillRecord>> _loadWithEnabledState(
    SkillDao dao,
    List<Skill> skills,
  ) async {
    final records = <SkillRecord>[];
    for (final skill in skills) {
      final enabled = await dao.isSkillEnabled(skill.name);
      records.add(SkillRecord(skill: skill, enabled: enabled));
    }
    return records;
  }

  Future<void> _syncFromServer() async {
    try {
      final serverSkills = await ref.read(skillsProvider.future);
      final dao = await ref.read(skillDaoProvider.future);

      // Upsert all server skills into cache.
      await dao.upsertSkills(serverSkills);

      // Remove stale skills that are no longer on the server.
      final serverNames = serverSkills.map((s) => s.name).toSet();
      await dao.deleteSkillsNotIn(serverNames);

      ref.invalidateSelf();
    } catch (_) {
      // Silently ignore sync errors — cached data is still usable.
    }
  }

  /// Toggle a skill's enabled state.
  Future<void> toggleSkill(String name) async {
    final dao = await ref.read(skillDaoProvider.future);
    final currentEnabled = await dao.isSkillEnabled(name);
    await dao.setSkillEnabled(name, !currentEnabled);
    ref.invalidateSelf();
  }

  /// Enable or disable a specific skill.
  Future<void> setSkillEnabled(String name, bool enabled) async {
    final dao = await ref.read(skillDaoProvider.future);
    await dao.setSkillEnabled(name, enabled);
    ref.invalidateSelf();
  }

  /// Force refresh from server + invalidate cache.
  Future<void> refresh() async {
    await _syncFromServer();
  }
}
