# Starred Models — Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Add a "Recommended" filter chip and star-toggle to the model selection sheet, with starred model IDs persisted in SharedPreferences.

**Architecture:** New `StarredModels` Riverpod provider (keepAlive) stores `Set<String>` of `"providerId/modelId"` keys via SharedPreferences. The existing `ModelSelectionSheet` gets a new "Recommended" filter chip, star icon buttons on each model tile, and an empty state when no models are starred.

**Tech Stack:** Flutter, Dart, Riverpod (`@riverpod`), SharedPreferences, json_serializable (for existing models, not new code)

---

## File Map

| File | Action | Responsibility |
|---|---|---|
| `lib/providers/starred_models_provider.dart` | Create | Starred models state + persistence |
| `lib/providers/starred_models_provider.g.dart` | Generate | build_runner output |
| `lib/l10n/app_en.arb` | Modify | 2 new locale keys (EN) |
| `lib/l10n/app_zh.arb` | Modify | 2 new locale keys (ZH) |
| `lib/l10n/app_localizations.dart` | Generate | l10n output |
| `lib/l10n/app_localizations_en.dart` | Generate | l10n output |
| `lib/l10n/app_localizations_zh.dart` | Generate | l10n output |
| `lib/widgets/message/model_selection_sheet.dart` | Modify | Filter chip, star button, empty state, badge logic |

---

### Task 1: Create starred_models_provider.dart

**Files:**
- Create: `lib/providers/starred_models_provider.dart`

- [ ] **Step 1: Write the provider file**

```dart
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
```

- [ ] **Step 2: Run build_runner to generate .g.dart**

```bash
dart run build_runner build --delete-conflicting-outputs
```
Expected: exit 0, `lib/providers/starred_models_provider.g.dart` created.

- [ ] **Step 3: Commit**

```bash
git add lib/providers/starred_models_provider.dart lib/providers/starred_models_provider.g.dart
git commit -m "feat: add StarredModels provider with SharedPreferences persistence"
```

---

### Task 2: Add l10n keys

**Files:**
- Modify: `lib/l10n/app_en.arb` (after `modelSelectionFavorited`, before `messageCopy`)
- Modify: `lib/l10n/app_zh.arb` (after `modelSelectionFavorited`, before `messageCopy`)

- [ ] **Step 1: Add keys to app_en.arb**

In `lib/l10n/app_en.arb`, after line 376 (`"modelSelectionFavorited": "Favorited"`), insert:

```json
  "modelSelectionRecommended": "Recommended",
  "modelSelectionNoStarredModels": "Star a model to access it quickly here",
```

New lines 377-378, existing content shifts down by 2 lines.

- [ ] **Step 2: Add keys to app_zh.arb**

In `lib/l10n/app_zh.arb`, after line 376 (`"modelSelectionFavorited": "已收藏"`), insert:

```json
  "modelSelectionRecommended": "推荐",
  "modelSelectionNoStarredModels": "给模型加星即可在此快速访问",
```

- [ ] **Step 3: Regenerate l10n files**

```bash
dart run build_runner build --delete-conflicting-outputs
```
Expected: exit 0. Verify new getters appear in `lib/l10n/app_localizations_en.dart` and `lib/l10n/app_localizations_zh.dart`.

- [ ] **Step 4: Commit**

```bash
git add lib/l10n/app_en.arb lib/l10n/app_zh.arb lib/l10n/app_localizations.dart lib/l10n/app_localizations_en.dart lib/l10n/app_localizations_zh.dart
git commit -m "feat: add recommended model l10n keys (EN/ZH)"
```

---

### Task 3: Modify model_selection_sheet.dart

**Files:**
- Modify: `lib/widgets/message/model_selection_sheet.dart`

- [ ] **Step 1: Add import for starred_models_provider**

In the imports block (after the `provider_list_provider` import, line 9), add:

```dart
import '../../providers/starred_models_provider.dart';
```

- [ ] **Step 2: Add `_filterRecommended` constant**

