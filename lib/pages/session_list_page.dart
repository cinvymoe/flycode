import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../l10n/l10n.dart';
import '../models/chat_route_args.dart';
import '../providers/current_directory_provider.dart';
import '../providers/home_page_provider.dart';
import '../providers/permission_provider.dart';
import '../providers/session_status_provider.dart';
import '../providers/session_unread_provider.dart';
import '../service/api/models/permission.dart';
import '../service/api/models/session.dart';
import '../service/api/models/session_status.dart';
import '../service/api/session_api.dart';
import '../theme/app_tokens.dart';

String _projectNameFromDirectory(String directory) {
  final parts = directory.replaceAll('\\', '/').split('/');
  return parts.lastWhere((p) => p.isNotEmpty, orElse: () => directory);
}

// ---------------------------------------------------------------------------
// Badge logic (copied from chat_input.dart _SessionHistorySheet)
// ---------------------------------------------------------------------------

enum _SessionListBadgeKind { none, working, permission, error, unread }

bool _hasPendingPermission(
  String sessionID,
  List<PermissionRequest> pendingPermissions,
  List<Session> allSessions,
) {
  if (pendingPermissions.isEmpty) return false;
  final subtree = collectSessionTree(sessionID, allSessions);
  for (final request in pendingPermissions) {
    if (subtree.contains(request.sessionID)) return true;
  }
  return false;
}

_SessionListBadgeKind _resolveBadgeKind(
  String sessionID,
  Map<String, SessionStatus> sessionStatuses,
  SessionUnreadState unreadState,
  List<PermissionRequest> pendingPermissions,
  List<Session> allSessions,
) {
  final status = sessionStatuses[sessionID];
  if (status != null && status.isWorking) {
    return _SessionListBadgeKind.working;
  }
  if (_hasPendingPermission(sessionID, pendingPermissions, allSessions)) {
    return _SessionListBadgeKind.permission;
  }
  if (unreadState.hasError(sessionID)) {
    return _SessionListBadgeKind.error;
  }
  if (unreadState.unseenCount(sessionID) > 0) {
    return _SessionListBadgeKind.unread;
  }
  return _SessionListBadgeKind.none;
}

Widget _buildStatusBadge(BuildContext context, _SessionListBadgeKind kind) {
  final tokens = context.tokens;
  final theme = Theme.of(context);
  switch (kind) {
    case _SessionListBadgeKind.working:
      return SizedBox(
        width: 14,
        height: 14,
        child: CircularProgressIndicator(
          strokeWidth: 1.8,
          color: tokens.successForeground,
        ),
      );
    case _SessionListBadgeKind.permission:
      return Container(
        width: 8,
        height: 8,
        decoration: BoxDecoration(
          color: tokens.warningForeground,
          shape: BoxShape.circle,
        ),
      );
    case _SessionListBadgeKind.error:
      return Container(
        width: 8,
        height: 8,
        decoration: BoxDecoration(
          color: theme.colorScheme.error,
          shape: BoxShape.circle,
        ),
      );
    case _SessionListBadgeKind.unread:
      return Container(
        width: 8,
        height: 8,
        decoration: BoxDecoration(
          color: theme.colorScheme.primary,
          shape: BoxShape.circle,
        ),
      );
    case _SessionListBadgeKind.none:
      return const SizedBox.shrink();
  }
}

// ---------------------------------------------------------------------------
// Date grouping helpers (copied from chat_input.dart private functions)
// ---------------------------------------------------------------------------

Map<String, List<Session>> _groupSessionsByDate(List<Session> sessions) {
  final grouped = <String, List<Session>>{};
  final sorted = List<Session>.from(sessions)
    ..sort((a, b) => (b.updatedAt ?? 0).compareTo(a.updatedAt ?? 0));

  for (final session in sorted) {
    final key = _dateKey(session.updatedAt);
    grouped.putIfAbsent(key, () => []).add(session);
  }
  return grouped;
}

String _dateKey(int? timestamp) {
  if (timestamp == null || timestamp == 0) {
    final now = DateTime.now();
    return '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
  }
  final dt = DateTime.fromMillisecondsSinceEpoch(timestamp);
  return '${dt.year}-${dt.month.toString().padLeft(2, '0')}-${dt.day.toString().padLeft(2, '0')}';
}

