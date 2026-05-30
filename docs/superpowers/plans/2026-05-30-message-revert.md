# Message Revert Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Wire the existing backend revert/unrevert APIs into the Flutter client with a revert button on each user message and a reverted-session banner.

**Architecture:** No optimistic updates. Call `SessionApi.revertMessage()` / `unrevertSession()`, then let SSE events (`message.removed`, `session.updated`) drive UI state through existing reducers. Add a `currentSessionRevertProvider` to expose revert state for the banner.

**Tech Stack:** Flutter, Riverpod (riverpod_annotation + codegen), existing SessionApi, existing l10n (.arb) system.

---

## File Structure

| File | Responsibility |
|------|---------------|
| `lib/providers/session_provider.dart` | Add `revertToMessage()` + `unrevertSession()` methods to notifiers; add `currentSessionRevertProvider` |
| `lib/widgets/message/message_bubble.dart` | Add revert button to `_UserFooter`; add confirmation dialog |
| `lib/widgets/message/message_list.dart` | Add `RevertedBanner` above message list; pass revert state down |
| `lib/l10n/app_en.arb` | English strings for revert UI |
| `lib/l10n/app_zh.arb` | Chinese strings for revert UI |

---

### Task 1: Add l10n strings for revert

**Files:**
- Modify: `lib/l10n/app_en.arb`
- Modify: `lib/l10n/app_zh.arb`

- [ ] **Step 1: Add English strings to `app_en.arb`**

Append after the last entry in `lib/l10n/app_en.arb`:

```json
"revertToHere": "Revert to here",
"@revertToHere": {},
"revertConfirmTitle": "Revert to here",
"@revertConfirmTitle": {},
"revertConfirmBody": "This will remove all messages after this point. Continue?",
"@revertConfirmBody": {},
"revertConfirmAction": "Revert",
"@revertConfirmAction": {},
"revertCancel": "Cancel",
"@revertCancel": {},
"revertBannerText": "Reverted · Messages after this point have been removed",
"@revertBannerText": {},
"revertRestore": "Restore",
"@revertRestore": {},
"revertFailed": "Revert failed: {error}",
"@revertFailed": {
  "placeholders": {
    "error": {
      "type": "String"
    }
  }
},
"unrevertFailed": "Restore failed: {error}",
"@unrevertFailed": {
  "placeholders": {
    "error": {
      "type": "String"
    }
  }
}
```

- [ ] **Step 2: Add Chinese strings to `app_zh.arb`**

Append after the last entry in `lib/l10n/app_zh.arb`:

```json
"revertToHere": "回退到此处",
"@revertToHere": {},
"revertConfirmTitle": "回退到此处",
"@revertConfirmTitle": {},
"revertConfirmBody": "此操作将移除该消息之后的所有消息，是否继续？",
"@revertConfirmBody": {},
"revertConfirmAction": "回退",
"@revertConfirmAction": {},
"revertCancel": "取消",
"@revertCancel": {},
"revertBannerText": "已回退 · 之后的消息已移除",
"@revertBannerText": {},
"revertRestore": "恢复",
"@revertRestore": {},
"revertFailed": "回退失败：{error}",
"@revertFailed": {
  "placeholders": {
    "error": {
      "type": "String"
    }
  }
},
"unrevertFailed": "恢复失败：{error}",
"@unrevertFailed": {
  "placeholders": {
    "error": {
      "type": "String"
    }
  }
}
```

- [ ] **Step 3: Regenerate l10n**

Run: `flutter gen-l10n`

Expected: no errors, `app_localizations_en.dart` and `app_localizations_zh.dart` contain the new getters.

- [ ] **Step 4: Verify build**

Run: `flutter analyze`

Expected: no new errors.

- [ ] **Step 5: Commit**

```bash
git add lib/l10n/
git commit -m "feat(revert): add l10n strings for message revert"
```

---

### Task 2: Add provider methods for revert/unrevert

**Files:**
- Modify: `lib/providers/session_provider.dart`

- [ ] **Step 1: Add `revertToMessage` to `SessionMessagesNotifier`**

In `lib/providers/session_provider.dart`, add the following method to `SessionMessagesNotifier` (after `appendPartDelta`, before `_currentMessages` getter):

```dart
  /// 回退到指定消息：调用后端 revert API，不做本地状态变更，等 SSE 驱动
  Future<void> revertToMessage(String messageID) async {
    final api = await ref.read(sessionApiProvider.future);
    final directory = ref.read(currentDirectoryProvider);
    await api.revertMessage(
      sessionID,
      data: {'messageID': messageID},
      directory: directory,
    );
    ref.invalidate(sessionDiffProvider(sessionID));
    ref.invalidate(sessionTodosProvider(sessionID));
  }
```

