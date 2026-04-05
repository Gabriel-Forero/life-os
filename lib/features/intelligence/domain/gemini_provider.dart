import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:life_os/features/intelligence/domain/ai_provider.dart';

/// Google Gemini implementation of [AIProvider].
///
/// Uses the Gemini API with SSE streaming.
/// https://ai.google.dev/api/generate-content
class GeminiProvider implements AIProvider {
  GeminiProvider({required this.apiKey, required String model})
      : _model = model;

  final String apiKey;
  final String _model;

  static const _baseUrl = 'https://generativelanguage.googleapis.com/v1beta';

  @override
  String get providerKey => 'gemini';

  @override
  Stream<String> sendMessage(String prompt, {String? systemContext}) async* {
    final client = http.Client();
    try {
      final contents = <Map<String, dynamic>>[
        {
          'role': 'user',
          'parts': [
            {'text': prompt},
          ],
        },
      ];

      final body = <String, dynamic>{
        'contents': contents,
      };

      if (systemContext != null && systemContext.isNotEmpty) {
        body['systemInstruction'] = {
          'parts': [
            {'text': systemContext},
          ],
        };
      }

      // Gemini uses streamGenerateContent for streaming
      final url = Uri.parse(
        '$_baseUrl/models/$_model:streamGenerateContent?alt=sse&key=$apiKey',
      );

      final request = http.Request('POST', url)
        ..headers['Content-Type'] = 'application/json'
        ..body = jsonEncode(body);

      final response = await client.send(request);

      if (response.statusCode != 200) {
        final responseBody = await response.stream.bytesToString();
        yield 'Error ${response.statusCode}: $responseBody';
        return;
      }

      final lineStream = response.stream
          .transform(utf8.decoder)
          .transform(const LineSplitter());

      await for (final line in lineStream) {
        if (!line.startsWith('data: ')) continue;
        final data = line.substring(6).trim();

        try {
          final json = jsonDecode(data) as Map<String, dynamic>;
          final candidates = json['candidates'] as List<dynamic>?;
          if (candidates == null || candidates.isEmpty) continue;

          final content =
              (candidates[0] as Map<String, dynamic>)['content']
                  as Map<String, dynamic>?;
          final parts = content?['parts'] as List<dynamic>?;
          if (parts == null || parts.isEmpty) continue;

          final text = (parts[0] as Map<String, dynamic>)['text'];
          if (text is String && text.isNotEmpty) {
            yield text;
          }
        } catch (_) {
          // Malformed JSON chunk — skip
        }
      }
    } catch (e) {
      yield 'Error al conectar con Gemini: $e';
    } finally {
      client.close();
    }
  }

  @override
  Future<List<String>> listModels() async => const [
        'gemini-2.5-flash',
        'gemini-2.5-pro',
        'gemini-2.0-flash',
      ];
}
