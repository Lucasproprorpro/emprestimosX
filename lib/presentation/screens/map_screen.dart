import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../data/models/client.dart';
import '../providers/derived.dart';
import '../widgets/common.dart';

/// Mapa de cobranças. Para manter o app compilável sem chave de API do Google
/// Maps, esta tela organiza a ORDEM DE VISITAS e abre a rota diretamente no
/// aplicativo Google Maps (origem = localização atual do aparelho).
class MapScreen extends ConsumerStatefulWidget {
  const MapScreen({super.key});

  @override
  ConsumerState<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends ConsumerState<MapScreen> {
  List<Client>? _ordered;

  @override
  Widget build(BuildContext context) {
    final located = ref.watch(clientsWithLocationProvider);
    _ordered ??= List.of(located);
    // Mantém sincronizado com novos/removidos.
    if (_ordered!.length != located.length) _ordered = List.of(located);

    return Scaffold(
      appBar: AppBar(title: const Text('Mapa de cobranças')),
      body: located.isEmpty
          ? const EmptyState(
              icon: Icons.location_off,
              title: 'Nenhum cliente com GPS',
              message: 'Capture a localização no cadastro do cliente para vê-lo aqui.')
          : Column(
              children: [
                Padding(
                  padding: const EdgeInsets.all(12),
                  child: Text(
                    'Arraste para organizar a ordem das visitas.',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ),
                Expanded(
                  child: ReorderableListView.builder(
                    padding: const EdgeInsets.fromLTRB(12, 0, 12, 96),
                    itemCount: _ordered!.length,
                    onReorder: (oldI, newI) {
                      setState(() {
                        if (newI > oldI) newI -= 1;
                        final item = _ordered!.removeAt(oldI);
                        _ordered!.insert(newI, item);
                      });
                    },
                    itemBuilder: (context, i) {
                      final c = _ordered![i];
                      return Card(
                        key: ValueKey(c.id),
                        margin: const EdgeInsets.only(bottom: 8),
                        child: ListTile(
                          leading: CircleAvatar(child: Text('${i + 1}')),
                          title: Text(c.name),
                          subtitle: Text(
                              '${c.latitude!.toStringAsFixed(4)}, ${c.longitude!.toStringAsFixed(4)}'),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              IconButton(
                                icon: const Icon(Icons.navigation),
                                tooltip: 'Traçar rota',
                                onPressed: () => _openRouteTo(c),
                              ),
                              const Icon(Icons.drag_handle),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
      floatingActionButton: located.isEmpty
          ? null
          : FloatingActionButton.extended(
              onPressed: _openFullRoute,
              icon: const Icon(Icons.route),
              label: const Text('Rota completa'),
            ),
    );
  }

  Future<void> _openRouteTo(Client c) async {
    await _launch(
        'https://www.google.com/maps/dir/?api=1&destination=${c.latitude},${c.longitude}&travelmode=driving');
  }

  Future<void> _openFullRoute() async {
    final list = _ordered!;
    if (list.isEmpty) return;
    final destination = list.last;
    final waypoints = list
        .take(list.length - 1)
        .map((c) => '${c.latitude},${c.longitude}')
        .join('|');
    final url = StringBuffer(
        'https://www.google.com/maps/dir/?api=1&destination=${destination.latitude},${destination.longitude}&travelmode=driving');
    if (waypoints.isNotEmpty) {
      url.write('&waypoints=${Uri.encodeComponent(waypoints)}');
    }
    await _launch(url.toString());
  }

  Future<void> _launch(String url) async {
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } else if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Não foi possível abrir o mapa.')),
      );
    }
  }
}