- [ ] **Step 2: Add `revertToMessage` to `SubSessionMessagesNotifier`**

In the same file, add the same method to `SubSessionMessagesNotifier` (after `appendPartDelta`, before `_currentMessages` getter):

```dart
  Future<void> revertToMessage(String messageID) async {
    final api = await ref.read(sessionApiProvider.future);
    final directory = ref.read(currentDirectoryProvider);
    await api.revertMessage(
      sessionID,
      data: {'messageID': messageID},
      directory: directory,
    );
    ref.invalidate(sessionDiffProvider(sessionID));
    ref.invalidate(sessionTodosProvider(sessionID));
  }
```

- [ ] **Step 3: Add `currentSessionRevertProvider`**

At the end of `lib/providers/session_provider.dart` (after the `_normalizeParts` function), add:

```dart
@riverpod
SessionRevert? currentSessionRevert(Ref ref) {
  final sessionId = ref.watch(
    chatViewStateProvider.select((s) => s.sessionId),
  );
  if (sessionId == null) return null;
  final sessions = ref.watch(sessionsProvider).asData?.value;
  if (sessions == null) return null;
  try {
    return sessions.firstWhere((s) => s.id == sessionId).revert;
  } catch (_) {
    return null;
  }
}
```

This requires adding imports at the top of the file:

```dart
import 'chat_view_state_provider.dart';
```

- [ ] **Step 4: Regenerate Riverpod code**

Run: `dart run build_runner build --delete-conflicting-outputs`

Expected: `session_provider.g.dart` is regenerated with `currentSessionRevertProvider`.

- [ ] **Step 5: Verify build**

Run: `dart format . && flutter analyze`

Expected: no errors.

- [ ] **Step 6: Commit**

```bash
git add lib/providers/session_provider.dart lib/providers/session_provider.g.dart
git commit -m "feat(revert): add revertToMessage and currentSessionRevertProvider"
```

---

### Task 3: Add revert button to UserMessage footer

**Files:**
- Modify: `lib/widgets/message/message_bubble.dart`

- [ ] **Step 1: Add new fields to `MessageBubble`**

Add `sessionID`, `isWorking`, and `isReverted` parameters to `MessageBubble`:

```dart
class MessageBubble extends ConsumerStatefulWidget {
  final MessageWithParts messageWithParts;
  final bool prevIsUser;
  final bool isLatestMessage;
  final String? sessionID;
  final bool isWorking;
  final bool isReverted;
  final void Function(String sessionId)? onNavigateToSubSession;

  const MessageBubble({
    super.key,
    required this.messageWithParts,
    required this.prevIsUser,
    this.isLatestMessage = false,
    this.sessionID,
    this.isWorking = false,
    this.isReverted = false,
    this.onNavigateToSubSession,
  });
```

- [ ] **Step 2: Add `_isLatestUserMessage` helper to `_MessageBubbleState`**

Add a getter to determine if this is the latest user message (needed for revert button visibility):

```dart
  bool get _isLatestUserMessage {
    return widget.isLatestMessage && widget.messageWithParts.info is UserMessage;
  }
```

- [ ] **Step 3: Add revert confirmation dialog method**

Add to `_MessageBubbleState`:

```dart
  Future<void> _showRevertDialog() async {
    final userMessage = widget.messageWithParts.info;
    if (userMessage is! UserMessage) return;
    final sessionId = widget.sessionID;
    if (sessionId == null) return;

    final l10n = context.l10n;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l10n.revertConfirmTitle),
        content: Text(l10n.revertConfirmBody),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: Text(l10n.revertCancel),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: Text(l10n.revertConfirmAction),
          ),
        ],
      ),
    );

    if (confirmed != true || !mounted) return;

    try {
      await ref
          .read(sessionMessagesProvider(sessionId).notifier)
          .revertToMessage(userMessage.id);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(context.l10n.revertFailed(e.toString()))),
        );
      }
    }
  }
```

This requires adding imports at the top of `message_bubble.dart`:

```dart
import '../../providers/session_provider.dart';
import '../../providers/session_status_provider.dart';
```

- [ ] **Step 4: Pass revert callback and visibility to `_UserFooter`**

Modify the `_buildUserBubble` method to pass the new props to `_UserFooter`. Change the `_UserFooter` call:

