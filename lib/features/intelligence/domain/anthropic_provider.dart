import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:life_os/features/intelligence/domain/ai_provider.dart';

/// Anthropic (Claude) implementation of [AIProvider].
///
/// Uses the Messages API with SSE streaming.
/// https://docs.anthropic.com/en/api/messages
class AnthropicProvider implements AIProvider {
  AnthropicProvider({required this.apiKey, required String model})
      : _model = model;

  final String apiKey;
  final String _model;

  static const _baseUrl = 'https://api.anthropic.com/v1';
  static const _apiVersion = '2023-06-01';

  @override
  String get providerKey => 'anthropic';

  @override
  Stream<String> sendMessage(String prompt, {String? systemContext}) async* {
    final client = http.Client();
    try {
      final body = <String, dynamic>{
        'model': _model,
        'max_tokens': 4096,
        'stream': true,
        'messages': [
          {'role': 'user', 'content': prompt},
        ],
      };

      if (systemContext != null && systemContext.isNotEmpty) {
        body['system'] = systemContext;
      }

      final request = http.Request(
        'POST',
        Uri.parse('$_baseUrl/messages'),
      )
        ..headers['x-api-key'] = apiKey
        ..headers['anthropic-version'] = _apiVersion
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
          final type = json['type'] as String?;

          if (type == 'content_block_delta') {
            final delta = json['delta'] as Map<String, dynamic>?;
            final text = delta?['text'];
            if (text is String && text.isNotEmpty) {
              yield text;
            }
          } else if (type == 'message_stop') {
            break;
          }
        } catch (_) {
          // Malformed JSON chunk — skip
        }
      }
    } catch (e) {
      yield 'Error al conectar con Anthropic: $e';
    } finally {
      client.close();
    }
  }

  @override
  Future<List<String>> listModels() async => const [
        'claude-sonnet-4-20250514',
        'claude-haiku-4-20250414',
        'claude-opus-4-20250514',
      ];
}
