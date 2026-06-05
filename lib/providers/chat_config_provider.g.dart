// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'chat_config_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(ChatConfigNotifier)
final chatConfigProvider = ChatConfigNotifierProvider._();

final class ChatConfigNotifierProvider
    extends $NotifierProvider<ChatConfigNotifier, ChatConfig> {
  ChatConfigNotifierProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'chatConfigProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$chatConfigNotifierHash();

  @$internal
  @override
  ChatConfigNotifier create() => ChatConfigNotifier();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(ChatConfig value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<ChatConfig>(value),
    );
  }
}

String _$chatConfigNotifierHash() =>
    r'44c4fe52a6b00ba945b84cb4022ee6edd473ce4d';

abstract class _$ChatConfigNotifier extends $Notifier<ChatConfig> {
  ChatConfig build();
  @$mustCallSuper
  @override
  void runBuild() {
    final ref = this.ref as $Ref<ChatConfig, ChatConfig>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<ChatConfig, ChatConfig>,
              ChatConfig,
              Object?,
              Object?
            >;
    element.handleCreate(ref, build);
  }
}