```dart
              _UserFooter(
                message: userMessage,
                agentLabel: _formatAgentLabel(userMessage.agent),
                modelLabel: modelLabel,
                copied: _copied,
                onCopy: _copyMessage,
                showCopy: _hasTextContent,
                showRevert: !widget.isWorking &&
                    !widget.isReverted &&
                    !_isLatestUserMessage,
                onRevert: _showRevertDialog,
              ),
```

- [ ] **Step 5: Add revert button to `_UserFooter`**

Update `_UserFooter` class to accept and render the revert button:

```dart
class _UserFooter extends StatelessWidget {
  final UserMessage message;
  final String agentLabel;
  final String modelLabel;
  final bool copied;
  final VoidCallback onCopy;
  final bool showCopy;
  final bool showRevert;
  final VoidCallback onRevert;

  const _UserFooter({
    required this.message,
    required this.agentLabel,
    required this.modelLabel,
    required this.copied,
    required this.onCopy,
    required this.showCopy,
    required this.showRevert,
    required this.onRevert,
  });
```

In the `build` method, add the revert button in the `Row`, before the time label:

```dart
    return DefaultTextStyle(
      style: TextStyle(fontSize: 12, color: tokens.mutedForeground),
      child: Align(
        alignment: Alignment.centerRight,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (showRevert) ...[
              GestureDetector(
                onTap: onRevert,
                child: Icon(
                  Icons.restore_outlined,
                  size: 14,
                  color: tokens.mutedForeground,
                ),
              ),
              const SizedBox(width: 8),
            ],
            ConstrainedBox(
              constraints: BoxConstraints(maxWidth: maxModelWidth),
              child: Text(
                modelAndAgentLabel,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.right,
              ),
            ),
            const SizedBox(width: 8),
            Text(timeLabel),
            if (showCopy) ...[
              const SizedBox(width: 12),
              _CopyButton(copied: copied, onCopy: onCopy),
            ],
          ],
        ),
      ),
    );
```

- [ ] **Step 6: Verify build**

Run: `dart format . && flutter analyze`

Expected: no errors.

- [ ] **Step 7: Commit**

```bash
git add lib/widgets/message/message_bubble.dart
git commit -m "feat(revert): add revert button to UserMessage footer"
```

---

### Task 4: Add reverted-session banner to MessageList

**Files:**
- Modify: `lib/widgets/message/message_list.dart`

- [ ] **Step 1: Add `RevertedBanner` widget**

Add the following widget at the end of `lib/widgets/message/message_list.dart` (before the file-level helper functions):

```dart
class RevertedBanner extends ConsumerWidget {
  final String sessionID;

  const RevertedBanner({super.key, required this.sessionID});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final revert = ref.watch(currentSessionRevertProvider);
    if (revert == null) return const SizedBox.shrink();

    final tokens = context.tokens;
    final l10n = context.l10n;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: tokens.info.withValues(alpha: 0.15),
        border: Border(
          bottom: BorderSide(color: tokens.border.withValues(alpha: 0.5)),
        ),
      ),
      child: Row(
        children: [
          Icon(Icons.info_outline, size: 16, color: tokens.mutedForeground),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              l10n.revertBannerText,
              style: TextStyle(fontSize: 13, color: tokens.mutedForeground),
            ),
          ),
          const SizedBox(width: 8),
          TextButton(
            onPressed: () => _handleUnrevert(ref),
            style: TextButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              minimumSize: Size.zero,
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
            child: Text(
              l10n.revertRestore,
              style: TextStyle(fontSize: 13, color: tokens.accent),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _handleUnrevert(WidgetRef ref) async {
    try {
      final api = await ref.read(sessionApiProvider.future);
      final directory = ref.read(currentDirectoryProvider);
      await api.unrevertSession(sessionID, directory: directory);
      ref.invalidate(sessionDiffProvider(sessionID));
      ref.invalidate(sessionTodosProvider(sessionID));
      ref.invalidate(sessionsProvider);
    } catch (e) {
      // Unrevert errors are shown via SnackBar if a context is available.
      // Since this is a ConsumerWidget, we rely on the caller to handle.
    }
  }
}
```

This requires adding imports at the top of `message_list.dart`:

```dart
import '../../providers/chat_view_state_provider.dart';
import '../../service/api/session_api.dart';
import '../../service/api/models/session.dart' show SessionRevert;
import '../../providers/current_directory_provider.dart';
```

- [ ] **Step 2: Integrate `RevertedBanner` into `MessageList`**

