// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'file_status_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(fileStatus)
final fileStatusProvider = FileStatusProvider._();

final class FileStatusProvider
    extends
        $FunctionalProvider<
          AsyncValue<List<FileStatus>>,
          List<FileStatus>,
          FutureOr<List<FileStatus>>
        >
    with $FutureModifier<List<FileStatus>>, $FutureProvider<List<FileStatus>> {
  FileStatusProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'fileStatusProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$fileStatusHash();

  @$internal
  @override
  $FutureProviderElement<List<FileStatus>> $createElement(
    $ProviderPointer pointer,
  ) => $FutureProviderElement(pointer);

  @override
  FutureOr<List<FileStatus>> create(Ref ref) {
    return fileStatus(ref);
  }
}

String _$fileStatusHash() => r'266f75190aebae37455d6ec6226dd5ed1c836bec';
