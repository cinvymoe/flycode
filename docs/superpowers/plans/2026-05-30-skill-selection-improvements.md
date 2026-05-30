# Skill Selection Sheet Improvements — Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Add star/favorite with pin-to-top, remove right-side Switch, and fix the bug where clicking a skill doesn't insert `/skill-name` into the chat input.

**Architecture:** Add a `starred` column to the existing `skills` SQLite table via migration. Extend `SkillDao` and `SkillNotifier` with star state. In the UI, replace the `Switch` with a star icon, change row `onTap` to insert skill name into input and close the sheet, and sort starred items to the top.

**Tech Stack:** Flutter, Dart, Riverpod, sqflite, `build_runner` for code generation

---

### Task 1: Database schema migration — add `starred` column

**Files:**
- Modify: `lib/database/database_helper.dart`

- [ ] **Step 1: Bump DB version and add migration**

In `lib/database/database_helper.dart`:

Change `_dbVersion` from 4 to 5:

```dart
static const int _dbVersion = 5;
```

Add `starred INTEGER NOT NULL DEFAULT 0` to the `_onCreate` skills table definition (after the `enabled` line):

```dart
await db.execute('''
  CREATE TABLE skills (
    name TEXT NOT NULL,
    description TEXT,
    location TEXT NOT NULL DEFAULT '',
    content TEXT NOT NULL DEFAULT '',
    enabled INTEGER NOT NULL DEFAULT 1,
    starred INTEGER NOT NULL DEFAULT 0,
    updated_at INTEGER NOT NULL,
    PRIMARY KEY (name)
  )
''');
```

Add a new migration block at the end of `_onUpgrade`:

```dart
if (oldVersion < 5) {
  await db.execute(
    'ALTER TABLE skills ADD COLUMN starred INTEGER NOT NULL DEFAULT 0',
  );
}
```

- [ ] **Step 2: Verify no analysis errors**

Run: `dart analyze lib/database/database_helper.dart`
Expected: No errors

- [ ] **Step 3: Commit**

```bash
git add lib/database/database_helper.dart
git commit -m "feat(db): add starred column to skills table (migration v4→v5)"
```

---

### Task 2: Extend SkillDao with star methods

**Files:**
- Modify: `lib/database/dao/skill_dao.dart`

- [ ] **Step 1: Add static constant and three methods**

Add a static constant for the new column at the top of `SkillDao`:

```dart
static const String columnStarred = 'starred';
```

Add these three methods after `setSkillEnabled`:

```dart
/// Returns whether a skill is starred.
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

/// Set or clear the starred flag for a skill.
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

/// Returns only starred skills.
Future<List<Skill>> getStarredSkills() async {
  final result = await db.query(
    tableName,
    where: '$columnStarred = ?',
    whereArgs: [1],
  );
  return result.map(_rowToSkill).toList();
}
```

- [ ] **Step 2: Verify no analysis errors**

Run: `dart analyze lib/database/dao/skill_dao.dart`
Expected: No errors

- [ ] **Step 3: Commit**

```bash
git add lib/database/dao/skill_dao.dart
git commit -m "feat(dao): add starred query and mutation methods to SkillDao"
```

---

### Task 3: Extend SkillRecord and SkillNotifier with star state

**Files:**
- Modify: `lib/providers/skill_provider.dart`

- [ ] **Step 1: Add `starred` to `SkillRecord`**

Update the `SkillRecord` class:

```dart
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
```

- [ ] **Step 2: Update `_loadWithEnabledState` → rename to `_loadWithLocalState` and load starred**

Rename the method and update its body:

```dart
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
```

Update all call sites of `_loadWithEnabledState` to `_loadWithLocalState` (there are 3: in `build()`, `_syncFromServer`, and `_updateStateFromCache`).

- [ ] **Step 3: Add `toggleStar` method to `SkillNotifier`**

Add after `setSkillEnabled`:

```dart
/// Toggle a skill's starred state.
Future<void> toggleStar(String name) async {
  final dao = await ref.read(skillDaoProvider.future);
  final currentStarred = await dao.isSkillStarred(name);
  await dao.setSkillStarred(name, !currentStarred);
  await _updateStateFromCache(dao);
}
```

- [ ] **Step 4: Regenerate provider code**

Run: `dart run build_runner build --delete-conflicting-outputs`
Expected: Success, `skill_provider.g.dart` regenerated

- [ ] **Step 5: Verify no analysis errors**

Run: `dart analyze lib/providers/skill_provider.dart`
Expected: No errors

- [ ] **Step 6: Commit**

```bash
git add lib/providers/skill_provider.dart lib/providers/skill_provider.g.dart
git commit -m "feat(provider): add starred field to SkillRecord and toggleStar to SkillNotifier"
```

---

### Task 4: UI — Remove Switch, add star icon, fix onTap, sort by star

**Files:**
- Modify: `lib/widgets/message/chat_input.dart`

- [ ] **Step 1: Add `onSkillTap` callback to `_SkillSelectionSheet`**

Change the class signature from:

```dart
class _SkillSelectionSheet extends ConsumerStatefulWidget {
  const _SkillSelectionSheet();
```

to:

```dart
class _SkillSelectionSheet extends ConsumerStatefulWidget {
  final ValueChanged<Skill>? onSkillTap;

  const _SkillSelectionSheet({this.onSkillTap});
```

- [ ] **Step 2: Update `_showSkillSelector` to pass callback**

Change `_showSkillSelector` from:

