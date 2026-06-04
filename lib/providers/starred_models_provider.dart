import 'dart:async';
import 'dart:convert';

import 'package:riverpod_annotation/riverpod_annotation.dart';

import 'shared_preferences_provider.dart';

part 'starred_models_provider.g.dart';

const String _kStarredModelsCacheKey = 'starred_models';

@Riverpod(keepAlive: true)
class StarredModels extends _$StarredModels {
  final Set<String> _starred = <String>{};
  bool _restored = false;

  @override
  Set<String> build() {
    if (!_restored) {
      _restored = true;
      unawaited(_restore());
    }
    return <String>{};
  }

  bool isStarred(String providerId, String modelId) {
    return _starred.contains('$providerId/$modelId');
  }

  void toggleStar(String providerId, String modelId) {
    final key = '$providerId/$modelId';
    if (_starred.contains(key)) {
      _starred.remove(key);
    } else {
      _starred.add(key);
    }
    if (ref.mounted) {
      state = Set<String>.from(_starred);
    }
    unawaited(_persist());
  }

  Future<void> _restore() async {
    final prefs = await ref.read(sharedPreferencesProvider.future);
    final raw = prefs.getString(_kStarredModelsCacheKey);
    if (raw == null || raw.trim().isEmpty) return;

    try {
      final json = jsonDecode(raw);
      if (json is! List) return;
      _starred.addAll(json.cast<String>().where((e) => e.isNotEmpty));
      if (ref.mounted) {
        state = Set<String>.from(_starred);
      }
    } catch (_) {
      // Ignore invalid cached payload.
    }
  }

  Future<void> _persist() async {
    final prefs = await ref.read(sharedPreferencesProvider.future);
    await prefs.setString(
      _kStarredModelsCacheKey,
      jsonEncode(_starred.toList()),
    );
  }
}
