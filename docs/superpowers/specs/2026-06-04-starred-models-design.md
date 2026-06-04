# Starred Models — Design Spec

## Problem

Users frequently switch between a small set of preferred models. The current model selection sheet lists all models grouped by provider with no way to bookmark or quickly access favorites. Navigating a long list every time is friction.

## Goal

Add a "Recommended" (推荐) section to the model selection sheet. Users can star any model; starred models appear in a dedicated filter view for fast access. Star state is persisted locally and shared globally across all sessions and server connections.

## Design Decisions

| Decision | Choice | Rationale |
|---|---|---|
| Storage mechanism | SharedPreferences | Simple ID set, no relational queries needed. Consistent with `model_variant_provider` pattern. |
| Star scope | Global (not per-server) | User's preferred models are personal and don't depend on server context. |
| Star trigger | Star icon button on model tile | Single-tap action, doesn't close the sheet, distinct from model selection. |
| Recommended UI | Filter chip in existing chip row | Minimal UI change, consistent with existing "All" / provider filter pattern. |
| Server-side favorite badge | Shown only when model is NOT starred | Avoids visual duplication — star icon already conveys "favorited" when starred. |

## Data Layer

### New file: `lib/providers/starred_models_provider.dart`

- `@Riverpod(keepAlive: true)` — global, survives page lifecycle.
- State type: `Set<String>` — each entry is `"providerId/modelId"` (matches `buildModelKey()` from `model_variant_provider`).
- SharedPreferences key: `starred_models`.
- Stored as JSON-encoded `List<String>`.

#### Public API

```dart
@riverpod
class StarredModels extends _$StarredModels {
  @override
  Set<String> build(); // restore from SharedPreferences

  void toggleStar(String providerId, String modelId); // add or remove, persist
}
```

#### Persistence

- `build()`: Read `SharedPreferences.getString('starred_models')`, decode JSON list, convert to `Set<String>`. On error or missing key, return empty set.
- `toggleStar()`: Add/remove key from set, call `_persist()`.
- `_persist()`: Encode set as JSON list, write to SharedPreferences.

## UI Layer

### Changes to `lib/widgets/message/model_selection_sheet.dart`

#### 1. New filter chip: "Recommended"

- Constant `_filterRecommended = 'recommended'` alongside existing `_filterAll`.
- Chip appears immediately after "全部" chip in the horizontal scroll row.
- When selected, `_buildProviderGroups` filters to only include starred models.
- `_selectedProviderId` returns `null` when `_filterRecommended` is active (same as "All"), filtering is handled by a separate `_showRecommendedOnly` boolean.

#### 2. Empty state for recommended

When `_filterRecommended` is active and no models are starred, show centered text with localization key `modelSelectionNoStarredModels`.

#### 3. Star icon button on `_ModelTile`

- Positioned to the right of the model name, before the existing favorite badge.
- Unstarred: `Icons.star_border`, color `tokens.mutedForeground`.
- Starred: `Icons.star`, color `theme.colorScheme.primary`.
- Size: 20px, tight padding to avoid inflating tile height.
- On tap: call `ref.read(starredModelsProvider.notifier).toggleStar(providerId, modelInfo.id)`.
- Tap does **not** close the sheet.
- Star button tap must not propagate to the model selection `InkWell`. Wrap star button in its own `GestureDetector` or use `IconButton` with `onPressed` which naturally stops propagation.

#### 4. Server-side favorite badge behavior

Current code checks `model.options['favorite']` and shows a "已收藏" badge. After this change:
- If model is starred (local), show star icon only — hide the server-side badge.
- If model is not starred but has `options['favorite'] == true`, show the existing badge as-is.

This avoids two "favorite" indicators on the same tile.

## Internationalization

New keys in `app_en.arb` and `app_zh.arb`:

| Key | EN | ZH |
|---|---|---|
| `modelSelectionRecommended` | Recommended | 推荐 |
| `modelSelectionNoStarredModels` | Star a model to access it quickly here | 给模型加星即可在此快速访问 |

## File Change List

| File | Action | Description |
|---|---|---|
| `lib/providers/starred_models_provider.dart` | Create | Starred models provider with SharedPreferences persistence |
| `lib/providers/starred_models_provider.g.dart` | Generate | build_runner output |
| `lib/widgets/message/model_selection_sheet.dart` | Modify | Add recommended chip, star button, empty state, badge logic |
| `lib/l10n/app_en.arb` | Modify | Add 2 localization keys |
| `lib/l10n/app_zh.arb` | Modify | Add 2 localization keys |
| `lib/l10n/app_localizations.dart` | Generate | l10n output |
| `lib/l10n/app_localizations_en.dart` | Generate | l10n output |
| `lib/l10n/app_localizations_zh.dart` | Generate | l10n output |

## Out of Scope

- Modifying `ModelInfo` or `ProviderModel` server-side models
- Modifying `model_config_provider` (enable/disable logic is independent)
- Modifying `chat_config_provider` (model selection logic unchanged)
- Drag-to-reorder starred models
- Custom sort order within recommended group
- Export/import of starred model lists
