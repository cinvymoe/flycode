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

/// A local-cached skill record that carries its enabled and starred state.
class SkillRecord {
  final Skill skill;
  final bool enabled;
  final bool starred;

  const SkillRecord({
    required this.skill,
    required this.enabled,
    this.starred = false,
  });

  SkillRecord copyWith({Skill? skill, bool? enabled, bool? starred}) {
    return SkillRecord(
      skill: skill ?? this.skill,
      enabled: enabled ?? this.enabled,
      starred: starred ?? this.starred,
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
      return _loadWithLocalState(dao, cached);
    }

    // No cache yet — wait for the server sync to complete.
    final serverSkills = await ref.watch(skillsProvider.future);

    if (serverSkills.isNotEmpty) {
      await dao.upsertSkills(serverSkills);
    }
    return _loadWithLocalState(dao, serverSkills);
  }

  Future<List<SkillRecord>> _loadWithLocalState(
    SkillDao dao,
    List<Skill> skills,
  ) async {
    final records = <SkillRecord>[];
    for (final skill in skills) {
      final enabled = await dao.isSkillEnabled(skill.name);
      final starred = await dao.isSkillStarred(skill.name);
      records.add(
        SkillRecord(skill: skill, enabled: enabled, starred: starred),
      );
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

      // Directly update state instead of invalidateSelf() to avoid a
      // rebuild loop: invalidateSelf() → build() → _syncFromServer() →
      // invalidateSelf() → … which keeps the provider cycling through
      // AsyncLoading and makes the UI spin forever.
      final records = await _loadWithLocalState(dao, serverSkills);
      state = AsyncData(records);
    } catch (_) {
      // Silently ignore sync errors — cached data is still usable.
    }
  }

  /// Toggle a skill's enabled state.
  Future<void> toggleSkill(String name) async {
    final dao = await ref.read(skillDaoProvider.future);
    final currentEnabled = await dao.isSkillEnabled(name);
    await dao.setSkillEnabled(name, !currentEnabled);
    // Update state directly to avoid invalidateSelf() rebuild loop.
    await _updateStateFromCache(dao);
  }

  /// Enable or disable a specific skill.
  Future<void> setSkillEnabled(String name, bool enabled) async {
    final dao = await ref.read(skillDaoProvider.future);
    await dao.setSkillEnabled(name, enabled);
    // Update state directly to avoid invalidateSelf() rebuild loop.
    await _updateStateFromCache(dao);
  }

  /// Toggle a skill's starred state.
  Future<void> toggleStar(String name) async {
    final dao = await ref.read(skillDaoProvider.future);
    final currentStarred = await dao.isSkillStarred(name);
    await dao.setSkillStarred(name, !currentStarred);
    await _updateStateFromCache(dao);
  }

  /// Force refresh from server + invalidate cache.
  Future<void> refresh() async {
    await _syncFromServer();
  }

  /// Read the current cache and update state directly (avoids rebuild loop).
  Future<void> _updateStateFromCache(SkillDao dao) async {
    final cached = await dao.getAllSkills();
    final records = await _loadWithLocalState(dao, cached);
    state = AsyncData(records);
  }
}
