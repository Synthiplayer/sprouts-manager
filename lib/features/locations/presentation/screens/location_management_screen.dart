import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../application/location_list_notifier.dart';
import '../../domain/location_gema_profile.dart';
import '../../domain/location_model.dart';

class LocationManagementScreen extends ConsumerWidget {
  const LocationManagementScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final locations = ref.watch(locationListProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Location-Verwaltung')),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () async {
          final created = await showDialog<LocationModel>(
            context: context,
            builder: (_) => const LocationEditDialog(),
          );
          if (created != null) {
            ref.read(locationListProvider.notifier).addLocation(created);
          }
        },
        icon: const Icon(Icons.add),
        label: const Text('Location hinzufügen'),
      ),
      body: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: locations.length,
        itemBuilder: (context, index) {
          final location = locations[index];
          final gemaEventAreas = location.eventRelevantGemaProfiles;

          return Card(
            margin: const EdgeInsets.only(bottom: 12),
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          location.name,
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.edit),
                        onPressed: () async {
                          final updated = await showDialog<LocationModel>(
                            context: context,
                            builder: (_) => LocationEditDialog(existing: location),
                          );
                          if (updated != null) {
                            ref.read(locationListProvider.notifier).updateLocation(updated);
                          }
                        },
                      ),
                      IconButton(
                        icon: const Icon(Icons.delete, color: Colors.red),
                        onPressed: () {
                          ref.read(locationListProvider.notifier).deleteLocation(location.id);
                        },
                      ),
                    ],
                  ),
                  Text('${location.zipCode} ${location.city}'),
                  const SizedBox(height: 4),
                  Text(
                    'Stehplätze: ${location.standingCapacity} | Sitzplätze: ${location.seatingCapacity}',
                  ),
                  Text('Grundmiete: ${location.baseRent.toStringAsFixed(2)} EVC'),
                  Text('Umsatzbeteiligung: ${location.revenueSharePercent.toStringAsFixed(1)} %'),
                  const SizedBox(height: 6),
                  Text(
                    gemaEventAreas.isNotEmpty
                        ? 'GEMA: ${gemaEventAreas.map((e) => e.areaName).join(', ')}'
                        : 'GEMA: Keine eventrelevanten Bereiche',
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: _buildRequirementChips(location),
                  ),
                  if (location.description.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    Text(location.description),
                  ],
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  List<Widget> _buildRequirementChips(LocationModel location) {
    final chips = <Widget>[];

    void addChip(bool visible, String label) {
      if (visible) {
        chips.add(Chip(label: Text(label)));
      }
    }

    addChip(location.requiresToiletTrailer, 'Toilettenwagen');
    addChip(location.requiresFirstAid, 'Erste Hilfe');
    addChip(location.requiresSecurity, 'Security');
    addChip(location.requiresBarriers, 'Absperrgitter');
    addChip(location.requiresStage, 'Bühne');
    addChip(location.requiresTechnicalSetup, 'Technik-Setup');
    addChip(location.hasCateringRestriction, 'Catering-Einschränkung');

    if (chips.isEmpty) {
      chips.add(const Chip(label: Text('Keine besonderen Anforderungen')));
    }

    return chips;
  }
}

class LocationEditDialog extends StatefulWidget {
  final LocationModel? existing;

  const LocationEditDialog({super.key, this.existing});

  @override
  State<LocationEditDialog> createState() => _LocationEditDialogState();
}

class _LocationEditDialogState extends State<LocationEditDialog> {
  late final TextEditingController _nameController;
  late final TextEditingController _streetController;
  late final TextEditingController _zipController;
  late final TextEditingController _cityController;
  late final TextEditingController _descriptionController;

  late final TextEditingController _standingController;
  late final TextEditingController _seatingController;
  late final TextEditingController _mixedNoteController;

  late final TextEditingController _baseRentController;
  late final TextEditingController _revenueShareController;
  late final TextEditingController _minimumRentController;
  late final TextEditingController _depositController;
  late final TextEditingController _cleaningFeeController;
  late final TextEditingController _utilityFeeController;
  late final TextEditingController _variableCostNoteController;

  late final TextEditingController _infrastructureNoteController;
  late final TextEditingController _parkingNoteController;
  late final TextEditingController _accessNoteController;

  bool _isIndoor = true;
  bool _isOutdoor = false;
  bool _isAccessible = false;

