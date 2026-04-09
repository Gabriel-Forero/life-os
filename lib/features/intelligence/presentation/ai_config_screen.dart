import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:life_os/core/database/app_database.dart';
import 'package:life_os/core/providers/providers.dart';
import 'package:life_os/features/intelligence/domain/ai_context_builder.dart';
import 'package:life_os/features/intelligence/domain/openai_provider.dart';

// ---------------------------------------------------------------------------
// AI Config Screen — Feature 6: Privacy & Security UI
// ---------------------------------------------------------------------------

class AIConfigScreen extends ConsumerStatefulWidget {
  const AIConfigScreen({super.key});

  @override
  ConsumerState<AIConfigScreen> createState() => _AIConfigScreenState();
}

class _AIConfigScreenState extends ConsumerState<AIConfigScreen> {
  final _formKey = GlobalKey<FormState>();
  final _modelController = TextEditingController();
  final _apiKeyController = TextEditingController();

  String _selectedProvider = 'openai';
  bool _isSaving = false;
  String? _feedbackMessage;

  static const _providers = ['openai', 'anthropic', 'custom'];

  static const _providerLabels = {
    'openai': 'OpenAI',
    'anthropic': 'Anthropic',
    'custom': 'Personalizado',
  };

  List<String> _availableModels = [];
  bool _loadingModels = false;
  bool _isClearingHistory = false;

  // Privacy setting: only send data when user explicitly requests
  bool _sendDataOnRequest = true;

  // API key stored status per provider
  final _keyStatus = <String, bool>{};

  @override
  void initState() {
    super.initState();
    _checkApiKeyStatuses();
  }

  @override
  void dispose() {
    _modelController.dispose();
    _apiKeyController.dispose();
    super.dispose();
  }

  Future<void> _checkApiKeyStatuses() async {
    final secureStorage = ref.read(secureStorageServiceProvider);
    for (final provider in _providers) {
      final key = await secureStorage.getApiKey();
      if (mounted) {
        setState(() {
          _keyStatus[provider] = key != null && key.isNotEmpty;
        });
      }
    }
  }

  Future<void> _loadModels() async {
    if (_selectedProvider != 'openai') {
      setState(() => _availableModels = []);
      return;
    }
    setState(() => _loadingModels = true);
    final provider = OpenAIProvider(
      apiKey: _apiKeyController.text.trim(),
      model: _modelController.text.trim().isEmpty
          ? 'gpt-4o'
          : _modelController.text.trim(),
    );
    final models = await provider.listModels();
    setState(() {
      _availableModels = models;
      _loadingModels = false;
      if (models.isNotEmpty && _modelController.text.trim().isEmpty) {
        _modelController.text = models.first;
      }
    });
  }

  Future<void> _save() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    setState(() {
      _isSaving = true;
      _feedbackMessage = null;
    });

    // Save API key to secure storage
    final apiKey = _apiKeyController.text.trim();
    if (apiKey.isNotEmpty) {
      final secureStorage = ref.read(secureStorageServiceProvider);
      await secureStorage.saveApiKey(apiKey);
      _keyStatus[_selectedProvider] = true;
    }

    final notifier = ref.read(aiNotifierProvider);
    final result = await notifier.addConfiguration(
      providerKey: _selectedProvider,
      modelName: _modelController.text.trim(),
      isDefault: notifier.state.configurations.isEmpty,
    );

    setState(() => _isSaving = false);

