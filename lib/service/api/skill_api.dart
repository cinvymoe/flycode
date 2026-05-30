import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../../providers/current_directory_provider.dart';
import 'api_client.dart';
import 'models/skill.dart';

part 'skill_api.g.dart';

@Riverpod(keepAlive: true)
Future<SkillApi> skillApi(Ref ref) async {
  final client = await ref.watch(apiClientProvider.future);
  return SkillApi(client);
}

@Riverpod(keepAlive: true)
Future<List<Skill>> skills(Ref ref) async {
  final api = await ref.watch(skillApiProvider.future);
  final directory = ref.watch(currentDirectoryProvider);
  return api.getSkills(directory: directory);
}

class SkillApi {
  final ApiClient _client;

  SkillApi(this._client);

  Future<List<Skill>> getSkills({String? directory}) async {
    final queryParams = <String, String>{};
    if (directory != null) queryParams['directory'] = directory;

    final List<dynamic> json = await _client.get(
      '/skill',
      queryParameters: queryParams.isNotEmpty ? queryParams : null,
    );
    return json.map((e) => Skill.fromJson(e as Map<String, dynamic>)).toList();
  }
}
