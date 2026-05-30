# Message Revert Feature Design

## Summary

Allow users to revert a chat session to any earlier user message, removing all messages after that point. The backend already provides `POST /session/:id/revert` and `POST /session/:id/unrevert` APIs; this spec covers the Flutter client wiring only.

## Scope

- Revert to any user message via a revert button on each user message bubble
- Confirmation dialog before executing revert
- Reverted-session banner with "restore" (unrevert) action
- Provider-layer method to call revert/unrevert APIs
- Invalidation of dependent providers after revert

Out of scope: backend API changes, optimistic UI updates, sub-session revert (read-only).

## Architecture & Data Flow

```
User taps ↩ on a UserMessage
  -> Confirmation dialog
  -> SessionApi.revertMessage(sessionID, data: {messageID}, directory)
  -> Backend processes revert, emits SSE events:
      - message.removed x N (for each removed message)
      - session.updated  (Session.revert field set)
  -> Existing SSE handlers process these events:
      - _MessageGlobalEventHandler handles message.removed
      - _SessionGlobalEventHandler invalidates sessionsProvider
  -> UI updates reactively via Riverpod
```

**Key principle: no optimistic updates.** The revert API triggers server-side git/file operations with latency. Existing SSE-driven reducers (`MessageListStateReducer.removeMessage`) naturally trim the message list. This avoids rollback complexity in the client.

## Provider Changes

### `lib/providers/session_provider.dart`

Add `revertToMessage` method to `SessionMessagesNotifier`:

```dart
Future<void> revertToMessage(String messageID) async {
  final api = await ref.read(sessionApiProvider.future);
  final directory = ref.read(currentDirectoryProvider);
  await api.revertMessage(
    sessionID,
    data: {'messageID': messageID},
    directory: directory,
  );
  // Invalidate dependent providers
  ref.invalidate(sessionDiffProvider(sessionID));
  ref.invalidate(sessionTodosProvider(sessionID));
}
```

Same method on `SubSessionMessagesNotifier` (optional, sub-sessions are read-only but revert may still be useful).

### `lib/providers/session_provider.dart` — new provider

Add a provider to watch the current session's revert state:

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

### Invalidation after revert

After `revertToMessage` succeeds, invalidate:
- `sessionDiffProvider(sessionID)` — diff may change
- `sessionTodosProvider(sessionID)` — todos may be cleared
- `sessionsProvider` — session.revert field updated (already invalidated by SSE `session.updated`)

### Unrevert action

Add to `SessionApi` usage — call existing `api.unrevertSession(sessionID, directory)` and invalidate the same providers.

## UI Changes

### 1. Revert button on UserMessage (`lib/widgets/message/message_bubble.dart`)

**Location:** In `_UserFooter` Row, before the time label.

**Button spec:**
- Icon: `Icons.restore_outlined` (or similar ↩ icon), size 14
- Color: `tokens.mutedForeground`
- Tooltip: '回退到此处'
- On tap: show confirmation dialog, then call revert

**Visibility conditions:**
- Only on `UserMessage` (not on assistant messages)
- Session is not busy (`sessionStatus.isWorking == false`)
- Not the latest user message in the list (reverting to the latest is a no-op)
- Session is not already in a reverted state (`session.revert == null`)

### 2. Confirmation dialog

Standard `AlertDialog`:
- Title: '回退到此处'
- Body: '此操作将移除该消息之后的所有消息，是否继续？'
- Actions: '取消' (dismiss) / '回退' (destructive, calls revert)

### 3. Reverted-session banner

When `currentSessionRevertProvider` is non-null, show a banner above the message list:

**Location:** In `MessageList` widget, above the `Stack` containing the `ListView`.

**Banner spec:**
- Background: `tokens.info` with low opacity
- Content: Row with icon `Icons.info_outline`, text '已回退 · 之后的消息已移除', and a '恢复' text button
- Border: bottom border `tokens.border`
- The '恢复' button calls `api.unrevertSession(sessionID, directory: directory)` and invalidates providers

## Files to Modify

| File | Change |
|------|--------|
| `lib/providers/session_provider.dart` | Add `revertToMessage()` to both notifiers; add `currentSessionRevertProvider` |
| `lib/widgets/message/message_bubble.dart` | Add revert button to `_UserFooter`; pass sessionID, isWorking, isReverted props |
| `lib/widgets/message/message_list.dart` | Add reverted-session banner; pass additional state to `MessageListView` |
| `lib/l10n/app_localizations_en.dart` | Add revert-related strings |
| `lib/l10n/app_localizations_zh.dart` | Add revert-related strings |

## Edge Cases

1. **Revert while session is busy** — button hidden/disabled. The user must wait for the current operation to complete or abort first.
2. **Revert on an already-reverted session** — revert button hidden; only the "restore" (unrevert) button is visible in the banner.
3. **Revert the latest message** — button not shown (no-op).
4. **Network failure during revert** — catch exception, show SnackBar error. State remains unchanged.
5. **SSE events arrive out of order** — existing `MessageListStateReducer` is idempotent (removeMessage on non-existent ID is a no-op).
6. **Sub-session revert** — out of scope for this iteration. Sub-sessions are read-only.
7. **Session deleted after revert** — handled by existing `_SessionGlobalEventHandler` which invalidates `sessionsProvider`.

## Testing

- Unit test `SessionMessagesNotifier.revertToMessage()` — verify API is called with correct args, providers are invalidated
- Unit test `currentSessionRevertProvider` — verify it reads from sessions list correctly
- Widget test `MessageBubble` — verify revert button visibility conditions
- Widget test revert confirmation dialog — verify dialog appears and revert is called on confirm
- Widget test reverted banner — verify banner appears when `currentSessionRevertProvider` is non-null