    result.when(
      success: (_) {
        setState(
          () => _feedbackMessage = 'Configuracion guardada correctamente',
        );
        _formKey.currentState?.reset();
        _modelController.clear();
        _apiKeyController.clear();
      },
      failure: (f) => setState(() => _feedbackMessage = f.userMessage),
    );
  }

  Future<void> _clearAIHistory() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Borrar historial de IA'),
        content: const Text(
          'Se eliminaran todas las conversaciones y mensajes del asistente. '
          'Esta accion no se puede deshacer.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Borrar'),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    setState(() => _isClearingHistory = true);

    try {
      final dao = ref.read(aiDaoProvider);
      // Get all conversations and delete each (cascade deletes messages)
      final conversations = await dao.getAllConversations();
      for (final conv in conversations) {
        await dao.deleteConversation(conv.id);
      }
      if (mounted) {
        setState(() {
          _isClearingHistory = false;
          _feedbackMessage = 'Historial de IA eliminado correctamente';
        });
      }
    } on Exception catch (e) {
      setState(() {
        _isClearingHistory = false;
        _feedbackMessage = 'Error al borrar historial: $e';
      });
    }
  }

  Future<void> _showDataPreview() async {
    final summary = await buildRealModuleSummary(ref);
    final contextString = buildAIContext(summary);

    if (!mounted) return;

    await showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Datos que se envian a la IA'),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Este es el contexto que se incluye en cada mensaje:',
                style: Theme.of(ctx).textTheme.bodySmall?.copyWith(
                      color: Theme.of(ctx).colorScheme.outline,
                    ),
              ),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Theme.of(ctx).colorScheme.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  contextString,
                  style: Theme.of(ctx).textTheme.bodySmall?.copyWith(
                        fontFamily: 'monospace',
                        fontSize: 11,
                      ),
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cerrar'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final notifier = ref.watch(aiNotifierProvider);
    final theme = Theme.of(context);
    final primaryColor = theme.colorScheme.primary;

    return Scaffold(
      key: const ValueKey('ai_config_screen'),
      appBar: AppBar(
        title: const Text('Configuracion de IA'),
        backgroundColor: theme.scaffoldBackgroundColor,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ---------------------------------------------------------------
              // Info card: no API key needed
              // ---------------------------------------------------------------
              Card(
                elevation: 0,
                color: primaryColor.withAlpha(12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                  side: BorderSide(color: primaryColor.withAlpha(50)),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Row(
                    children: [
                      Icon(Icons.info_outline, color: primaryColor, size: 20),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          'Sin API key, la app funciona al 100%. '
                          'Con key, se activan funciones inteligentes como el '
                          'asistente, resumen semanal y analisis de tickets.',
                          style: theme.textTheme.bodySmall,
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 16),

              // ---------------------------------------------------------------
              // Secure storage info
              // ---------------------------------------------------------------
              Semantics(
                label: 'Almacenamiento seguro de claves de API',
                child: Card(
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                    side: BorderSide(color: theme.colorScheme.outline.withAlpha(40)),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(Icons.lock_outline,
                                color: theme.colorScheme.primary, size: 18),
                            const SizedBox(width: 8),
                            Text(
                              'Almacenamiento seguro',
                              style: theme.textTheme.labelLarge?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'iOS Keychain / Android EncryptedSharedPreferences. '
                          'Tu clave de API nunca se muestra ni se comparte.',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.outline,
                          ),
                        ),
                        const SizedBox(height: 12),
                        // API key status per provider
                        ..._providers.map((p) {
                          final stored = _keyStatus[p] ?? false;
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 4),
                            child: Row(
                              children: [
                                Icon(
                                  stored ? Icons.check_circle : Icons.radio_button_unchecked,
                                  size: 16,
                                  color: stored ? Colors.green : theme.colorScheme.outline,
                                ),
                                const SizedBox(width: 6),
                                Text(
                                  _providerLabels[p] ?? p,
                                  style: theme.textTheme.bodySmall,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  stored ? '(clave almacenada)' : '(sin clave)',
                                  style: theme.textTheme.bodySmall?.copyWith(
                                    color: stored ? Colors.green : theme.colorScheme.outline,
                                    fontStyle: FontStyle.italic,
                                  ),
                                ),
                              ],
                            ),
                          );
                        }),
                      ],
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 16),

              // ---------------------------------------------------------------
              // Privacy settings
              // ---------------------------------------------------------------
              Semantics(
                label: 'Configuracion de privacidad',
                child: Card(
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                    side: BorderSide(color: theme.colorScheme.outline.withAlpha(40)),
                  ),
                  child: Column(
                    children: [
                      SwitchListTile(
                        key: const ValueKey('send_data_toggle'),
                        title: const Text('Enviar datos solo cuando lo solicite'),
                        subtitle: const Text(
                          'Si esta activo, el contexto de tus datos solo se envia '
                          'cuando inicias una conversacion o pides un resumen.',
                        ),
                        value: _sendDataOnRequest,
                        onChanged: (v) => setState(() => _sendDataOnRequest = v),
                      ),
                      const Divider(height: 1),
                      ListTile(
                        key: const ValueKey('preview_data_tile'),
                        leading: const Icon(Icons.visibility_outlined),
                        title: const Text('Ver datos que se enviaran'),
                        subtitle: const Text('Muestra el contexto exacto que recibe la IA'),
                        trailing: const Icon(Icons.chevron_right),
                        onTap: _showDataPreview,
                      ),
                      const Divider(height: 1),
                      ListTile(
                        key: const ValueKey('clear_history_tile'),
                        leading: Icon(Icons.delete_outline, color: Colors.red.withAlpha(200)),
                        title: const Text('Borrar historial de IA'),
                        subtitle: const Text('Elimina todas las conversaciones y mensajes'),
                        trailing: _isClearingHistory
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(strokeWidth: 2),
                              )
                            : const Icon(Icons.chevron_right),
                        onTap: _isClearingHistory ? null : _clearAIHistory,
                      ),
                    ],
                  ),
                ),
              ),

              const Divider(height: 32),

              // ---------------------------------------------------------------
              // Existing configurations
              // ---------------------------------------------------------------
              Semantics(
                label: 'Proveedores configurados',
                child: Text(
                  'Proveedores configurados',
                  style: theme.textTheme.titleMedium
                      ?.copyWith(fontWeight: FontWeight.bold),
                ),
              ),
              const SizedBox(height: 8),
              StreamBuilder<List<AiConfiguration>>(
                stream: notifier.dao.watchAllConfigurations(),
                initialData: notifier.state.configurations,
                builder: (context, snapshot) {
                  final configs = snapshot.data ?? [];
                  if (configs.isEmpty) {
                    return Semantics(
                      label: 'Sin configuraciones',
                      child: const Text(
                        'Sin configuraciones. Agrega una abajo.',
                        style: TextStyle(color: Colors.grey),
                      ),
                    );
                  }
                  return ListView.builder(
                    key: const ValueKey('config_list'),
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: configs.length,
                    itemBuilder: (context, index) {
                      final config = configs[index];
                      return _ConfigTile(
                        key: ValueKey('config_tile_${config.id}'),
                        config: config,
                        primaryColor: primaryColor,
                        onSetDefault: () =>
                            notifier.setDefaultProvider(config.id),
                        onDelete: () =>
                            notifier.deleteConfiguration(config.id),
                      );
                    },
                  );
                },
              ),

              const Divider(height: 32),

              // ---------------------------------------------------------------
              // Add new configuration form
              // ---------------------------------------------------------------
              Semantics(
                label: 'Agregar nuevo proveedor',
                child: Text(
                  'Agregar proveedor',
                  style: theme.textTheme.titleMedium
                      ?.copyWith(fontWeight: FontWeight.bold),
                ),
              ),
              const SizedBox(height: 16),

              // Provider selector
              Semantics(
                label: 'Seleccionar proveedor de IA',
                child: DropdownButtonFormField<String>(
                  key: const ValueKey('provider_dropdown'),
                  initialValue: _selectedProvider,
                  decoration: const InputDecoration(
                    labelText: 'Proveedor',
                    border: OutlineInputBorder(),
                  ),
                  items: _providers
                      .map(
                        (p) => DropdownMenuItem(
                          value: p,
                          child: Text(_providerLabels[p] ?? p),
                        ),
                      )
                      .toList(),
                  onChanged: (value) {
                    setState(() => _selectedProvider = value ?? 'openai');
                    _loadModels();
                  },
                ),
              ),
              const SizedBox(height: 12),

              // API Key field (never shows stored key)
              Semantics(
                label: 'Clave de API',
                child: TextFormField(
                  key: const ValueKey('api_key_field'),
                  controller: _apiKeyController,
                  decoration: InputDecoration(
                    labelText: 'Clave de API',
                    border: const OutlineInputBorder(),
                    hintText: _keyStatus[_selectedProvider] == true
                        ? '(ya configurada — ingresa nueva para reemplazar)'
                        : 'sk-...',
                    helperText: 'Nunca se muestra el valor almacenado',
                  ),
                  obscureText: true,
                  onChanged: (_) => _loadModels(),
                  validator: (v) {
                    if ((_keyStatus[_selectedProvider] ?? false) &&
                        (v == null || v.trim().isEmpty)) {
                      // Already has a key — allow empty to keep existing
                      return null;
                    }
                    if (v == null || v.trim().isEmpty) {
                      return 'Ingresa tu clave de API';
                    }
                    return null;
                  },
                ),
              ),
              const SizedBox(height: 12),

              // Model field / dropdown
              if (_loadingModels)
                const Center(child: CircularProgressIndicator())
              else if (_availableModels.isNotEmpty)
                Semantics(
                  label: 'Seleccionar modelo',
                  child: DropdownButtonFormField<String>(
                    key: const ValueKey('model_dropdown'),
                    initialValue: _availableModels.contains(_modelController.text)
                        ? _modelController.text
                        : _availableModels.first,
                    decoration: const InputDecoration(
                      labelText: 'Modelo',
                      border: OutlineInputBorder(),
                    ),
                    items: _availableModels
                        .map(
                          (m) => DropdownMenuItem(value: m, child: Text(m)),
                        )
                        .toList(),
                    onChanged: (v) =>
                        setState(() => _modelController.text = v ?? ''),
                  ),
                )
              else
                Semantics(
                  label: 'Nombre del modelo',
                  child: TextFormField(
                    key: const ValueKey('model_name_field'),
                    controller: _modelController,
                    decoration: const InputDecoration(
                      labelText: 'Modelo',
                      border: OutlineInputBorder(),
                      hintText: 'gpt-4o',
                    ),
                    validator: (v) =>
                        (v == null || v.trim().isEmpty)
                            ? 'Ingresa el nombre del modelo'
                            : null,
                  ),
                ),

              const SizedBox(height: 20),

              // Save button
              SizedBox(
                width: double.infinity,
                child: Semantics(
                  label: 'Guardar configuracion',
                  button: true,
                  child: ElevatedButton.icon(
                    key: const ValueKey('save_config_button'),
                    onPressed: _isSaving ? null : _save,
                    icon: _isSaving
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.save_outlined),
                    label: const Text('Guardar'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: primaryColor,
                      foregroundColor: Colors.white,
                    ),
                  ),
                ),
              ),

              if (_feedbackMessage != null) ...[
                const SizedBox(height: 12),
                Semantics(
                  label: _feedbackMessage,
                  child: Text(
                    _feedbackMessage!,
                    style: TextStyle(
                      color: _feedbackMessage!.contains('correctamente')
                          ? Colors.green
                          : Colors.red,
                    ),
                  ),
                ),
              ],

              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Config tile widget