  bool _requiresToiletTrailer = false;
  bool _requiresFirstAid = false;
  bool _requiresSecurity = false;
  bool _requiresBarriers = false;
  bool _requiresStage = false;
  bool _requiresTechnicalSetup = false;
  bool _hasCateringRestriction = false;

  late List<LocationGemaProfile> _gemaProfiles;

  @override
  void initState() {
    super.initState();
    final current = widget.existing;

    _nameController = TextEditingController(text: current?.name ?? '');
    _streetController = TextEditingController(text: current?.street ?? '');
    _zipController = TextEditingController(text: current?.zipCode ?? '');
    _cityController = TextEditingController(text: current?.city ?? '');
    _descriptionController = TextEditingController(text: current?.description ?? '');

    _standingController = TextEditingController(text: '${current?.standingCapacity ?? 0}');
    _seatingController = TextEditingController(text: '${current?.seatingCapacity ?? 0}');
    _mixedNoteController = TextEditingController(text: current?.mixedCapacityNote ?? '');

    _baseRentController = TextEditingController(text: '${current?.baseRent ?? 0}');
    _revenueShareController = TextEditingController(text: '${current?.revenueSharePercent ?? 0}');
    _minimumRentController = TextEditingController(text: '${current?.minimumRent ?? 0}');
    _depositController = TextEditingController(text: '${current?.deposit ?? 0}');
    _cleaningFeeController = TextEditingController(text: '${current?.cleaningFee ?? 0}');
    _utilityFeeController = TextEditingController(text: '${current?.utilityFee ?? 0}');
    _variableCostNoteController = TextEditingController(text: current?.variableCostNote ?? '');

    _infrastructureNoteController = TextEditingController(text: current?.infrastructureNote ?? '');
    _parkingNoteController = TextEditingController(text: current?.parkingNote ?? '');
    _accessNoteController = TextEditingController(text: current?.accessNote ?? '');

    _isIndoor = current?.isIndoor ?? true;
    _isOutdoor = current?.isOutdoor ?? false;
    _isAccessible = current?.isAccessible ?? false;

    _requiresToiletTrailer = current?.requiresToiletTrailer ?? false;
    _requiresFirstAid = current?.requiresFirstAid ?? false;
    _requiresSecurity = current?.requiresSecurity ?? false;
    _requiresBarriers = current?.requiresBarriers ?? false;
    _requiresStage = current?.requiresStage ?? false;
    _requiresTechnicalSetup = current?.requiresTechnicalSetup ?? false;
    _hasCateringRestriction = current?.hasCateringRestriction ?? false;

    _gemaProfiles = [...(current?.gemaProfiles ?? const [])];
  }

