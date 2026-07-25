import 'dart:io';

import 'package:cross_file/cross_file.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

import '../providers/app_controller.dart';
import '../providers/settings_controller.dart';
import '../widgets/common.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(settingsProvider);
    final settingsCtrl = ref.read(settingsProvider.notifier);

    return Scaffold(
      appBar: AppBar(title: const Text('Configurações')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const SectionTitle('Aparência'),
          Card(
            child: Column(
              children: [
                RadioListTile<ThemeMode>(
                  title: const Text('Tema do sistema'),
                  value: ThemeMode.system,
                  groupValue: settings.themeMode,
                  onChanged: (v) => settingsCtrl.setThemeMode(v!),
                ),
                RadioListTile<ThemeMode>(
                  title: const Text('Claro'),
                  value: ThemeMode.light,
                  groupValue: settings.themeMode,
                  onChanged: (v) => settingsCtrl.setThemeMode(v!),
                ),
                RadioListTile<ThemeMode>(
                  title: const Text('Escuro'),
                  value: ThemeMode.dark,
                  groupValue: settings.themeMode,
                  onChanged: (v) => settingsCtrl.setThemeMode(v!),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          const SectionTitle('Moeda'),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Wrap(
                spacing: 8,
                children: ['R\$', 'US\$', '€', 'Kz', 'MZN']
                    .map((s) => ChoiceChip(
                          label: Text(s),
                          selected: settings.currencySymbol == s,
                          onSelected: (_) => settingsCtrl.setCurrency(s),
                        ))
                    .toList(),
              ),
            ),
          ),
          const SizedBox(height: 16),
          const SectionTitle('Backup'),
          Card(
            child: Column(
              children: [
                ListTile(
                  leading: const Icon(Icons.backup),
                  title: const Text('Exportar backup'),
                  subtitle: const Text('Salva um arquivo .json com todos os dados'),
                  onTap: () => _export(context, ref),
                ),
                const Divider(height: 1),
                ListTile(
                  leading: const Icon(Icons.restore),
                  title: const Text('Restaurar backup'),
                  subtitle: const Text('Substitui os dados atuais pelo arquivo'),
                  onTap: () => _restore(context, ref),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          const SectionTitle('Sobre'),
          const Card(
            child: ListTile(
              leading: Icon(Icons.info_outline),
              title: Text('EmprestaFácil'),
              subtitle: Text(
                  'Versão 1.0.0 — gestão de empréstimos Penhor, Diário e Parcelado.\n'
                  'Estruturado para futura sincronização em nuvem (Firebase).'),
              isThreeLine: true,
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _export(BuildContext context, WidgetRef ref) async {
    try {
      final json = ref.read(appProvider.notifier).exportBackup();
      final dir = await getTemporaryDirectory();
      final stamp = DateTime.now().millisecondsSinceEpoch;
      final file = File('${dir.path}/emprestafacil_backup_$stamp.json');
      await file.writeAsString(json);
      await Share.shareXFiles([XFile(file.path)],
          text: 'Backup EmprestaFácil');
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Falha ao exportar: $e')),
        );
      }
    }
  }

  Future<void> _restore(BuildContext context, WidgetRef ref) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Restaurar backup?'),
        content: const Text(
            'Os dados atuais serão substituídos pelos do arquivo selecionado.'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancelar')),
          FilledButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Continuar')),
        ],
      ),
    );
    if (confirm != true) return;

    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['json'],
      );
      if (result == null || result.files.single.path == null) return;
      final content =
          await File(result.files.single.path!).readAsString();
      await ref.read(appProvider.notifier).importBackup(content);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Backup restaurado com sucesso.')),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Falha ao restaurar: $e')),
        );
      }
    }
  }
}
