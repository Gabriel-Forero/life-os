import 'package:life_os/features/intelligence/domain/ai_provider.dart';

/// OpenAI implementation of [AIProvider].
///
/// Stub: the interface contract is fully implemented. Actual HTTP calls
/// via the OpenAI REST API are deferred to a future iteration — this stub
/// returns controlled responses so the rest of the system can be integrated
/// and tested end-to-end today.
class OpenAIProvider implements AIProvider {
  const OpenAIProvider({required this.apiKey, required String model})
      : _model = model;

  final String apiKey;
  final String _model;

  @override
  String get providerKey => 'openai';

  /// Streams a stub assistant response token by token.
  ///
  /// TODO: Replace with real OpenAI streaming HTTP call when the HTTP
  /// dependency is added to pubspec.yaml.
  @override
  Stream<String> sendMessage(String prompt, {String? systemContext}) async* {
    // Simulate a short delay to mimic network latency in tests / dev.
    await Future<void>.delayed(const Duration(milliseconds: 50));
    final stubResponse =
        'Hola! Soy tu asistente de LifeOS. '
        '(Respuesta generada por el modelo $_model — '
        'integracion HTTP pendiente.)';
    for (final word in stubResponse.split(' ')) {
      yield '$word ';
      await Future<void>.delayed(const Duration(milliseconds: 10));
    }
  }

  /// Returns a static list of commonly used OpenAI models.
  ///
  /// TODO: Replace with a live GET /v1/models API call.
  @override
  Future<List<String>> listModels() async => const [
        'gpt-4o',
        'gpt-4o-mini',
        'gpt-4-turbo',
        'gpt-3.5-turbo',
      ];
}
