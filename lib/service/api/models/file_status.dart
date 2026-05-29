/// Git file status returned by `GET /file/status`.
///
/// Matches the server schema:
/// ```ts
/// { path: string, added: number, removed: number, status: "added" | "deleted" | "modified" }
/// ```
class FileStatus {
  const FileStatus({
    required this.path,
    required this.added,
    required this.removed,
    required this.status,
  });

  final String path;
  final int added;
  final int removed;

  /// One of "added", "deleted", "modified".
  final String status;

  bool get isAdded => status == 'added';
  bool get isDeleted => status == 'deleted';
  bool get isModified => status == 'modified';

  factory FileStatus.fromJson(Map<String, dynamic> json) => FileStatus(
    path: json['path'] as String,
    added: json['added'] as int? ?? 0,
    removed: json['removed'] as int? ?? 0,
    status: json['status'] as String,
  );

  Map<String, dynamic> toJson() => {
    'path': path,
    'added': added,
    'removed': removed,
    'status': status,
  };
}