  @override
  void dispose() {
    _nameController.dispose();
    _streetController.dispose();
    _zipController.dispose();
    _cityController.dispose();
    _descriptionController.dispose();
    _standingController.dispose();
    _seatingController.dispose();
    _mixedNoteController.dispose();
    _baseRentController.dispose();
    _revenueShareController.dispose();
    _minimumRentController.dispose();
    _depositController.dispose();
    _cleaningFeeController.dispose();
    _utilityFeeController.dispose();
    _variableCostNoteController.dispose();
    _infrastructureNoteController.dispose();
    _parkingNoteController.dispose();
    _accessNoteController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.existing == null ? 'Location hinzufügen' : 'Location bearbeiten'),
      content: SizedBox(
        width: 720,
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildSectionTitle('Basisdaten'),
              _textField(_nameController, 'Name'),
              _textField(_streetController, 'Straße'),
              Row(
                children: [
                  Expanded(child: _textField(_zipController, 'PLZ')),
                  const SizedBox(width: 8),
                  Expanded(child: _textField(_cityController, 'Stadt')),
                ],
              ),
              _textField(_descriptionController, 'Beschreibung'),
              SwitchListTile(
                value: _isIndoor,
                title: const Text('Indoor'),
                onChanged: (value) => setState(() => _isIndoor = value),
              ),
              SwitchListTile(
                value: _isOutdoor,
                title: const Text('Outdoor'),
                onChanged: (value) => setState(() => _isOutdoor = value),
              ),
              SwitchListTile(
                value: _isAccessible,
                title: const Text('Barrierefrei'),
                onChanged: (value) => setState(() => _isAccessible = value),
              ),

              _buildSectionTitle('Kapazität'),
              Row(
                children: [
                  Expanded(child: _textField(_standingController, 'Stehplätze', isNumber: true)),
                  const SizedBox(width: 8),
                  Expanded(child: _textField(_seatingController, 'Sitzplätze', isNumber: true)),
                ],
              ),
              _textField(_mixedNoteController, 'Mischkapazität Hinweis'),

              _buildSectionTitle('Kostenmodell'),
              _textField(_baseRentController, 'Grundmiete', isNumber: true),
              _textField(_revenueShareController, 'Umsatzbeteiligung (%)', isNumber: true),
              _textField(_minimumRentController, 'Mindestmiete', isNumber: true),
              _textField(_depositController, 'Kaution', isNumber: true),
              _textField(_cleaningFeeController, 'Reinigungsgebühr', isNumber: true),
              _textField(_utilityFeeController, 'Nebenkosten', isNumber: true),
              _textField(_variableCostNoteController, 'Variable Kosten Hinweis'),

              _buildSectionTitle('Zusatzanforderungen'),
              _switch('Toilettenwagen erforderlich', _requiresToiletTrailer,
                  (v) => setState(() => _requiresToiletTrailer = v)),
              _switch('Erste Hilfe erforderlich', _requiresFirstAid,
                  (v) => setState(() => _requiresFirstAid = v)),
              _switch('Security erforderlich', _requiresSecurity,
                  (v) => setState(() => _requiresSecurity = v)),
              _switch('Absperrgitter erforderlich', _requiresBarriers,
                  (v) => setState(() => _requiresBarriers = v)),
              _switch('Bühne erforderlich', _requiresStage,
                  (v) => setState(() => _requiresStage = v)),
              _switch('Technik-Setup erforderlich', _requiresTechnicalSetup,
                  (v) => setState(() => _requiresTechnicalSetup = v)),
              _switch('Catering-Einschränkung', _hasCateringRestriction,
                  (v) => setState(() => _hasCateringRestriction = v)),

              _buildSectionTitle('Hinweise'),
              _textField(_infrastructureNoteController, 'Infrastruktur Hinweis'),
              _textField(_parkingNoteController, 'Parken Hinweis'),
              _textField(_accessNoteController, 'Zugang Hinweis'),

              _buildSectionTitle('GEMA-Profile'),
              ..._gemaProfiles.asMap().entries.map((entry) {
                final index = entry.key;
                final profile = entry.value;
                return Card(
                  child: ListTile(
                    title: Text(profile.areaName),
                    subtitle: Text(
                      profile.isEventArea
                          ? 'Eventbereich, Personen: ${profile.allowedPersons}, Konzert: ${profile.concertFee}'
                          : 'Nicht eventrelevant',
                    ),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          icon: const Icon(Icons.edit),
                          onPressed: () async {
                            final updated = await _showGemaProfileDialog(existing: profile);
                            if (updated != null) {
                              setState(() => _gemaProfiles[index] = updated);
                            }
                          },
                        ),
                        IconButton(
                          icon: const Icon(Icons.delete, color: Colors.red),
                          onPressed: () {
                            setState(() => _gemaProfiles.removeAt(index));
                          },
                        ),
                      ],
                    ),
                  ),
                );
              }),
              Align(
                alignment: Alignment.centerLeft,
                child: TextButton.icon(
                  onPressed: () async {
                    final created = await _showGemaProfileDialog();
                    if (created != null) {
                      setState(() => _gemaProfiles.add(created));
                    }
                  },
                  icon: const Icon(Icons.add),
                  label: const Text('GEMA-Bereich hinzufügen'),
                ),
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Abbrechen'),
        ),
        FilledButton(
          onPressed: () {
            final model = LocationModel(
              id: widget.existing?.id ?? 'loc_${DateTime.now().millisecondsSinceEpoch}',
              name: _nameController.text.trim(),
              street: _streetController.text.trim(),
              zipCode: _zipController.text.trim(),
              city: _cityController.text.trim(),
              description: _descriptionController.text.trim(),
              isIndoor: _isIndoor,
              isOutdoor: _isOutdoor,
              isAccessible: _isAccessible,
              standingCapacity: int.tryParse(_standingController.text) ?? 0,
              seatingCapacity: int.tryParse(_seatingController.text) ?? 0,
              mixedCapacityNote: _mixedNoteController.text.trim(),
              baseRent: _toDouble(_baseRentController.text),
              revenueSharePercent: _toDouble(_revenueShareController.text),
              minimumRent: _toDouble(_minimumRentController.text),
              deposit: _toDouble(_depositController.text),
              cleaningFee: _toDouble(_cleaningFeeController.text),
              utilityFee: _toDouble(_utilityFeeController.text),
              variableCostNote: _variableCostNoteController.text.trim(),
              requiresToiletTrailer: _requiresToiletTrailer,
              requiresFirstAid: _requiresFirstAid,
              requiresSecurity: _requiresSecurity,
              requiresBarriers: _requiresBarriers,
              requiresStage: _requiresStage,
              requiresTechnicalSetup: _requiresTechnicalSetup,
              hasCateringRestriction: _hasCateringRestriction,
              infrastructureNote: _infrastructureNoteController.text.trim(),
              parkingNote: _parkingNoteController.text.trim(),
              accessNote: _accessNoteController.text.trim(),
              gemaProfiles: _gemaProfiles,
            );
            Navigator.of(context).pop(model);
          },
          child: const Text('Speichern'),
        ),
      ],
    );
  }

  Future<LocationGemaProfile?> _showGemaProfileDialog({LocationGemaProfile? existing}) {
    final areaController = TextEditingController(text: existing?.areaName ?? '');
    final allowedController = TextEditingController(text: '${existing?.allowedPersons ?? 0}');
    final sizeController = TextEditingController(text: '${existing?.areaSizeSqm ?? 0}');
    final concertController = TextEditingController(text: '${existing?.concertFee ?? 0}');
    final partyController = TextEditingController(text: '${existing?.partyFee ?? 0}');
    final privateController = TextEditingController(text: '${existing?.privateEventFee ?? 0}');
    final notesController = TextEditingController(text: existing?.notes ?? '');
    bool isEventArea = existing?.isEventArea ?? true;

    return showDialog<LocationGemaProfile>(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setLocalState) {
            return AlertDialog(
              title: Text(existing == null ? 'GEMA-Bereich hinzufügen' : 'GEMA-Bereich bearbeiten'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _textField(areaController, 'Bereichsname'),
                    SwitchListTile(
                      value: isEventArea,
                      title: const Text('Für Veranstaltungsgäste relevant'),
                      onChanged: (value) => setLocalState(() => isEventArea = value),
                    ),
                    _textField(allowedController, 'Zugelassene Personen', isNumber: true),
                    _textField(sizeController, 'Fläche (qm)', isNumber: true),
                    _textField(concertController, 'Konzert-Gebühr', isNumber: true),
                    _textField(partyController, 'Party-Gebühr', isNumber: true),
                    _textField(privateController, 'Gebühr geschl. Gesellschaft', isNumber: true),
                    _textField(notesController, 'Hinweis'),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('Abbrechen'),
                ),
                FilledButton(
                  onPressed: () {
                    Navigator.of(context).pop(
                      LocationGemaProfile(
                        id: existing?.id ?? 'gema_${DateTime.now().millisecondsSinceEpoch}',
                        areaName: areaController.text.trim(),
                        isEventArea: isEventArea,
                        allowedPersons: int.tryParse(allowedController.text) ?? 0,
                        areaSizeSqm: _toDouble(sizeController.text),
                        concertFee: _toDouble(concertController.text),
                        partyFee: _toDouble(partyController.text),
                        privateEventFee: _toDouble(privateController.text),
                        notes: notesController.text.trim(),
                      ),
                    );
                  },
                  child: const Text('Übernehmen'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Widget _textField(TextEditingController controller, String label, {bool isNumber = false}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: TextField(
        controller: controller,
        keyboardType: isNumber
            ? const TextInputType.numberWithOptions(decimal: true)
            : TextInputType.text,
        decoration: InputDecoration(
          labelText: label,
          border: const OutlineInputBorder(),
        ),
      ),
    );
  }

  Widget _switch(String label, bool value, ValueChanged<bool> onChanged) {
    return SwitchListTile(
      value: value,
      title: Text(label),
      onChanged: onChanged,
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(top: 12, bottom: 8),
      child: Text(
        title,
        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
      ),
    );
  }

  double _toDouble(String raw) {
    return double.tryParse(raw.replaceAll(',', '.')) ?? 0;
  }
}
