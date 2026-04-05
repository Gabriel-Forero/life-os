import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:life_os/core/database/app_database.dart';
import 'package:life_os/core/providers/providers.dart';
import 'package:life_os/features/intelligence/domain/openai_provider.dart';

// ---------------------------------------------------------------------------
// AI Config Screen
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

  @override
  void dispose() {
    _modelController.dispose();
    _apiKeyController.dispose();
    super.dispose();
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
                  value: _selectedProvider,
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

              // API Key field
              Semantics(
                label: 'Clave de API',
                child: TextFormField(
                  key: const ValueKey('api_key_field'),
                  controller: _apiKeyController,
                  decoration: const InputDecoration(
                    labelText: 'Clave de API',
                    border: OutlineInputBorder(),
                    hintText: 'sk-...',
                  ),
                  obscureText: true,
                  onChanged: (_) => _loadModels(),
                  validator: (v) =>
                      (v == null || v.trim().isEmpty)
                          ? 'Ingresa tu clave de API'
                          : null,
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
                    value: _availableModels.contains(_modelController.text)
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
