import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../l10n/l10n.dart';
import '../providers/file_provider.dart';
import '../providers/file_status_provider.dart';
import '../route_navigation.dart';
import '../service/api/models/file_status.dart';
import '../theme/app_tokens.dart';
import '../widgets/message/diff_view.dart';

class GitFilesPage extends ConsumerWidget {
  const GitFilesPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final statusAsync = ref.watch(fileStatusProvider);
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final tokens = context.tokens;
    final l10n = context.l10n;

    return Scaffold(
      backgroundColor: colorScheme.surface,
      appBar: AppBar(
        title: Text(l10n.gitFilesTitle),
        backgroundColor: colorScheme.surface,
        foregroundColor: colorScheme.onSurface,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(
            color: tokens.border.withValues(alpha: 0.5),
            height: 1,
          ),
        ),
      ),
      body: statusAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => _ErrorView(error: error),
        data: (files) {
          if (files.isEmpty) {
            return _EmptyView();
          }
          return _FileListView(files: files);
        },
      ),
    );
  }
}

class _EmptyView extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    final l10n = context.l10n;
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.check_circle_outline_rounded,
              size: 56,
              color: tokens.mutedForeground.withValues(alpha: 0.5),
            ),
            const SizedBox(height: 16),
            Text(
              l10n.gitFilesEmptyTitle,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: tokens.mutedForeground,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              l10n.gitFilesEmptySubtitle,
              style: TextStyle(
                fontSize: 13,
                color: tokens.mutedForeground.withValues(alpha: 0.8),
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

class _ErrorView extends StatelessWidget {
  const _ErrorView({required this.error});
  final Object error;

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    final l10n = context.l10n;
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.error_outline_rounded,
              size: 48,
              color: tokens.errorSoftForeground,
            ),
            const SizedBox(height: 12),
            Text(
              l10n.gitFilesLoadFailed,
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w500,
                color: Theme.of(context).colorScheme.onSurface,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              '$error',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 12, color: tokens.mutedForeground),
            ),
          ],
        ),
      ),
    );
  }
}

class _FileListView extends StatelessWidget {
  const _FileListView({required this.files});
  final List<FileStatus> files;

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    final l10n = context.l10n;

    return Column(
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            color: tokens.accent,
            border: Border(bottom: BorderSide(color: tokens.border)),
          ),
          child: Row(
            children: [
              Icon(
                Icons.source_rounded,
                size: 14,
                color: tokens.mutedForeground,
              ),
              const SizedBox(width: 6),
              Text(
                l10n.gitFilesCount(files.length),
                style: TextStyle(fontSize: 12, color: tokens.mutedForeground),
              ),
            ],
          ),
        ),
        Expanded(
          child: ListView.builder(
            itemCount: files.length,
            itemBuilder: (context, index) {
              final file = files[index];
              return _FileStatusTile(file: file);
            },
          ),
        ),
      ],
    );
  }
}

class _FileStatusTile extends ConsumerWidget {
  const _FileStatusTile({required this.file});
  final FileStatus file;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tokens = context.tokens;
    final colorScheme = Theme.of(context).colorScheme;

    final (icon, color, label) = switch (file.status) {
      'added' => (
        Icons.add_circle_rounded,
        Colors.green,
        context.l10n.gitFilesStatusAdded,
      ),
      'deleted' => (
        Icons.remove_circle_rounded,
        Colors.red,
        context.l10n.gitFilesStatusDeleted,
      ),
      _ => (
        Icons.edit_rounded,
        Colors.orange,
        context.l10n.gitFilesStatusModified,
      ),
    };

    final fileName = _fileName(file.path);
    final dirPath = file.path != fileName
        ? file.path.substring(0, file.path.length - fileName.length)
        : null;

