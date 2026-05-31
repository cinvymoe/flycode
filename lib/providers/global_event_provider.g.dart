// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'global_event_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(GlobalEventListener)
final globalEventListenerProvider = GlobalEventListenerProvider._();

final class GlobalEventListenerProvider
    extends $StreamNotifierProvider<GlobalEventListener, GlobalEvent> {
  GlobalEventListenerProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'globalEventListenerProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$globalEventListenerHash();

  @$internal
  @override
  GlobalEventListener create() => GlobalEventListener();
}

String _$globalEventListenerHash() =>
    r'f44d91da018a8d8ef759d0002a694f371b224d14';

abstract class _$GlobalEventListener extends $StreamNotifier<GlobalEvent> {
  Stream<GlobalEvent> build();
  @$mustCallSuper
  @override
  void runBuild() {
    final ref = this.ref as $Ref<AsyncValue<GlobalEvent>, GlobalEvent>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<AsyncValue<GlobalEvent>, GlobalEvent>,
              AsyncValue<GlobalEvent>,
              Object?,
              Object?
            >;
    element.handleCreate(ref, build);
  }
}
