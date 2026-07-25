import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import 'package:image_picker/image_picker.dart';

import '../../core/constants/enums.dart';
import '../../data/models/client.dart';
import '../providers/app_controller.dart';

class ClientFormScreen extends ConsumerStatefulWidget {
  const ClientFormScreen({super.key, this.existing});
  final Client? existing;

  @override
  ConsumerState<ClientFormScreen> createState() => _ClientFormScreenState();
}

class _ClientFormScreenState extends ConsumerState<ClientFormScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _name;
  late final TextEditingController _document;
  late final TextEditingController _cpf;
  late final TextEditingController _phone;
  late final TextEditingController _address;
  late final TextEditingController _notes;
  late final TextEditingController _businessName;

  String? _photoPath;
  double? _lat;
  double? _lng;
  BusinessType? _businessType;
  bool _capturingGps = false;

  @override
  void initState() {
    super.initState();
    final e = widget.existing;
    _name = TextEditingController(text: e?.name ?? '');
    _document = TextEditingController(text: e?.document ?? '');
    _cpf = TextEditingController(text: e?.cpf ?? '');
    _phone = TextEditingController(text: e?.phone ?? '');
    _address = TextEditingController(text: e?.address ?? '');
    _notes = TextEditingController(text: e?.notes ?? '');
    _businessName = TextEditingController(text: e?.businessName ?? '');
    _photoPath = e?.photoPath;
    _lat = e?.latitude;
    _lng = e?.longitude;
    _businessType = e?.businessType;
  }

  @override
  void dispose() {
    for (final c in [
      _name,
      _document,
      _cpf,
      _phone,
      _address,
      _notes,
      _businessName
    ]) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _pickPhoto() async {
    final source = await showModalBottomSheet<ImageSource>(
      context: context,
      builder: (_) => SafeArea(
        child: Wrap(children: [
          ListTile(
            leading: const Icon(Icons.camera_alt),
            title: const Text('Câmera'),
            onTap: () => Navigator.pop(context, ImageSource.camera),
          ),
          ListTile(
            leading: const Icon(Icons.photo_library),
            title: const Text('Galeria'),
            onTap: () => Navigator.pop(context, ImageSource.gallery),
          ),
        ]),
      ),
    );
    if (source == null) return;
    try {
      final file = await ImagePicker()
          .pickImage(source: source, maxWidth: 1080, imageQuality: 80);
      if (file != null) setState(() => _photoPath = file.path);
    } catch (_) {
      _snack('Não foi possível acessar a câmera/galeria.');
    }
  }

  Future<void> _captureGps() async {
    setState(() => _capturingGps = true);
    try {
      var perm = await Geolocator.checkPermission();
      if (perm == LocationPermission.denied) {
        perm = await Geolocator.requestPermission();
      }
      if (perm == LocationPermission.denied ||
          perm == LocationPermission.deniedForever) {
        _snack('Permissão de localização negada.');
        return;
      }
      final pos = await Geolocator.getCurrentPosition();
      setState(() {
        _lat = pos.latitude;
        _lng = pos.longitude;
      });
      _snack('Localização capturada.');
    } catch (_) {
      _snack('Não foi possível obter a localização.');
    } finally {
      if (mounted) setState(() => _capturingGps = false);
    }
  }

  void _snack(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(msg)));
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    final ctrl = ref.read(appProvider.notifier);
    if (widget.existing != null) {
      final updated = widget.existing!.copyWith(
        name: _name.text.trim(),
        document: _document.text.trim(),
        cpf: _cpf.text.trim().isEmpty ? null : _cpf.text.trim(),
        phone: _phone.text.trim(),
        address: _address.text.trim(),
        photoPath: _photoPath,
        latitude: _lat,
        longitude: _lng,
        notes: _notes.text.trim(),
        businessName:
            _businessName.text.trim().isEmpty ? null : _businessName.text.trim(),
        businessType: _businessType,
      );
      await ctrl.saveClient(updated);
    } else {
      await ctrl.createClient(
        name: _name.text.trim(),
        document: _document.text.trim(),
        cpf: _cpf.text.trim().isEmpty ? null : _cpf.text.trim(),
        phone: _phone.text.trim(),
        address: _address.text.trim(),
        photoPath: _photoPath,
        latitude: _lat,
        longitude: _lng,
        notes: _notes.text.trim(),
        businessName:
            _businessName.text.trim().isEmpty ? null : _businessName.text.trim(),
        businessType: _businessType,
      );
    }
    if (mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Scaffold(
      appBar: AppBar(
          title:
              Text(widget.existing == null ? 'Novo cliente' : 'Editar cliente')),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Center(
              child: Stack(
                children: [
                  CircleAvatar(
                    radius: 48,
                    backgroundColor: scheme.primaryContainer,
                    backgroundImage:
                        _photoPath != null && File(_photoPath!).existsSync()
                            ? FileImage(File(_photoPath!))
                            : null,
                    child: _photoPath == null
                        ? Icon(Icons.person,
                            size: 44, color: scheme.onPrimaryContainer)
                        : null,
                  ),
                  Positioned(
                    right: 0,
                    bottom: 0,
                    child: CircleAvatar(
                      radius: 16,
                      backgroundColor: scheme.primary,
                      child: IconButton(
                        iconSize: 16,
                        color: scheme.onPrimary,
                        icon: const Icon(Icons.camera_alt),
                        onPressed: _pickPhoto,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            _field(_name, 'Nome *', required: true),
            _field(_document, 'Documento (RG)'),
            _field(_cpf, 'CPF (opcional)',
                keyboard: TextInputType.number),
            _field(_phone, 'Telefone', keyboard: TextInputType.phone),
            _field(_address, 'Endereço'),
            const SizedBox(height: 8),
            _LocationTile(
              lat: _lat,
              lng: _lng,
              loading: _capturingGps,
              onCapture: _captureGps,
              onClear: () => setState(() {
                _lat = null;
                _lng = null;
              }),
            ),
            const SizedBox(height: 16),
            Text('Comércio (modalidade Diário)',
                style: Theme.of(context).textTheme.titleSmall),
            const SizedBox(height: 8),
            _field(_businessName, 'Nome do comércio'),
            DropdownButtonFormField<BusinessType>(
              value: _businessType,
              decoration: const InputDecoration(labelText: 'Tipo de comércio'),
              items: BusinessType.values
                  .map((t) =>
                      DropdownMenuItem(value: t, child: Text(t.label)))
                  .toList(),
              onChanged: (v) => setState(() => _businessType = v),
            ),
            const SizedBox(height: 12),
            _field(_notes, 'Observações', maxLines: 3),
            const SizedBox(height: 24),
            FilledButton.icon(
              onPressed: _save,
              icon: const Icon(Icons.save),
              label: const Text('Salvar cliente'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _field(TextEditingController c, String label,
      {bool required = false,
      TextInputType? keyboard,
      int maxLines = 1}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: TextFormField(
        controller: c,
        keyboardType: keyboard,
        maxLines: maxLines,
        decoration: InputDecoration(labelText: label),
        validator: required
            ? (v) => (v == null || v.trim().isEmpty) ? 'Obrigatório' : null
            : null,
      ),
    );
  }
}

class _LocationTile extends StatelessWidget {
  const _LocationTile({
    required this.lat,
    required this.lng,
    required this.loading,
    required this.onCapture,
    required this.onClear,
  });

  final double? lat;
  final double? lng;
  final bool loading;
  final VoidCallback onCapture;
  final VoidCallback onClear;

  @override
  Widget build(BuildContext context) {
    final has = lat != null && lng != null;
    return Card(
      child: ListTile(
        leading: const Icon(Icons.my_location),
        title: Text(has
            ? '${lat!.toStringAsFixed(5)}, ${lng!.toStringAsFixed(5)}'
            : 'Localização não definida'),
        subtitle: const Text('GPS do cliente'),
        trailing: loading
            ? const SizedBox(
                width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
            : Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (has)
                    IconButton(
                        onPressed: onClear, icon: const Icon(Icons.clear)),
                  IconButton(
                      onPressed: onCapture,
                      icon: const Icon(Icons.gps_fixed)),
                ],
              ),
      ),
    );
  }
}
