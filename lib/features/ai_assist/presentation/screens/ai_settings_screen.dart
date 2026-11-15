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
  late AiProvider _provider;
  late final TextEditingController _modelCtl;
  final TextEditingController _keyCtl = TextEditingController();
  bool _obscure = true;
  bool _testing = false;

  @override
  void initState() {
    super.initState();
    final s = ref.read(settingsProvider);
    _provider = s.aiProvider;
    _modelCtl = TextEditingController(text: s.aiModel);
    _loadKey(_provider);
  }

  @override
  void dispose() {
    _modelCtl.dispose();
    _keyCtl.dispose();
    super.dispose();
  }

  Future<void> _loadKey(AiProvider p) async {
    final k = await ref.read(aiKeyStoreProvider).read(p);
    if (!mounted || _provider != p) return;
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
            aiModel: _modelCtl.text.trim(),
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
        model: _modelCtl.text.trim(),
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
                Text('Penyedia', style: AppText.bodyStrong),
                const SizedBox(height: Sp.x2),
                SegmentedButton<AiProvider>(
                  segments: const [
                    ButtonSegment(
                        value: AiProvider.anthropic, label: Text('Claude')),
                    ButtonSegment(
                        value: AiProvider.gemini, label: Text('Gemini')),
                    ButtonSegment(
                        value: AiProvider.openai, label: Text('OpenAI')),
                  ],
                  selected: {_provider},
                  onSelectionChanged: (v) {
                    setState(() => _provider = v.first);
                    _loadKey(v.first);
                  },
                ),
                const SizedBox(height: Sp.x4),
                Text('Model', style: AppText.bodyStrong),
                const SizedBox(height: Sp.x2),
                TextField(
                  controller: _modelCtl,
                  decoration: InputDecoration(
                    hintText: kDefaultModels[_provider],
                  ),
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
