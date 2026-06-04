import 'dart:async';
import 'dart:convert';

import 'package:riverpod_annotation/riverpod_annotation.dart';

import 'chat_view_state_provider.dart';
import '../service/api/models/agent.dart' as agent_model;
import '../service/api/models/message.dart';
import 'shared_preferences_provider.dart';
import 'session_provider.dart';

part 'chat_config_provider.g.dart';

const _kDefaultAgent = 'build';
const _kFallbackProviderID = 'opencode';
const _kFallbackModelID = 'minimax-m2.5-free';
const _kLastUsedModelCacheKey = 'chat_config_last_used_model';
const _kLastUsedAgentCacheKey = 'chat_config_last_used_agent';

class ChatConfig {
  final String agent;
  final MessageModel model;

  const ChatConfig({required this.agent, required this.model});

  ChatConfig copyWith({String? agent, MessageModel? model}) {
    return ChatConfig(agent: agent ?? this.agent, model: model ?? this.model);
  }

  @override
  String toString() =>
      'ChatConfig(agent: $agent, providerID: ${model.providerID},'
      ' modelID: ${model.modelID})';
}

@Riverpod(keepAlive: true)
class ChatConfigNotifier extends _$ChatConfigNotifier {
  @override
  ChatConfig build() {
    final initialState = ref.read(chatViewStateProvider);

    // Listen for session changes and sync the model when switching to an
    // existing session. Uses listen (not watch) so that message updates never
    // trigger a full rebuild of this notifier.
    ref.listen<ChatViewState>(chatViewStateProvider, (previous, next) {
      unawaited(_handleChatStateChanged(previous, next));
    });

    if (initialState.sessionId != null && !initialState.isPending) {
      unawaited(_syncModelFromSession(initialState.sessionId!));
    } else {
      unawaited(_restoreConfigFromCacheIfNoSession());
    }

    return ChatConfig(
      agent: _kDefaultAgent,
      model: MessageModel(
        providerID: _kFallbackProviderID,
        modelID: _kFallbackModelID,
      ),
    );
  }

  Future<void> _handleChatStateChanged(
    ChatViewState? previous,
    ChatViewState next,
  ) async {
    final newSessionId = next.sessionId;

    // New-session flow (isPending=true) or nothing selected: restore from
    // cache so input can fallback to the last-used model.
    if (next.isPending || newSessionId == null) {
      await _restoreConfigFromCacheIfNoSession();
      return;
    }

    // Same session selected again – nothing to do.
    if (newSessionId == previous?.sessionId) return;

    // Switched to an existing session: try to restore its last-used model.
    await _syncModelFromSession(newSessionId);
  }

  /// Reads selected-session messages once (no watch) and syncs model from the
  /// latest message context:
  /// 1) Prefer the last UserMessage (agent + model are both available).
  /// 2) Fallback to the last AssistantMessage's provider/model.
  /// If no suitable message exists, current config is preserved.
  Future<void> _syncModelFromSession(String sessionID) async {
    final messages = await ref.read(sessionMessagesProvider(sessionID).future);
    if (!ref.mounted || messages.isEmpty) return;

    // Track the most recent AssistantMessage for model fallback.
    AssistantMessage? lastAssistant;
    for (final message in messages.reversed) {
      if (message.info case final UserMessage user) {
        _setState(
          agent: user.agent,
          model: user.model,
          persistAgent: true,
          persistModel: true,
        );
        return;
      }
      lastAssistant ??= message.info as AssistantMessage;
    }

    // No UserMessage found: fallback to the last AssistantMessage's model.
    if (lastAssistant != null) {
      _setState(
        model: MessageModel(
          providerID: lastAssistant.providerID,
          modelID: lastAssistant.modelID,
        ),
        persistModel: true,
      );
    }
  }

  /// Sets the active agent. If [linkedModel] is provided (from the agent's
  /// bound model field), the model is also updated automatically.
  void setAgent(String agent, {agent_model.AgentModel? linkedModel}) {
    if (linkedModel == null) {
      _setState(agent: agent, persistAgent: true);
      return;
    }

    _setState(
      agent: agent,
      model: MessageModel(
        providerID: linkedModel.providerID,
        modelID: linkedModel.modelID,
      ),
      persistAgent: true,
      persistModel: true,
    );
  }

  void setModel(MessageModel model) {
    _setState(model: model, persistModel: true);
  }

  Future<void> _restoreConfigFromCacheIfNoSession() async {
    final chatState = ref.read(chatViewStateProvider);
    if (chatState.sessionId != null) return;

    final cachedModel = await _readCachedModel();
    final cachedAgent = await _readCachedAgent();
    if (!ref.mounted) return;

    final latestState = ref.read(chatViewStateProvider);
    if (latestState.sessionId != null) return;

    _setState(agent: cachedAgent, model: cachedModel);
  }

  Future<MessageModel?> _readCachedModel() async {
    final prefs = await ref.read(sharedPreferencesProvider.future);
    final raw = prefs.getString(_kLastUsedModelCacheKey);
    if (raw == null || raw.trim().isEmpty) return null;

    try {
      final json = jsonDecode(raw);
      if (json is! Map<String, dynamic>) return null;
      final model = MessageModel.fromJson(json);
      if (model.providerID.isEmpty || model.modelID.isEmpty) {
        return null;
      }
      return model;
    } catch (_) {
      return null;
    }
  }

  Future<void> _persistModel(MessageModel model) async {
    final prefs = await ref.read(sharedPreferencesProvider.future);
    await prefs.setString(_kLastUsedModelCacheKey, jsonEncode(model.toJson()));
  }

  Future<String?> _readCachedAgent() async {
    final prefs = await ref.read(sharedPreferencesProvider.future);
    final agent = prefs.getString(_kLastUsedAgentCacheKey);
    if (agent == null || agent.trim().isEmpty) return null;
    return agent;
  }

  Future<void> _persistAgent(String agent) async {
    final prefs = await ref.read(sharedPreferencesProvider.future);
    await prefs.setString(_kLastUsedAgentCacheKey, agent);
  }

  void _setState({
    String? agent,
    MessageModel? model,
    bool persistModel = false,
    bool persistAgent = false,
  }) {
    if (!ref.mounted) return;
    final next = state.copyWith(agent: agent, model: model);
    if (next.agent == state.agent &&
        next.model.providerID == state.model.providerID &&
        next.model.modelID == state.model.modelID) {
      return;
    }
    state = next;

    if (persistModel && model != null) {
      unawaited(_persistModel(model));
    }
    if (persistAgent && agent != null) {
      unawaited(_persistAgent(agent));
    }
  }
}