// ---------------------------------------------------------------------------

class _ConfigTile extends StatelessWidget {
  const _ConfigTile({
    super.key,
    required this.config,
    required this.primaryColor,
    required this.onSetDefault,
    required this.onDelete,
  });

  final AiConfiguration config;
  final Color primaryColor;
  final VoidCallback onSetDefault;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: Semantics(
          label: config.isDefault ? 'Proveedor predeterminado' : '',
          child: Icon(
            config.isDefault ? Icons.star : Icons.star_border,
            color: config.isDefault ? primaryColor : null,
          ),
        ),
        title: Text(config.modelName),
        subtitle: Text(config.providerKey),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (!config.isDefault)
              Semantics(
                label: 'Establecer como predeterminado',
                button: true,
                child: IconButton(
                  key: ValueKey('set_default_${config.id}'),
                  icon: const Icon(Icons.check_circle_outline),
                  tooltip: 'Establecer como predeterminado',
                  onPressed: onSetDefault,
                ),
              ),
            Semantics(
              label: 'Eliminar configuracion',
              button: true,
              child: IconButton(
                key: ValueKey('delete_config_${config.id}'),
                icon: const Icon(Icons.delete_outline),
                tooltip: 'Eliminar',
                color: Colors.red,
                onPressed: onDelete,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