```dart
void _showSkillSelector() {
  showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Theme.of(
      context,
    ).colorScheme.surface.withValues(alpha: 0),
    builder: (context) => const _SkillSelectionSheet(),
  );
}
```

to:

```dart
void _showSkillSelector() {
  showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Theme.of(
      context,
    ).colorScheme.surface.withValues(alpha: 0),
    builder: (context) => _SkillSelectionSheet(
      onSkillTap: (skill) {
        _controller.value = TextEditingValue(
          text: '/${skill.name} ',
          selection: TextSelection.collapsed(
            offset: 1 + skill.name.length + 1,
          ),
        );
        Navigator.of(context).pop();
        _focusNode.requestFocus();
      },
    ),
  );
}
```

- [ ] **Step 3: Sort skills — starred first, then alphabetical**

In the `data:` callback of `skillsAsync.when`, after the search filter and before the empty check, add sorting:

```dart
data: (skills) {
  var filtered = skills;
  if (_searchQuery.isNotEmpty) {
    filtered = skills
        .where(
          (s) =>
              s.skill.name.toLowerCase().contains(
                _searchQuery,
              ) ||
              (s.skill.description?.toLowerCase().contains(
                    _searchQuery,
                  ) ??
                  false),
        )
        .toList();
  }

  // Sort: starred first, then alphabetical by name.
  filtered = List<SkillRecord>.from(filtered)
    ..sort((a, b) {
      if (a.starred != b.starred) {
        return a.starred ? -1 : 1;
      }
      return a.skill.name.compareTo(b.skill.name);
    });

  if (filtered.isEmpty) {
    // ... existing empty state
  }
```

- [ ] **Step 4: Replace Switch with star icon, fix row onTap**

Replace the entire `InkWell` child `Container` in the skill list item builder (the part inside `itemBuilder` that currently has `onTap: () { ref.read(skillProvider.notifier).toggleSkill(skill.name); }` and the `Switch` widget).

Replace from `InkWell(` through the closing of the `InkWell`, with:

```dart
InkWell(
  onTap: () {
    widget.onSkillTap?.call(skill);
  },
  borderRadius: BorderRadius.circular(tokens.radiusM),
  splashColor: theme.colorScheme.primary.withValues(
    alpha: 0.08,
  ),
  highlightColor: theme.colorScheme.primary
      .withValues(alpha: 0.05),
  child: Container(
    padding: const EdgeInsets.symmetric(
      horizontal: 12,
      vertical: 10,
    ),
    child: Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment:
                CrossAxisAlignment.start,
            children: [
              Text(
                '/${skill.name}',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: record.starred
                      ? FontWeight.w700
                      : FontWeight.w600,
                  color: record.starred
                      ? theme.colorScheme.primary
                      : theme.colorScheme.onSurface,
                ),
              ),
              if (skill.description != null &&
                  skill.description!.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(
                    top: 2,
                  ),
                  child: Text(
                    skill.description!,
                    style: TextStyle(
                      fontSize: 13,
                      color: tokens.mutedForeground,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
            ],
          ),
        ),
        const SizedBox(width: 8),
        GestureDetector(
          onTap: () {
            ref
                .read(skillProvider.notifier)
                .toggleStar(skill.name);
          },
          behavior: HitTestBehavior.opaque,
          child: Padding(
            padding: const EdgeInsets.all(4),
            child: Icon(
              record.starred
                  ? Icons.star
                  : Icons.star_border,
              size: 20,
              color: record.starred
                  ? theme.colorScheme.primary
                  : tokens.mutedForeground,
            ),
          ),
        ),
      ],
    ),
  ),
),
```

Key changes:
- Row `onTap` → calls `widget.onSkillTap?.call(skill)` instead of `toggleSkill`
- `Switch` replaced with star `GestureDetector` + `Icon`
- Star tap calls `toggleStar` without closing the sheet
- Background color of `Material` simplified (no more `isEnabled` distinction — starred state drives styling)

Also update the `Material` color to remove the `isEnabled`-based coloring:

```dart
Material(
  color: tokens.card.withValues(alpha: 0.5),
  borderRadius: BorderRadius.circular(tokens.radiusM),
```

- [ ] **Step 5: Verify no analysis errors**

Run: `dart analyze lib/widgets/message/chat_input.dart`
Expected: No errors

- [ ] **Step 6: Commit**

```bash
git add lib/widgets/message/chat_input.dart
git commit -m "feat(ui): add star/favorite to skill sheet, remove switch, fix onTap to insert skill name"
```

---

### Task 5: Final verification — build, analyze, test

**Files:**
- All changed files

- [ ] **Step 1: Run code generation**

Run: `dart run build_runner build --delete-conflicting-outputs`
Expected: Success

- [ ] **Step 2: Format code**

Run: `dart format .`
Expected: No changes or formatting applied

- [ ] **Step 3: Run static analysis**

Run: `flutter analyze`
Expected: No errors or warnings in changed files

- [ ] **Step 4: Run tests**

Run: `flutter test`
Expected: All existing tests pass

- [ ] **Step 5: Commit any formatting changes**

```bash
git add -A
git commit -m "chore: format and verify after skill selection improvements"
```

---

## Self-Review Checklist

- [x] **Spec coverage:** Task 1 covers DB schema, Task 2 covers DAO, Task 3 covers provider, Task 4 covers UI, Task 5 covers verification
- [x] **Placeholder scan:** No TBD/TODO/placeholders — all code is explicit
- [x] **Type consistency:** `SkillRecord.starred` is `bool`, DAO uses `INTEGER 0/1`, provider reads as `== 1`, UI checks `record.starred`
