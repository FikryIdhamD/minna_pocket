import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../shared/domain/providers/settings_provider.dart';
import '../../../../shared/theme/app_colors.dart';
import '../../../../shared/theme/app_spacing.dart';
import '../../../../shared/theme/text_theme.dart';
import '../../data/datasource/ai_client.dart';
import '../../data/datasource/ai_key_store.dart';

class AiSettingsScreen extends ConsumerStatefulWidget {
  const AiSettingsScreen({super.key});

  @override
  ConsumerState<AiSettingsScreen> createState() => _AiSettingsScreenState();
}

class _AiSettingsScreenState extends ConsumerState<AiSettingsScreen> {
  static const AiProvider _provider = AiProvider.gemini;
  static const String _defaultModel = 'gemini-3.5-flash-lite';
  static const List<({String id, String label})> _geminiModels = [
    (
      id: 'gemini-3.5-flash-lite',
      label: 'gemini-3.5-flash-lite (Rekomendasi · 500/hari)'
    ),
    (id: 'gemini-3.1-flash-lite', label: 'gemini-3.1-flash-lite (500/hari)'),
    (id: 'gemini-2.5-flash-lite', label: 'gemini-2.5-flash-lite (20/hari)'),
    (id: 'gemini-2.5-flash', label: 'gemini-2.5-flash (20/hari)'),
    (id: 'gemini-3-flash', label: 'gemini-3-flash (20/hari)'),
    (id: 'gemini-3.6-flash', label: 'gemini-3.6-flash (20/hari)'),
    (id: 'gemini-3.8-flash', label: 'gemini-3.8-flash (20/hari)'),
  ];

  late String _selectedModel;
  final TextEditingController _keyCtl = TextEditingController();
  bool _obscure = true;
  bool _testing = false;

  @override
  void initState() {
    super.initState();
    final saved = ref.read(settingsProvider).aiModel.trim();
    final known = _geminiModels.any((m) => m.id == saved);
    _selectedModel = known ? saved : _defaultModel;
    _loadKey();
  }

  @override
  void dispose() {
    _keyCtl.dispose();
    super.dispose();
  }

  Future<void> _loadKey() async {
    final k = await ref.read(aiKeyStoreProvider).read(_provider);
    if (!mounted) return;
    _keyCtl.text = k ?? '';
  }

  Future<void> _save() async {
    final key = _keyCtl.text.trim();
    final store = ref.read(aiKeyStoreProvider);
    if (key.isEmpty) {
      await store.delete(_provider);
    } else {
      await store.write(_provider, key);
    }
    ref.read(aiKeyVersionProvider.notifier).bump();
    await ref.read(settingsProvider.notifier).update(
          (s) => s.copyWith(
            aiProvider: _provider,
            aiModel: _selectedModel,
          ),
        );
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Tersimpan.')),
      );
    }
  }

  Future<void> _testConnection() async {
    final key = _keyCtl.text.trim();
    if (key.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Masukkan API key terlebih dahulu.')),
      );
      return;
    }
    setState(() => _testing = true);
    try {
      await AiClient().stream(
        provider: _provider,
        model: _selectedModel,
        apiKey: key,
        system: 'Jawab singkat.',
        messages: const [AiMessage('user', 'Balas dengan satu kata: OK')],
      ).drain<void>();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Koneksi berhasil.')),
        );
      }
    } on AiException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.message)),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Gagal menguji koneksi: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _testing = false);
    }
  }

  Future<void> _deleteKey() async {
    await ref.read(aiKeyStoreProvider).delete(_provider);
    ref.read(aiKeyVersionProvider.notifier).bump();
    _keyCtl.clear();
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Key dihapus.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final p = context.palette;

    return Scaffold(
      appBar: AppBar(title: const Text('Pengaturan AI')),
      body: SafeArea(
        top: false,
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: Sizes.maxContentWidth),
            child: ListView(
              padding: const EdgeInsets.all(Sp.screen),
              children: [
                Text('Model (Gemini)', style: AppText.bodyStrong),
                const SizedBox(height: Sp.x2),
                DropdownButtonFormField<String>(
                  value: _selectedModel,
                  isExpanded: true,
                  items: [
                    for (final m in _geminiModels)
                      DropdownMenuItem(
                        value: m.id,
                        child: Text(m.label, overflow: TextOverflow.ellipsis),
                      ),
                  ],
                  onChanged: (v) {
                    if (v != null) setState(() => _selectedModel = v);
                  },
                ),
                const SizedBox(height: Sp.x4),
                Text('API key', style: AppText.bodyStrong),
                const SizedBox(height: Sp.x2),
                TextField(
                  controller: _keyCtl,
                  obscureText: _obscure,
                  autocorrect: false,
                  enableSuggestions: false,
                  decoration: InputDecoration(
                    hintText: 'Tempel API key...',
                    suffixIcon: TextButton(
                      onPressed: () => setState(() => _obscure = !_obscure),
                      child: Text(_obscure ? 'Lihat' : 'Tutup'),
                    ),
                  ),
                ),
                const SizedBox(height: Sp.x5),
                FilledButton(
                  onPressed: _save,
                  child: const Text('Simpan'),
                ),
                const SizedBox(height: Sp.x2),
                OutlinedButton(
                  onPressed: _testing ? null : _testConnection,
                  child: Text(_testing ? 'Menguji...' : 'Tes koneksi'),
                ),
                const SizedBox(height: Sp.x2),
                TextButton(
                  style: TextButton.styleFrom(foregroundColor: p.danger),
                  onPressed: _deleteKey,
                  child: const Text('Hapus key'),
                ),
                const SizedBox(height: Sp.x4),
                Text(
                  'Key disimpan terenkripsi di HP ini dan tidak ikut backup. Biaya pemakaian ditagih ke akun API milikmu. Jawaban AI selalu diberi label dan bisa keliru.',
                  style: AppText.bodySm.copyWith(color: p.inkMuted),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