Modify the `MessageList.build` method to include the banner above the message body:

```dart
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final messagesAsync = ref.watch(sessionMessagesProvider(sessionID));
    final l10n = context.l10n;

    return messagesAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, stack) {
        if (kDebugMode) {
          debugPrint('MessageList Error: $error\n$stack');
        }
        return MessageErrorState(message: l10n.messageListLoadFailed);
      },
      data: (messages) => Column(
        children: [
          RevertedBanner(sessionID: sessionID),
          Expanded(
            child: _MessageListBody(
              messages: messages,
              onNavigateToSubSession: onNavigateToSubSession,
            ),
          ),
        ],
      ),
    );
  }
```

- [ ] **Step 3: Pass `sessionID`, `isWorking`, `isReverted` to `MessageBubble`**

In `_MessageListViewState.build`, update the `MessageBubble` instantiation. First, the widget needs access to these values. Add them as fields to `MessageListView`:

```dart
class MessageListView extends StatefulWidget {
  final List<MessageWithParts> messages;
  final void Function(String sessionId)? onNavigateToSubSession;
  final String? sessionID;
  final bool isWorking;
  final bool isReverted;
  final double bottomDetachedThreshold;
  final Duration scrollToBottomAnimationDuration;

  const MessageListView({
    super.key,
    required this.messages,
    this.onNavigateToSubSession,
    this.sessionID,
    this.isWorking = false,
    this.isReverted = false,
    this.bottomDetachedThreshold = 72,
    this.scrollToBottomAnimationDuration = const Duration(milliseconds: 220),
  });
```

Update `_MessageListBody` to pass these through:

```dart
class _MessageListBody extends StatelessWidget {
  final List<MessageWithParts> messages;
  final void Function(String sessionId)? onNavigateToSubSession;
  final String? sessionID;
  final bool isWorking;
  final bool isReverted;

  const _MessageListBody({
    required this.messages,
    this.onNavigateToSubSession,
    this.sessionID,
    this.isWorking = false,
    this.isReverted = false,
  });

  @override
  Widget build(BuildContext context) => MessageListView(
    messages: messages,
    onNavigateToSubSession: onNavigateToSubSession,
    sessionID: sessionID,
    isWorking: isWorking,
    isReverted: isReverted,
  );
}
```

Update the `MessageList.build` to pass these values:

```dart
      data: (messages) => Column(
        children: [
          RevertedBanner(sessionID: sessionID),
          Expanded(
            child: _MessageListBody(
              messages: messages,
              onNavigateToSubSession: onNavigateToSubSession,
              sessionID: sessionID,
              isWorking: ref.watch(sessionStatusProvider).isWorking(sessionID),
              isReverted: ref.watch(currentSessionRevertProvider) != null,
            ),
          ),
        ],
      ),
```

This requires adding imports:

```dart
import '../../providers/session_status_provider.dart';
```

Update the `MessageBubble` instantiation inside `_MessageListViewState.build`:

```dart
              return MessageBubble(
                key: ValueKey(_messageId(messageWithParts)),
                messageWithParts: messageWithParts,
                prevIsUser: prevIsUser,
                isLatestMessage: index == 0,
                sessionID: widget.sessionID,
                isWorking: widget.isWorking,
                isReverted: widget.isReverted,
                onNavigateToSubSession: widget.onNavigateToSubSession,
              );
```

- [ ] **Step 4: Update `home_page.dart` to pass sessionID to MessageList**

Find where `MessageList` is constructed in `lib/pages/home_page.dart` and verify it already passes `sessionID`. If it does, no change needed. If not, add the `sessionID` parameter.

- [ ] **Step 5: Verify build**

Run: `dart format . && flutter analyze`

Expected: no errors.

- [ ] **Step 6: Commit**

```bash
git add lib/widgets/message/message_list.dart lib/pages/home_page.dart
git commit -m "feat(revert): add reverted-session banner to MessageList"
```

---

### Task 5: Run full CI verification

**Files:** None (verification only)

- [ ] **Step 1: Run build_runner**

Run: `dart run build_runner build --delete-conflicting-outputs`

Expected: no errors, all `.g.dart` files up to date.

- [ ] **Step 2: Format and analyze**

Run: `dart format . && flutter analyze`

Expected: no errors.

- [ ] **Step 3: Run tests**

Run: `flutter test`

Expected: all existing tests pass (no regressions).

- [ ] **Step 4: Final commit if any formatting changes**

```bash
git add -A
git diff --cached --quiet || git commit -m "chore: format and fix after revert feature"
```
