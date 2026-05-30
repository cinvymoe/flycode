import 'dart:async';

import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../database/database_helper.dart';
import '../database/dao/skill_dao.dart';
import '../service/api/command_api.dart';
import '../service/api/models/command.dart';

part 'skill_provider.g.dart';

@riverpod
DatabaseHelper skillDatabaseHelper(Ref ref) {
  return DatabaseHelper();
}

@riverpod
Future<SkillDao> skillDao(Ref ref) async {
  final dbHelper = ref.watch(skillDatabaseHelperProvider);
  final db = await dbHelper.database;
  return SkillDao(db);
}

/// A local-cached skill record that carries its enabled state.
class SkillRecord {
  final Command command;
  final bool enabled;

  const SkillRecord({required this.command, required this.enabled});

  SkillRecord copyWith({Command? command, bool? enabled}) {
    return SkillRecord(
      command: command ?? this.command,
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
    unawaited(_syncFromServer());

    // If we have cached skills, return them immediately with their
    // enabled state from the local DB.
    if (cached.isNotEmpty) {
      return await _loadWithEnabledState(dao, cached);
    }

    // No cache yet — wait for the server sync to complete.
    final serverSkills = await ref.read(commandsProvider.future);
    final skills = serverSkills.where((c) => c.source == 'skill').toList();

    // Debug: log what the server actually returned so we can verify
    // the source field values.
    print('[SkillProvider] Server returned ${serverSkills.length} commands');
    for (final c in serverSkills) {
      print('[SkillProvider]  name=${c.name} source=${c.source}');
    }
    print('[SkillProvider] Filtered ${skills.length} skills');

    if (skills.isNotEmpty) {
      await dao.upsertSkills(skills);
    }
    return await _loadWithEnabledState(dao, skills);
  }

  Future<List<SkillRecord>> _loadWithEnabledState(
    SkillDao dao,
    List<Command> commands,
  ) async {
    final records = <SkillRecord>[];
    for (final cmd in commands) {
      final isEnabled = await dao.isSkillEnabled(cmd.name);
      records.add(SkillRecord(command: cmd, enabled: isEnabled));
    }
    return records;
  }

  Future<void> _syncFromServer() async {
    try {
      final serverSkills = await ref.read(commandsProvider.future);
      final skills = serverSkills.where((c) => c.source == 'skill').toList();

      print(
        '[SkillProvider._syncFromServer] Server returned ${serverSkills.length} commands',
      );
      for (final c in serverSkills) {
        print(
          '[SkillProvider._syncFromServer]  name=${c.name} source=${c.source}',
        );
      }
      print('[SkillProvider._syncFromServer] Filtered ${skills.length} skills');

      final dao = await ref.read(skillDaoProvider.future);

      // Upsert all server skills into cache.
      await dao.upsertSkills(skills);

      // Remove stale skills that are no longer on the server.
      final serverNames = skills.map((c) => c.name).toSet();
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
