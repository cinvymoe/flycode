# Skill Selection Sheet Improvements

**Date**: 2026-05-30
**Status**: Approved

## Problem

The skill selection bottom sheet has three issues:

1. **No star/favorite functionality** — Users cannot mark frequently-used skills, forcing them to scroll/search every time.
2. **Right-side Switch is redundant** — The `Switch` widget on each row duplicates the row's `onTap` toggle behavior, wasting space and confusing interaction.
3. **Clicking a skill doesn't populate the input** — The `onTap` handler toggles the skill's `enabled` state instead of inserting `/skill-name` into the chat input field, which is the expected behavior (matching the command popup).

## Design Decisions

| Decision | Choice | Rationale |
|---|---|---|
| Star storage | SQLite `skills.starred` column | Colocated with existing skill data; no new table needed; survives server sync |
| Right-side button | Remove Switch entirely | Clicking the row will insert into input; enabled/disabled can be managed elsewhere if needed later |
| Click behavior | Insert `/skill-name` into input + close sheet | Matches `ChatCommandPopup` behavior; user confirmed |

## Changes

### 1. Database Schema (`lib/database/database_helper.dart`)

- Bump `_dbVersion` from 4 to 5
- In `_onCreate`, add `starred INTEGER NOT NULL DEFAULT 0` to the `skills` table definition
- In `_onUpgrade`, add migration for `oldVersion < 5`: `ALTER TABLE skills ADD COLUMN starred INTEGER NOT NULL DEFAULT 0`

### 2. DAO (`lib/database/dao/skill_dao.dart`)

Add three methods:

- `Future<bool> isSkillStarred(String name)` — query `starred` column
- `Future<void> setSkillStarred(String name, bool starred)` — update `starred` column
- `Future<List<Skill>> getStarredSkills()` — query where `starred = 1`

### 3. Provider (`lib/providers/skill_provider.dart`)

- Add `starred` field to `SkillRecord` class (alongside existing `enabled`)
- Update `SkillRecord.copyWith` to include `starred`
- Update `_loadWithEnabledState` (rename to `_loadWithLocalState`) to also load `starred` from DAO
- Add `toggleStar(String name)` method to `SkillNotifier`
- Update `_updateStateFromCache` accordingly

### 4. UI (`lib/widgets/message/chat_input.dart`)

#### _SkillSelectionSheet changes:

- **Add `onSkillTap` callback**: `ValueChanged<Skill>? onSkillTap` parameter
- **Remove Switch**: Delete the `Switch` widget from the `Row` inside each list item
- **Change `onTap` behavior**: Instead of `toggleSkill`, call `onSkillTap?.call(skill)` + `Navigator.pop(context)`
- **Add star icon button**: Add an `IconButton` with `Icons.star` / `Icons.star_border` to the right side of each row (replacing the Switch position)
  - Star tap calls `ref.read(skillProvider.notifier).toggleStar(skill.name)`
  - Does NOT close the sheet (user may want to star multiple skills)
- **Sort skills**: Starred skills first, then alphabetical by name

#### _showSkillSelector changes:

- Pass `onSkillTap` callback to `_SkillSelectionSheet`
- Callback inserts `/${skill.name} ` into `_controller`, pops the sheet, and requests focus

#### ChatInputState changes:

- Add public `insertSkillName(String skillName)` method (or reuse `insertCommand` by constructing a lightweight `Command`)

### 5. Localization (`lib/l10n/app_en.arb`, `lib/l10n/app_zh.arb`)

No new strings required — the star icon is universally understood, and the existing `skillSelectionTitle`, `skillSelectionSearchHint`, `skillSelectionNoSkills` are sufficient.

## Skill List Sorting Logic

```
1. Starred skills (sorted alphabetically by name)
2. Non-starred skills (sorted alphabetically by name)
```

Within each group, search filtering still applies.

## Data Flow

```
User taps star icon
  → SkillNotifier.toggleStar(name)
    → SkillDao.setSkillStarred(name, true)
    → _updateStateFromCache(dao)
      → state = AsyncData(updatedRecords)
        → UI rebuilds with starred items on top

User taps skill row
  → onSkillTap callback
    → _controller.value = TextEditingValue(text: '/skillName ')
    → Navigator.pop(context)
    → _focusNode.requestFocus()
```

## Files Changed

| File | Change Type |
|---|---|
| `lib/database/database_helper.dart` | Schema migration |
| `lib/database/dao/skill_dao.dart` | New methods |
| `lib/providers/skill_provider.dart` | New field + method |
| `lib/providers/skill_provider.g.dart` | Regenerated |
| `lib/widgets/message/chat_input.dart` | UI changes (star, remove switch, fix onTap) |
| `lib/l10n/app_en.arb` | No changes needed |
| `lib/l10n/app_zh.arb` | No changes needed |

## Verification

1. Open skill sheet → starred skills appear at top
2. Tap star icon → skill moves to top without closing sheet
3. Tap star icon again → skill unstars and moves back to alphabetical position
4. Tap skill row → sheet closes, input field shows `/skill-name ` with cursor after space
5. Switch widget is gone from skill list items
6. DB migration works from version 4 → 5 without data loss
7. `dart run build_runner build --delete-conflicting-outputs` succeeds
8. `flutter analyze` clean
9. `flutter test` passes
