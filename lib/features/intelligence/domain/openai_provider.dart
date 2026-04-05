import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:life_os/features/intelligence/domain/ai_provider.dart';

/// OpenAI implementation of [AIProvider].
///
/// Uses the Chat Completions API with server-sent events (SSE) streaming so
/// the UI can render tokens incrementally as they arrive from the model.
class OpenAIProvider implements AIProvider {
  OpenAIProvider({required this.apiKey, required String model})
      : _model = model;

  final String apiKey;
  final String _model;

  static const _baseUrl = 'https://api.openai.com/v1';

  @override
  String get providerKey => 'openai';

  /// Streams token chunks from the OpenAI Chat Completions endpoint using SSE.
  ///
  /// Each chunk emitted is a partial content string (`choices[0].delta.content`).
  /// On any network or API error the stream emits a single human-readable error
  /// string and then closes — callers never see an unhandled exception.
  @override
  Stream<String> sendMessage(String prompt, {String? systemContext}) async* {
    final client = http.Client();
    try {
      final messages = <Map<String, String>>[
        if (systemContext != null && systemContext.isNotEmpty)
          {'role': 'system', 'content': systemContext},
        {'role': 'user', 'content': prompt},
      ];

      final request = http.Request(
        'POST',
        Uri.parse('$_baseUrl/chat/completions'),
      )
        ..headers['Authorization'] = 'Bearer $apiKey'
        ..headers['Content-Type'] = 'application/json'
        ..body = jsonEncode({
          'model': _model,
          'messages': messages,
          'stream': true,
        });

      final response = await client.send(request);

      if (response.statusCode != 200) {
        final body = await response.stream.bytesToString();
        yield 'Error ${response.statusCode}: $body';
        return;
      }

      // Parse SSE stream line by line.
      final lineStream = response.stream
          .transform(utf8.decoder)
          .transform(const LineSplitter());

      await for (final line in lineStream) {
        if (!line.startsWith('data: ')) continue;
        final data = line.substring(6).trim();
        if (data == '[DONE]') break;

        try {
          final json = jsonDecode(data) as Map<String, dynamic>;
          final choices = json['choices'] as List<dynamic>?;
          if (choices == null || choices.isEmpty) continue;
          final delta =
              (choices[0] as Map<String, dynamic>)['delta']
                  as Map<String, dynamic>?;
          final content = delta?['content'];
          if (content is String && content.isNotEmpty) {
            yield content;
          }
        } catch (_) {
          // Malformed JSON chunk — skip silently.
        }
      }
    } catch (e) {
      yield 'Error al conectar con OpenAI: $e';
    } finally {
      client.close();
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