String _formatDateHeader(BuildContext context, String dateKey) {
  final l10n = context.l10n;
  final now = DateTime.now();
  final today = DateTime(now.year, now.month, now.day);
  final yesterday = today.subtract(const Duration(days: 1));

  DateTime parseDate(String key) {
    final parts = key.split('-');
    if (parts.length < 3) return today;
    return DateTime(
      int.parse(parts[0]),
      int.parse(parts[1]),
      int.parse(parts[2]),
    );
  }

  final date = parseDate(dateKey);
  if (date == today) return l10n.chatInputToday;
  if (date == yesterday) return l10n.chatInputYesterday;

  final parts = dateKey.split('-');
  if (parts.length < 3) return dateKey;
  final month = int.tryParse(parts[1]) ?? 1;
  final day = int.tryParse(parts[2]) ?? 1;
  return l10n.chatInputMonthDay(month, day);
}

String _formatUpdatedTime(BuildContext context, int? timestampMs) {
  final l10n = context.l10n;
  if (timestampMs == null || timestampMs == 0) return l10n.chatInputJustNow;

  final dt = DateTime.fromMillisecondsSinceEpoch(timestampMs);
  final now = DateTime.now();
  final diff = now.difference(dt);

  if (diff.inMinutes < 1) return l10n.chatInputJustNow;
  if (diff.inMinutes < 60) return l10n.chatInputMinutesAgo(diff.inMinutes);
  if (diff.inHours < 24) return l10n.chatInputHoursAgo(diff.inHours);
  if (diff.inDays < 7) return l10n.chatInputDaysAgo(diff.inDays);

  final y = dt.year;
  final m = dt.month.toString().padLeft(2, '0');
  final d = dt.day.toString().padLeft(2, '0');
  if (dt.year == now.year) return '$m-$d';
  return '$y-$m-$d';
}

// ---------------------------------------------------------------------------
// SessionListPage
// ---------------------------------------------------------------------------

class SessionListPage extends ConsumerStatefulWidget {
  final String directory;

  const SessionListPage({super.key, required this.directory});

  @override
  ConsumerState<SessionListPage> createState() => _SessionListPageState();
}

