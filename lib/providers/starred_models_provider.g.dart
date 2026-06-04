// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'starred_models_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(StarredModels)
final starredModelsProvider = StarredModelsProvider._();

final class StarredModelsProvider
    extends $NotifierProvider<StarredModels, Set<String>> {
  StarredModelsProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'starredModelsProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$starredModelsHash();

  @$internal
  @override
  StarredModels create() => StarredModels();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(Set<String> value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<Set<String>>(value),
    );
  }
}

String _$starredModelsHash() => r'4ab24c580946cff6c89614baf973067cb71eb222';

abstract class _$StarredModels extends $Notifier<Set<String>> {
  Set<String> build();
  @$mustCallSuper
  @override
  void runBuild() {
    final ref = this.ref as $Ref<Set<String>, Set<String>>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<Set<String>, Set<String>>,
              Set<String>,
              Object?,
              Object?
            >;
    element.handleCreate(ref, build);
  }
}
