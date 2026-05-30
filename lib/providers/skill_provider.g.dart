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
        isAutoDispose: true,
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
    r'9710b5a073a0881f81cf97a18c21c972c720b48a';

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
        isAutoDispose: true,
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

String _$skillDaoHash() => r'87069b8b3b95f330d8c9076de02e54f532936ff8';

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

String _$skillNotifierHash() => r'f80450bab7fd7213e8c5e544ec2335a74048af37';

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
