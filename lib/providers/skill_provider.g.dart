// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'skill_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(skillDatabaseHelper)
final skillDatabaseHelperProvider = SkillDatabaseHelperProvider._();

final class SkillDatabaseHelperProvider
    extends $FunctionalProvider<DatabaseHelper, DatabaseHelper, DatabaseHelper>
    with $Provider<DatabaseHelper> {
  SkillDatabaseHelperProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'skillDatabaseHelperProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$skillDatabaseHelperHash();

  @$internal
  @override
  $ProviderElement<DatabaseHelper> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  DatabaseHelper create(Ref ref) {
    return skillDatabaseHelper(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(DatabaseHelper value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<DatabaseHelper>(value),
    );
  }
}

String _$skillDatabaseHelperHash() =>
    r'17199814e3672694c09b92a9ae31340cd42ca18d';

@ProviderFor(skillDao)
final skillDaoProvider = SkillDaoProvider._();

final class SkillDaoProvider
    extends
        $FunctionalProvider<AsyncValue<SkillDao>, SkillDao, FutureOr<SkillDao>>
    with $FutureModifier<SkillDao>, $FutureProvider<SkillDao> {
  SkillDaoProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'skillDaoProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$skillDaoHash();

  @$internal
  @override
  $FutureProviderElement<SkillDao> $createElement($ProviderPointer pointer) =>
      $FutureProviderElement(pointer);

  @override
  FutureOr<SkillDao> create(Ref ref) {
    return skillDao(ref);
  }
}

String _$skillDaoHash() => r'4d40f054183aef9d430b5f3e05d3f33a7b534e2e';

@ProviderFor(SkillNotifier)
final skillProvider = SkillNotifierProvider._();

final class SkillNotifierProvider
    extends $AsyncNotifierProvider<SkillNotifier, List<SkillRecord>> {
  SkillNotifierProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'skillProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$skillNotifierHash();

  @$internal
  @override
  SkillNotifier create() => SkillNotifier();
}

String _$skillNotifierHash() => r'141c3e2703e33ca63c8f99588d8098d709c08324';

abstract class _$SkillNotifier extends $AsyncNotifier<List<SkillRecord>> {
  FutureOr<List<SkillRecord>> build();
  @$mustCallSuper
  @override
  void runBuild() {
    final ref =
        this.ref as $Ref<AsyncValue<List<SkillRecord>>, List<SkillRecord>>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<AsyncValue<List<SkillRecord>>, List<SkillRecord>>,
              AsyncValue<List<SkillRecord>>,
              Object?,
              Object?
            >;
    element.handleCreate(ref, build);
  }
}
