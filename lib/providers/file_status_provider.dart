import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../service/api/file_api.dart';
import '../service/api/models/file_status.dart';

part 'file_status_provider.g.dart';

@riverpod
Future<List<FileStatus>> fileStatus(Ref ref) async {
  final api = await ref.watch(fileApiProvider.future);
  return api.getFileStatus();
}
