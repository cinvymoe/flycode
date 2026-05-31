// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'session_status_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Tracks the backend-reported status for each session.
///
/// The map only contains entries for sessions that are non-idle.
/// A missing key is equivalent to [SessionStatusIdle].

@ProviderFor(SessionStatusNotifier)
final sessionStatusProvider = SessionStatusNotifierProvider._();

/// Tracks the backend-reported status for each session.
///
/// The map only contains entries for sessions that are non-idle.
/// A missing key is equivalent to [SessionStatusIdle].
final class SessionStatusNotifierProvider
    extends
        $NotifierProvider<SessionStatusNotifier, Map<String, SessionStatus>> {
  /// Tracks the backend-reported status for each session.
  ///
  /// The map only contains entries for sessions that are non-idle.
  /// A missing key is equivalent to [SessionStatusIdle].
  SessionStatusNotifierProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'sessionStatusProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$sessionStatusNotifierHash();

  @$internal
  @override
  SessionStatusNotifier create() => SessionStatusNotifier();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(Map<String, SessionStatus> value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<Map<String, SessionStatus>>(value),
    );
  }
}

String _$sessionStatusNotifierHash() =>
    r'658d7a0f0d418a53d270005058bc4e2c2d9ab6f0';

/// Tracks the backend-reported status for each session.
///
/// The map only contains entries for sessions that are non-idle.
/// A missing key is equivalent to [SessionStatusIdle].

abstract class _$SessionStatusNotifier
    extends $Notifier<Map<String, SessionStatus>> {
  Map<String, SessionStatus> build();
  @$mustCallSuper
  @override
  void runBuild() {
    final ref =
        this.ref
            as $Ref<Map<String, SessionStatus>, Map<String, SessionStatus>>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<
                Map<String, SessionStatus>,
                Map<String, SessionStatus>
              >,
              Map<String, SessionStatus>,
              Object?,
              Object?
            >;
    element.handleCreate(ref, build);
  }
}