    return Theme(
      data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
      child: ExpansionTile(
        enabled: !file.isDeleted,
        tilePadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        childrenPadding: EdgeInsets.zero,
        leading: Icon(icon, size: 18, color: color),
        title: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    fileName,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: file.isDeleted
                          ? tokens.mutedForeground
                          : colorScheme.onSurface,
                      decoration: file.isDeleted
                          ? TextDecoration.lineThrough
                          : null,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  if (dirPath != null) ...[
                    const SizedBox(height: 2),
                    Text(
                      dirPath,
                      style: TextStyle(
                        fontSize: 11,
                        color: tokens.mutedForeground,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                label,
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                  color: color,
                ),
              ),
            ),
            if (!file.isDeleted && (file.added > 0 || file.removed > 0)) ...[
              const SizedBox(width: 6),
              _DiffStatChip(additions: file.added, deletions: file.removed),
            ],
            if (!file.isDeleted) ...[
              const SizedBox(width: 6),
              GestureDetector(
                onTap: () => context.pushFileContentByPath(file.path),
                child: Tooltip(
                  message: context.l10n.gitFilesViewFile,
                  child: Container(
                    width: 28,
                    height: 28,
                    decoration: BoxDecoration(
                      color: tokens.accent,
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Icon(
                      Icons.visibility_outlined,
                      size: 15,
                      color: tokens.mutedForeground,
                    ),
                  ),
                ),
              ),
            ],
            const SizedBox(width: 4),
            if (!file.isDeleted)
              Icon(
                Icons.expand_more_rounded,
                size: 18,
                color: tokens.mutedForeground,
              ),
          ],
        ),
        expandedAlignment: Alignment.topLeft,
        children: [
          if (file.isDeleted)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Text(
                'No changes',
                style: TextStyle(fontSize: 12, color: tokens.mutedForeground),
              ),
            )
          else
            _InlineDiffContent(filePath: file.path),
        ],
      ),
    );
  }

  static String _fileName(String path) {
    final normalized = path.replaceAll('\\', '/');
    final parts = normalized.split('/');
    return parts.lastWhere((p) => p.isNotEmpty, orElse: () => path);
  }
}

class _InlineDiffContent extends ConsumerWidget {
  const _InlineDiffContent({required this.filePath});
  final String filePath;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tokens = context.tokens;
    final contentAsync = ref.watch(fileContentProvider(filePath));

    return contentAsync.when(
      loading: () => Padding(
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
        child: Center(
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: tokens.mutedForeground,
                ),
              ),
              const SizedBox(width: 8),
              Text(
                context.l10n.gitFilesDiffLoading,
                style: TextStyle(fontSize: 13, color: tokens.mutedForeground),
              ),
            ],
          ),
        ),
      ),
      error: (error, _) => Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          children: [
            Icon(
              Icons.error_outline_rounded,
              size: 16,
              color: tokens.errorSoftForeground,
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                context.l10n.gitFilesDiffLoadFailed,
                style: TextStyle(
                  fontSize: 12,
                  color: tokens.errorSoftForeground,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
      data: (content) {
        if (content.patch != null) {
          return Padding(
            padding: const EdgeInsets.only(
              left: 16,
              right: 16,
              bottom: 12,
              top: 4,
            ),
            child: PatchDiffView(patch: content.patch!, fileName: filePath),
          );
        }

        if (content.diff != null && content.diff!.isNotEmpty) {
          return Padding(
            padding: const EdgeInsets.only(
              left: 16,
              right: 16,
              bottom: 12,
              top: 4,
            ),
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: tokens.card,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: tokens.border.withValues(alpha: 0.8)),
              ),
              child: SelectableText(
                content.diff!,
                style: TextStyle(
                  fontSize: 12,
                  color: Theme.of(context).colorScheme.onSurface,
                  fontFamily: 'monospace',
                  height: 1.5,
                ),
              ),
            ),
          );
        }

        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Text(
            context.l10n.gitFilesDiffNoChanges,
            style: TextStyle(fontSize: 12, color: tokens.mutedForeground),
          ),
        );
      },
    );
  }
}

class _DiffStatChip extends StatelessWidget {
  const _DiffStatChip({required this.additions, required this.deletions});

  final int additions;
  final int deletions;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (additions > 0) ...[
          Text(
            '+$additions',
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: Colors.green,
              fontFamily: 'monospace',
            ),
          ),
        ],
        if (additions > 0 && deletions > 0) ...[
          Text(' ', style: TextStyle(fontSize: 11, fontFamily: 'monospace')),
        ],
        if (deletions > 0) ...[
          Text(
            '-$deletions',
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: Colors.red,
              fontFamily: 'monospace',
            ),
          ),
        ],
      ],
    );
  }
}