class _SessionListPageState extends ConsumerState<SessionListPage> {
  @override
  Widget build(BuildContext context) {
    // Ensure currentDirectory is always set to this page's directory.
    // When popping back from /chat, the chat page's PopScope clears
    // currentDirectoryProvider, but initState won't re-run since this
    // page was already mounted underneath. Without this guard,
    // sessionsProvider returns [] because directory is null.
    final currentDir = ref.read(currentDirectoryProvider);
    if (currentDir != widget.directory) {
      Future.microtask(() {
        if (!mounted) return;
        ref.read(currentDirectoryProvider.notifier).set(widget.directory);
      });
    }
    final l10n = context.l10n;
    final colorScheme = Theme.of(context).colorScheme;
    final tokens = context.tokens;
    final pagePadding = tokens.pageHorizontalPadding;
    final projectName = _projectNameFromDirectory(widget.directory);

    final sessionsAsync = ref.watch(sessionsProvider);
    final sessionStatuses = ref.watch(sessionStatusProvider);
    final unreadState = ref.watch(sessionUnreadProvider);
    final pendingPermissions =
        ref.watch(pendingPermissionsProvider).asData?.value ??
        const <PermissionRequest>[];
    final allSessions =
        ref.watch(allSessionsProvider).asData?.value ?? const <Session>[];

    Future<void> refreshSessions() async {
      unawaited(ref.refresh(sessionsProvider.future));
    }

    void openSession(Session session) {
      context.push(
        '/chat',
        extra: ChatRouteArgs(
          directory: widget.directory,
          initialSessionId: session.id,
        ),
      );
    }

    void startNewSession() {
      context.push(
        '/chat',
        extra: ChatRouteArgs(directory: widget.directory, startNew: true),
      );
    }

    return PopScope(
      canPop: true,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) return;
        ref.read(homePageBootstrapControllerProvider.notifier).reset();
      },
      child: Scaffold(
        backgroundColor: colorScheme.surface,
        appBar: AppBar(
          centerTitle: false,
          titleSpacing: 4,
          title: Text(projectName),
          actions: [
            TextButton(
              onPressed: startNewSession,
              style: TextButton.styleFrom(
                foregroundColor: colorScheme.primary,
                minimumSize: const Size(0, 32),
                padding: const EdgeInsets.symmetric(horizontal: 8),
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
              child: Text(
                l10n.sessionListNewSession,
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            const SizedBox(width: 8),
          ],
          bottom: PreferredSize(
            preferredSize: const Size.fromHeight(1),
            child: Container(
              decoration: BoxDecoration(
                border: Border(
                  bottom: BorderSide(
                    color: tokens.border.withValues(alpha: 0.6),
                  ),
                ),
              ),
            ),
          ),
        ),
        body: sessionsAsync.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (error, _) => RefreshIndicator(
            onRefresh: refreshSessions,
            child: ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: EdgeInsets.symmetric(horizontal: pagePadding),
              children: [
                SizedBox(height: MediaQuery.of(context).size.height * 0.2),
                Icon(
                  Icons.error_outline_rounded,
                  size: 44,
                  color: tokens.mutedForeground.withValues(alpha: 0.55),
                ),
                const SizedBox(height: 12),
                Text(
                  '$error',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 13, color: tokens.mutedForeground),
                ),
              ],
            ),
          ),
          data: (sessions) {
            if (sessions.isEmpty) {
              return RefreshIndicator(
                onRefresh: refreshSessions,
                child: ListView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: EdgeInsets.symmetric(horizontal: pagePadding),
                  children: [
                    SizedBox(height: MediaQuery.of(context).size.height * 0.2),
                    Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            width: 72,
                            height: 72,
                            decoration: BoxDecoration(
                              color: tokens.card,
                              borderRadius: BorderRadius.circular(18),
                            ),
                            child: Icon(
                              Icons.chat_bubble_outline_rounded,
                              size: 36,
                              color: tokens.mutedForeground.withValues(
                                alpha: 0.55,
                              ),
                            ),
                          ),
                          const SizedBox(height: 16),
                          Text(
                            l10n.chatInputNoSessions,
                            style: TextStyle(
                              color: tokens.mutedForeground,
                              fontSize: 15,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const SizedBox(height: 14),
                          FilledButton.icon(
                            onPressed: startNewSession,
                            icon: const Icon(Icons.add, size: 18),
                            label: Text(l10n.sessionListNewSession),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              );
            }

            final grouped = _groupSessionsByDate(sessions);
            final dates = grouped.keys.toList();
            final contentBottomPadding =
                MediaQuery.paddingOf(context).bottom + 16;

            return RefreshIndicator(
              onRefresh: refreshSessions,
              child: ListView.builder(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: EdgeInsets.fromLTRB(
                  pagePadding,
                  20,
                  pagePadding,
                  contentBottomPadding,
                ),
                itemCount: dates.length,
                itemBuilder: (context, index) {
                  final date = dates[index];
                  final sessionsForDate = grouped[date]!;

                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Padding(
                        padding: EdgeInsets.only(
                          top: index == 0 ? 0 : 20,
                          bottom: 10,
                        ),
                        child: Text(
                          _formatDateHeader(context, date),
                          style: TextStyle(
                            fontFamily: 'Inter',
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: tokens.mutedForeground,
                          ),
                        ),
                      ),
                      ...sessionsForDate.map((session) {
                        final badgeKind = _resolveBadgeKind(
                          session.id,
                          sessionStatuses,
                          unreadState,
                          pendingPermissions,
                          allSessions,
                        );

                        return Padding(
                          padding: const EdgeInsets.only(bottom: 8),
                          child: Material(
                            color: tokens.card,
                            borderRadius: BorderRadius.circular(
                              tokens.radiusXs,
                            ),
                            child: InkWell(
                              onTap: () => openSession(session),
                              borderRadius: BorderRadius.circular(
                                tokens.radiusXs,
                              ),
                              hoverColor: tokens.accent,
                              child: Padding(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 16,
                                  vertical: 14,
                                ),
                                child: Row(
                                  crossAxisAlignment: CrossAxisAlignment.center,
                                  children: [
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            session.title ?? session.id,
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                            style: TextStyle(
                                              fontFamily: 'Inter',
                                              fontSize: 15,
                                              fontWeight: FontWeight.w600,
                                              color: colorScheme.onSurface,
                                            ),
                                          ),
                                          const SizedBox(height: 3),
                                          Text(
                                            _formatUpdatedTime(
                                              context,
                                              session.updatedAt,
                                            ),
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                            style: TextStyle(
                                              fontFamily: 'Inter',
                                              fontSize: 12,
                                              fontWeight: FontWeight.w500,
                                              color: tokens.mutedForeground,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    if (badgeKind !=
                                        _SessionListBadgeKind.none) ...[
                                      const SizedBox(width: 10),
                                      _buildStatusBadge(context, badgeKind),
                                    ],
                                    const SizedBox(width: 8),
                                    Icon(
                                      Icons.chevron_right_rounded,
                                      size: 18,
                                      color: tokens.mutedForeground,
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        );
                      }),
                    ],
                  );
                },
              ),
            );
          },
        ),
      ),
    );
  }
}
