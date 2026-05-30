// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'command_api.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(commandApi)
final commandApiProvider = CommandApiProvider._();

final class CommandApiProvider
    extends
        $FunctionalProvider<
          AsyncValue<CommandApi>,
          CommandApi,
          FutureOr<CommandApi>
        >
    with $FutureModifier<CommandApi>, $FutureProvider<CommandApi> {
  CommandApiProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'commandApiProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$commandApiHash();

  @$internal
  @override
  $FutureProviderElement<CommandApi> $createElement($ProviderPointer pointer) =>
      $FutureProviderElement(pointer);

  @override
  FutureOr<CommandApi> create(Ref ref) {
    return commandApi(ref);
  }
}

String _$commandApiHash() => r'00ec16ed69fa7609af1495e691d19fd4138e7769';

@ProviderFor(commands)
final commandsProvider = CommandsProvider._();

final class CommandsProvider
    extends
        $FunctionalProvider<
          AsyncValue<List<Command>>,
          List<Command>,
          FutureOr<List<Command>>
        >
    with $FutureModifier<List<Command>>, $FutureProvider<List<Command>> {
  CommandsProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'commandsProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$commandsHash();

  @$internal
  @override
  $FutureProviderElement<List<Command>> $createElement(
    $ProviderPointer pointer,
  ) => $FutureProviderElement(pointer);

  @override
  FutureOr<List<Command>> create(Ref ref) {
    return commands(ref);
  }
}

String _$commandsHash() => r'f2682876e878c638da2792ca2410d256cc81084b';