In `_ModelSelectionSheetState`, after `_filterAll` (line 25), add:

```dart
  static const String _filterAll = 'all';
  static const String _filterRecommended = 'recommended';  // <-- ADD THIS
```

- [ ] **Step 3: Add `_showRecommendedOnly` getter**

In `_ModelSelectionSheetState`, after the existing `_selectedProviderId` getter (lines 192-197), add:

```dart
  bool get _showRecommendedOnly => _selectedFilterKey == _filterRecommended;
```

- [ ] **Step 4: Add "Recommended" chip in `_buildFilterChips`**

In `_buildFilterChips` (line 213), inside the `Row` children (line 253), add the recommended chip right after the "All" chip. Change lines 253-259 from:

```dart
        children: [
          chip(key: _filterAll, label: context.l10n.commonAll),
          for (final provider in providers) ...[
```

to:

```dart
        children: [
          chip(key: _filterAll, label: context.l10n.commonAll),
          chip(key: _filterRecommended, label: context.l10n.modelSelectionRecommended),
          for (final provider in providers) ...[
```

- [ ] **Step 5: Add starred filter to `_buildProviderGroups`**

Modify `_buildProviderGroups` (line 265) to accept and use starred models. Change the method signature and body:

From (lines 265-307):
```dart
  Map<ProviderModel, List<MapEntry<String, ModelInfo>>> _buildProviderGroups(
    ProviderListResponse providerList,
    Map<String, Map<String, bool>> configs,
    String query,
  ) {
    final normalizedQuery = query.trim().toLowerCase();
    final selectedProviderId = _selectedProviderId;

    final connectedProviders = providerList.all
        .where((p) => providerList.connected.contains(p.id))
        .where((p) => selectedProviderId == null || p.id == selectedProviderId)
        .toList();

    final grouped = <ProviderModel, List<MapEntry<String, ModelInfo>>>{};

    for (final provider in connectedProviders) {
      final providerConfigs = configs[provider.id] ?? {};

      var availableModels = provider.models.entries.where((entry) {
        final modelId = entry.key;
        final model = entry.value;

        if (providerConfigs.containsKey(modelId)) {
          return providerConfigs[modelId]!;
        }
        return _isRecentlyReleased(model.releaseDate);
      }).toList();

      if (normalizedQuery.isNotEmpty) {
        availableModels = availableModels.where((entry) {
          final model = entry.value;
          return model.name.toLowerCase().contains(normalizedQuery) ||
              model.id.toLowerCase().contains(normalizedQuery);
        }).toList();
      }

      if (availableModels.isNotEmpty) {
        grouped[provider] = availableModels;
      }
    }

    return grouped;
  }
```

To:
```dart
  Map<ProviderModel, List<MapEntry<String, ModelInfo>>> _buildProviderGroups(
    ProviderListResponse providerList,
    Map<String, Map<String, bool>> configs,
    Set<String> starredModels,
    String query,
  ) {
    final normalizedQuery = query.trim().toLowerCase();
    final selectedProviderId = _selectedProviderId;

    final connectedProviders = providerList.all
        .where((p) => providerList.connected.contains(p.id))
        .where((p) => selectedProviderId == null || p.id == selectedProviderId)
        .toList();

    final grouped = <ProviderModel, List<MapEntry<String, ModelInfo>>>{};

    for (final provider in connectedProviders) {
      final providerConfigs = configs[provider.id] ?? {};

      var availableModels = provider.models.entries.where((entry) {
        final modelId = entry.key;
        final model = entry.value;

        if (providerConfigs.containsKey(modelId)) {
          return providerConfigs[modelId]!;
        }
        return _isRecentlyReleased(model.releaseDate);
      }).toList();

      // Filter by starred if recommended mode is active
      if (_showRecommendedOnly) {
        availableModels = availableModels.where((entry) {
          return starredModels.contains('${provider.id}/${entry.key}');
        }).toList();
      }

      if (normalizedQuery.isNotEmpty) {
        availableModels = availableModels.where((entry) {
          final model = entry.value;
          return model.name.toLowerCase().contains(normalizedQuery) ||
              model.id.toLowerCase().contains(normalizedQuery);
        }).toList();
      }

      if (availableModels.isNotEmpty) {
        grouped[provider] = availableModels;
      }
    }

    return grouped;
  }
```

