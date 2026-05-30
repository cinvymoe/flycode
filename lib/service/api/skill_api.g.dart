// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'skill_api.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(skillApi)
final skillApiProvider = SkillApiProvider._();

final class SkillApiProvider
    extends
        $FunctionalProvider<AsyncValue<SkillApi>, SkillApi, FutureOr<SkillApi>>
    with $FutureModifier<SkillApi>, $FutureProvider<SkillApi> {
  SkillApiProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'skillApiProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$skillApiHash();

  @$internal
  @override
  $FutureProviderElement<SkillApi> $createElement($ProviderPointer pointer) =>
      $FutureProviderElement(pointer);

  @override
  FutureOr<SkillApi> create(Ref ref) {
    return skillApi(ref);
  }
}

String _$skillApiHash() => r'04499524915fc5cca6a5a003f33cda513b8956e8';

@ProviderFor(skills)
final skillsProvider = SkillsProvider._();

final class SkillsProvider
    extends
        $FunctionalProvider<
          AsyncValue<List<Skill>>,
          List<Skill>,
          FutureOr<List<Skill>>
        >
    with $FutureModifier<List<Skill>>, $FutureProvider<List<Skill>> {
  SkillsProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'skillsProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$skillsHash();

  @$internal
  @override
  $FutureProviderElement<List<Skill>> $createElement(
    $ProviderPointer pointer,
  ) => $FutureProviderElement(pointer);

  @override
  FutureOr<List<Skill>> create(Ref ref) {
    return skills(ref);
  }
}

String _$skillsHash() => r'bab71660272de649bfd9226b830768c146f5f2c7';
