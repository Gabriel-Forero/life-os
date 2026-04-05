/// Abstract provider interface for AI language model backends.
///
/// Implementations are provider-agnostic plugins — the application
/// depends only on this interface, enabling swapping between
/// OpenAI, Anthropic, or any custom backend without changing call sites.
abstract class AIProvider {
  /// The unique key identifying this provider (e.g. 'openai', 'anthropic').
  String get providerKey;

  /// Sends [prompt] to the language model with an optional [systemContext]
  /// injected as a system-role message.
  ///
  /// Returns a [Stream<String>] of token chunks so the UI can render
  /// responses incrementally as they arrive.
  Stream<String> sendMessage(String prompt, {String? systemContext});

  /// Returns the list of model identifiers available for this provider.
  ///
  /// Used to populate model selection dropdowns in the AI config screen.
  Future<List<String>> listModels();
}