- [ ] **Step 6: Update `_buildList` to read and pass starred models**

Modify `_buildList` (line 309) to watch `starredModelsProvider` and pass it to `_buildProviderGroups`:

From (lines 315-322):
```dart
    final theme = Theme.of(context);
    final tokens = context.tokens;
    final providerGroups = _buildProviderGroups(
      providerList,
      configs,
      searchQuery,
    );
```

Change `_buildList` to be a method that also accepts `WidgetRef ref` (it's already in a `ConsumerStatefulWidget`, so `ref` is available via the widget). Actually, `_buildList` is a private method on the state class — it doesn't take `ref`. We need to pass the starred models in. The cleanest way: read `starredModelsProvider` at the call site and pass it through.

In the `build()` method, add a watch just before `_buildList` is called. Change lines 160-186:

In the Expanded child, add `ref.watch(starredModelsProvider)` alongside the other watches. Since we can't watch inside `_buildList` directly, we pass it as a parameter. Update the signature of `_buildList`:

```dart
  Widget _buildList(
    BuildContext context,
    ProviderListResponse providerList,
    Map<String, Map<String, bool>> configs,
    Set<String> starredModels,
    String searchQuery,
    String? selectedProviderId,
  ) {
```

And update the call site in `build()`. The nested `when` block (lines 161-184) uses the current providerList from the outer `when`. We need `starredModels` available inside. Add the watch before the Expanded:

In `build()` method, after the Divider (line 159), add:

```dart
            final starredModels = ref.watch(starredModelsProvider);
```

Then update the `_buildList` call in the `data` handler of the inner `when` (around line 164):

From:
```dart
                    data: (configs) => _buildList(
                      context,
                      providerList,
                      configs,
                      _searchQuery,
                      _selectedProviderId,
                    ),
```

To:
```dart
                    data: (configs) => _buildList(
                      context,
                      providerList,
                      configs,
                      starredModels,
                      _searchQuery,
                      _selectedProviderId,
                    ),
```

Also, add empty-state handling for recommended mode. After the existing empty checks (line 390), add a check before the `listItems.isEmpty` block. Replace the existing empty check block (lines 390-407) with:

```dart
    if (listItems.isEmpty) {
      if (_showRecommendedOnly) {
        return Center(
          child: Text(
            context.l10n.modelSelectionNoStarredModels,
            style: TextStyle(color: tokens.mutedForeground, fontSize: 14),
          ),
        );
      }

      final noMatchByQuery = searchQuery.trim().isNotEmpty;
      final noMatchByProvider =
          selectedProviderId != null && searchQuery.trim().isEmpty;
      String message = context.l10n.modelSelectionNoModels;
      if (noMatchByQuery) {
        message = context.l10n.modelSelectionNoMatchedModels;
      } else if (noMatchByProvider) {
        message = context.l10n.modelSelectionNoModelsUnderProvider;
      }

      return Center(
        child: Text(
          message,
          style: TextStyle(color: tokens.mutedForeground, fontSize: 14),
        ),
      );
    }
```

- [ ] **Step 7: Add star button to `_ModelTile`**

Modify `_ModelTile.build()` to add a star icon button between the model name row and the existing favorite badge. Replace the entire `_ModelTile.build` method body. The key change: the `Row` that contains `modelInfo.name` and the favorite badge now also includes a star button.

Replace lines 436-533 (the entire `build` method and `_isFavoriteModel` method of `_ModelTile`) with:

```dart
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentConfig = ref.watch(chatConfigProvider);
    final isSelected =
        currentConfig.model.providerID == providerId &&
        currentConfig.model.modelID == modelInfo.id;
    final theme = Theme.of(context);
    final tokens = context.tokens;
    final starredModels = ref.watch(starredModelsProvider);
    final isStarred = starredModels.contains('$providerId/${modelInfo.id}');
    final isServerFavorite = _isFavoriteModel(modelInfo);
    // Only show server badge when not locally starred (avoid visual dup)
    final showServerBadge = !isStarred && isServerFavorite && !isSelected;

    return Material(
      color: isSelected
          ? theme.colorScheme.primary.withValues(alpha: 0.08)
          : Colors.transparent,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: () {
          ref
              .read(chatConfigProvider.notifier)
              .setModel(
                MessageModel(providerID: providerId, modelID: modelInfo.id),
              );
          Navigator.pop(context);
        },
        borderRadius: BorderRadius.circular(12),
        hoverColor: tokens.accent,
        splashColor: theme.colorScheme.primary.withValues(alpha: 0.08),
        highlightColor: theme.colorScheme.primary.withValues(alpha: 0.05),
        child: Container(
          padding: const EdgeInsets.fromLTRB(12, 8, 12, 8),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      modelInfo.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontWeight: isSelected
                            ? FontWeight.w700
                            : FontWeight.w600,
                        fontSize: 14,
                        color: isSelected
                            ? theme.colorScheme.primary
                            : theme.colorScheme.onSurface,
                      ),
                    ),
                  ),
                  // Star toggle button — does NOT close the sheet
                  GestureDetector(
                    onTap: () {
                      ref
                          .read(starredModelsProvider.notifier)
                          .toggleStar(providerId, modelInfo.id);
                    },
                    behavior: HitTestBehavior.opaque,
                    child: Padding(
                      padding: const EdgeInsets.all(4.0),
                      child: Icon(
                        isStarred ? Icons.star : Icons.star_border,
                        size: 20,
                        color: isStarred
                            ? theme.colorScheme.primary
                            : tokens.mutedForeground,
                      ),
                    ),
                  ),
                  // Server-side favorite badge (only when not starred)
                  if (showServerBadge)
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 7,
                        vertical: 3,
                      ),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.primary.withValues(
                          alpha: 0.14,
                        ),
                        borderRadius: BorderRadius.circular(tokens.radiusPill),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.bookmark,
                            color: theme.colorScheme.primary,
                            size: 11,
                          ),
                          const SizedBox(width: 3),
                          Text(
                            context.l10n.modelSelectionFavorited,
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w600,
                              color: theme.colorScheme.primary,
                            ),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 2),
              Text(
                modelInfo.id,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(fontSize: 11, color: tokens.mutedForeground),
              ),
            ],
          ),
        ),
      ),
    );
  }

  bool _isFavoriteModel(ModelInfo model) {
    final dynamic raw = model.options['favorite'] ?? model.options['favourite'];
    return raw == true;
  }
```

- [ ] **Step 8: Run flutter analyze**

```bash
flutter analyze
```
Expected: exit 0, no errors. Fix any issues before proceeding.

- [ ] **Step 9: Commit**

```bash
git add lib/widgets/message/model_selection_sheet.dart
git commit -m "feat: add recommended chip, star toggle, and empty state to model selection"
```

---

### Task 4: Run full CI validation

- [ ] **Step 1: Run build_runner**

```bash
dart run build_runner build --delete-conflicting-outputs
```
Expected: exit 0.

- [ ] **Step 2: Format**

```bash
dart format .
```
Expected: exit 0, no changes needed (or minimal auto-format).

- [ ] **Step 3: Analyze**

```bash
flutter analyze
```
Expected: exit 0, no issues.

- [ ] **Step 4: Run tests**

```bash
flutter test
```
Expected: all tests pass. If any fail, investigate and fix.

- [ ] **Step 5: Final commit if any CI fixes were needed**

```bash
git add -A && git commit -m "chore: CI fixes for starred models feature"
```
