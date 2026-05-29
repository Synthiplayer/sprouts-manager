import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sprouts_manager/core/formatters/currency_formatter.dart';

import '../../application/location_list_notifier.dart';
import '../../domain/location_enums.dart';
import '../../domain/location_gema_profile.dart';
import '../../domain/location_model.dart';
import '../../domain/location_setup.dart';

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
                  if (location.standingCapacity > 0) Text('Max. stehend: ${location.standingCapacity}'),
                  if (location.seatingCapacity > 0) Text('Max. sitzend: ${location.seatingCapacity}'),
                  if (location.eventRelevantGemaProfiles.isNotEmpty)
                    Text(
                      'GEMA: ${location.eventRelevantGemaProfiles.map((e) => e.areaName).join(', ')}',
                    )
                  else
                    const Text('GEMA: Keine eventrelevanten Bereiche'),
                  const SizedBox(height: 6),
                  if (location.setups.isEmpty)
                    const Text('Setups: Keine hinterlegt')
                  else ...[
                    const Text('Setups:'),
                    const SizedBox(height: 4),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: location.setups.map((setup) => Chip(label: Text(setup.name))).toList(),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Standardmiete (erstes Setup): ${formatEuro(location.setups.first.defaultBaseRent)}',
                    ),
                  ],
                ],
              ),
            ),
          );
        },
      ),
    );
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
  late final TextEditingController _authorityNoteController;
  late final TextEditingController _infrastructureNoteController;
  late final TextEditingController _parkingNoteController;
  late final TextEditingController _accessNoteController;
  late final TextEditingController _securityReviewNoteController;

  bool _isIndoor = true;
  bool _isOutdoor = false;
  bool _isAccessible = false;
  bool _requiresToiletTrailer = false;
  bool _requiresFirstAid = false;
  bool _requiresBarriers = false;
  bool _requiresStage = false;
  bool _requiresTechnicalSetup = false;
  bool _hasCateringRestriction = false;

  AssemblyVenueReviewStatus _assemblyStatus = AssemblyVenueReviewStatus.unclear;
  late List<LocationGemaProfile> _gemaProfiles;
  late List<LocationSetup> _setups;

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
    _authorityNoteController = TextEditingController(text: current?.authorityNote ?? '');
    _infrastructureNoteController = TextEditingController(text: current?.infrastructureNote ?? '');
    _parkingNoteController = TextEditingController(text: current?.parkingNote ?? '');
    _accessNoteController = TextEditingController(text: current?.accessNote ?? '');
    _securityReviewNoteController = TextEditingController(
      text: current?.securityReviewNote ?? 'Securitybedarf je Event prüfen.',
    );
    _isIndoor = current?.isIndoor ?? true;
    _isOutdoor = current?.isOutdoor ?? false;
    _isAccessible = current?.isAccessible ?? false;
    _requiresToiletTrailer = current?.requiresToiletTrailer ?? false;
    _requiresFirstAid = current?.requiresFirstAid ?? false;
    _requiresBarriers = current?.requiresBarriers ?? false;
    _requiresStage = current?.requiresStage ?? false;
    _requiresTechnicalSetup = current?.requiresTechnicalSetup ?? false;
    _hasCateringRestriction = current?.hasCateringRestriction ?? false;
    _assemblyStatus = current?.assemblyVenueReviewStatus ?? AssemblyVenueReviewStatus.unclear;
    _gemaProfiles = [...(current?.gemaProfiles ?? const [])];
    _setups = [...(current?.setups ?? const [])];
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
    _authorityNoteController.dispose();
    _infrastructureNoteController.dispose();
    _parkingNoteController.dispose();
    _accessNoteController.dispose();
    _securityReviewNoteController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.existing == null ? 'Location hinzufügen' : 'Location bearbeiten'),
      content: SizedBox(
        width: 760,
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _section('Basisdaten'),
              _text(_nameController, 'Name'),
              _text(_streetController, 'Straße'),
              Row(
                children: [
                  Expanded(child: _text(_zipController, 'PLZ')),
                  const SizedBox(width: 8),
                  Expanded(child: _text(_cityController, 'Stadt')),
                ],
              ),
              _text(_descriptionController, 'Beschreibung'),
              _switch('Indoor', _isIndoor, (v) => setState(() => _isIndoor = v)),
              _switch('Outdoor', _isOutdoor, (v) => setState(() => _isOutdoor = v)),
              _switch('Barrierefrei', _isAccessible, (v) => setState(() => _isAccessible = v)),
              _section('Kapazität'),
              Row(
                children: [
                  Expanded(child: _text(_standingController, 'Max. Stehplätze', isNumber: true)),
                  const SizedBox(width: 8),
                  Expanded(child: _text(_seatingController, 'Max. Sitzplätze', isNumber: true)),
                ],
              ),

              _text(_mixedNoteController, 'Kapazitäts-/Bestuhlungshinweis'),
              _section('Prüf-/Behördennotizen'),
              DropdownButtonFormField<AssemblyVenueReviewStatus>(
                initialValue: _assemblyStatus,
                decoration: const InputDecoration(
                  labelText: 'Versammlungsstätten-Status',
                  border: OutlineInputBorder(),
                ),
                items: AssemblyVenueReviewStatus.values
                    .map((value) => DropdownMenuItem(value: value, child: Text(_assemblyLabel(value))))
                    .toList(),
                onChanged: (value) {
                  if (value != null) setState(() => _assemblyStatus = value);
                },
              ),
              const SizedBox(height: 8),
              _text(_authorityNoteController, 'Behördenhinweis'),
              _section('Setups'),
              ..._setups.asMap().entries.map((entry) {
                final setup = entry.value;
                final setupIndex = entry.key;
                final gemaLabel = _gemaProfileNameById(setup.defaultGemaProfileId);
                return Card(
                  child: ListTile(
                    title: Text(setup.name),
                    subtitle: Text(
                      '${_setupTypeLabel(setup.setupType)} | Kapazität: ${setup.capacity} | '
                      'Standardmiete: ${formatEuro(setup.defaultBaseRent)} | '
                      'GEMA: $gemaLabel (${_gemaEventTypeLabel(setup.defaultGemaEventType)})',
                    ),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          icon: const Icon(Icons.edit),
                          onPressed: () async {
                            final updated = await _showSetupDialog(existing: setup);
                            if (updated != null) {
                              setState(() => _setups[setupIndex] = updated);
                            }
                          },
                        ),
                        IconButton(
                          icon: const Icon(Icons.delete, color: Colors.red),
                          onPressed: () => setState(() => _setups.removeAt(setupIndex)),
                        ),
                      ],
                    ),
                  ),
                );
              }),
              TextButton.icon(
                onPressed: () async {
                  final created = await _showSetupDialog();
                  if (created != null) {
                    setState(() => _setups.add(created));
                  }
                },
                icon: const Icon(Icons.add),
                label: const Text('Setup hinzufügen'),
              ),
              _section('Zusatzanforderungen'),
              _switch('Toilettenwagen erforderlich', _requiresToiletTrailer, (v) => setState(() => _requiresToiletTrailer = v)),
              _switch('Erste Hilfe erforderlich', _requiresFirstAid, (v) => setState(() => _requiresFirstAid = v)),
              _switch('Absperrgitter erforderlich', _requiresBarriers, (v) => setState(() => _requiresBarriers = v)),
              _switch('Bühne erforderlich', _requiresStage, (v) => setState(() => _requiresStage = v)),
              _switch('Technik-Setup erforderlich', _requiresTechnicalSetup, (v) => setState(() => _requiresTechnicalSetup = v)),
              _switch('Catering-Einschränkung', _hasCateringRestriction, (v) => setState(() => _hasCateringRestriction = v)),
              _text(_securityReviewNoteController, 'Security-Hinweis (eventbezogen prüfen)'),
              _section('Hinweise'),
              _text(_infrastructureNoteController, 'Infrastruktur Hinweis'),
              _text(_parkingNoteController, 'Parken Hinweis'),
              _text(_accessNoteController, 'Zugang Hinweis'),
              _section('GEMA-Profile'),
              ..._gemaProfiles.asMap().entries.map((entry) {
                final index = entry.key;
                final profile = entry.value;
                return Card(
                  child: ListTile(
                    title: Text(profile.areaName),
                    subtitle: Text(
                      profile.isEventArea
                          ? 'Eventbereich, Konzert: ${formatEuro(profile.concertFee)}, '
                              'Party: ${formatEuro(profile.partyFee)}, '
                              'Geschl. Gesellschaft: ${formatEuro(profile.privateEventFee)}'
                          : 'Nicht eventrelevant',
                    ),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          icon: const Icon(Icons.edit),
                          onPressed: () async {
                            final updated = await _showGemaDialog(existing: profile);
                            if (updated != null) {
                              setState(() => _gemaProfiles[index] = updated);
                            }
                          },
                        ),
                        IconButton(
                          icon: const Icon(Icons.delete, color: Colors.red),
                          onPressed: () => setState(() => _gemaProfiles.removeAt(index)),
                        ),
                      ],
                    ),
                  ),
                );
              }),
              TextButton.icon(
                onPressed: () async {
                  final created = await _showGemaDialog();
                  if (created != null) {
                    setState(() => _gemaProfiles.add(created));
                  }
                },
                icon: const Icon(Icons.add),
                label: const Text('GEMA-Bereich hinzufügen'),
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text('Abbrechen')),
        FilledButton(
          onPressed: () {
            Navigator.of(context).pop(
              LocationModel(
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
                assemblyVenueReviewStatus: _assemblyStatus,
                authorityNote: _authorityNoteController.text.trim(),
                requiresToiletTrailer: _requiresToiletTrailer,
                requiresFirstAid: _requiresFirstAid,
                requiresBarriers: _requiresBarriers,
                requiresStage: _requiresStage,
                requiresTechnicalSetup: _requiresTechnicalSetup,
                hasCateringRestriction: _hasCateringRestriction,
                securityReviewNote: _securityReviewNoteController.text.trim(),
                infrastructureNote: _infrastructureNoteController.text.trim(),
                parkingNote: _parkingNoteController.text.trim(),
                accessNote: _accessNoteController.text.trim(),
                gemaProfiles: _gemaProfiles,
                setups: _setups,
              ),
            );
          },
          child: const Text('Speichern'),
        ),
      ],
    );
  }

  Future<LocationSetup?> _showSetupDialog({LocationSetup? existing}) {
    final nameController = TextEditingController(text: existing?.name ?? '');
    final capacityController = TextEditingController(text: '${existing?.capacity ?? 0}');
    final rentController = TextEditingController(text: _formatEuroInput(existing?.defaultBaseRent ?? 0));
    final securityController = TextEditingController(text: existing?.securityNote ?? '');
    final technicalController = TextEditingController(text: existing?.technicalNote ?? '');
    final seatingController = TextEditingController(text: existing?.seatingNote ?? '');
    final costController = TextEditingController(text: existing?.costNote ?? '');
    final generalController = TextEditingController(text: existing?.generalNote ?? '');
    var setupType = existing?.setupType ?? LocationSetupType.custom;
    var gemaType = existing?.defaultGemaEventType ?? GemaEventType.none;
    String? gemaProfileId = existing?.defaultGemaProfileId;
    if (_gemaProfiles.isNotEmpty) {
      gemaProfileId ??= _gemaProfiles.first.id;
    }

    return showDialog<LocationSetup>(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: Text(existing == null ? 'Setup hinzufügen' : 'Setup bearbeiten'),
              content: SizedBox(
                width: 620,
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      _text(nameController, 'Name'),
                      DropdownButtonFormField<LocationSetupType>(
                        initialValue: setupType,
                        decoration: const InputDecoration(labelText: 'Setup-Typ', border: OutlineInputBorder()),
                        items: LocationSetupType.values
                            .map((value) => DropdownMenuItem(value: value, child: Text(_setupTypeLabel(value))))
                            .toList(),
                        onChanged: (value) {
                          if (value != null) setDialogState(() => setupType = value);
                        },
                      ),
                      const SizedBox(height: 8),
                      _text(capacityController, 'Kapazität', isNumber: true),
                      _text(rentController, 'Standard-Grundmiete', isNumber: true, suffixText: 'EUR'),
                      DropdownButtonFormField<String>(
                        initialValue: gemaProfileId,
                        decoration: const InputDecoration(labelText: 'Standard-GEMA-Profil', border: OutlineInputBorder()),
                        items: _gemaProfiles
                            .map((value) => DropdownMenuItem(value: value.id, child: Text(value.areaName)))
                            .toList(),
                        onChanged: (value) {
                          if (value != null) setDialogState(() => gemaProfileId = value);
                        },
                      ),
                      const SizedBox(height: 8),
                      DropdownButtonFormField<GemaEventType>(
                        initialValue: gemaType,
                        decoration: const InputDecoration(labelText: 'Standard-GEMA-Art', border: OutlineInputBorder()),
                        items: GemaEventType.values
                            .map((value) => DropdownMenuItem(value: value, child: Text(_gemaEventTypeLabel(value))))
                            .toList(),
                        onChanged: (value) {
                          if (value != null) setDialogState(() => gemaType = value);
                        },
                      ),
                      const SizedBox(height: 8),
                      _text(securityController, 'Security-Hinweis'),
                      _text(technicalController, 'Technik-Hinweis'),
                      _text(seatingController, 'Bestuhlungs-Hinweis'),
                      _text(costController, 'Kosten-Hinweis'),
                      _text(generalController, 'Allgemeiner Hinweis'),
                    ],
                  ),
                ),
              ),
              actions: [
                TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text('Abbrechen')),
                FilledButton(
                  onPressed: () {
                    Navigator.of(context).pop(
                      LocationSetup(
                        id: existing?.id ?? 'setup_${DateTime.now().millisecondsSinceEpoch}',
                        name: nameController.text.trim(),
                        setupType: setupType,
                        capacity: int.tryParse(capacityController.text) ?? 0,
                        defaultBaseRent: parseEuroInput(rentController.text),
                        defaultGemaProfileId: gemaProfileId ?? '',
                        defaultGemaEventType: gemaType,
                        securityNote: securityController.text.trim(),
                        technicalNote: technicalController.text.trim(),
                        seatingNote: seatingController.text.trim(),
                        costNote: costController.text.trim(),
                        generalNote: generalController.text.trim(),
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

  Future<LocationGemaProfile?> _showGemaDialog({LocationGemaProfile? existing}) {
    final areaController = TextEditingController(text: existing?.areaName ?? '');
    final allowedController = TextEditingController(text: '${existing?.allowedPersons ?? 0}');
    final sizeController = TextEditingController(text: '${existing?.areaSizeSqm ?? 0}');
    final concertController = TextEditingController(text: _formatEuroInput(existing?.concertFee ?? 0));
    final partyController = TextEditingController(text: _formatEuroInput(existing?.partyFee ?? 0));
    final privateController = TextEditingController(text: _formatEuroInput(existing?.privateEventFee ?? 0));
    final notesController = TextEditingController(text: existing?.notes ?? '');
    var isEventArea = existing?.isEventArea ?? true;

    return showDialog<LocationGemaProfile>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: Text(existing == null ? 'GEMA-Bereich hinzufügen' : 'GEMA-Bereich bearbeiten'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _text(areaController, 'Bereichsname'),
                SwitchListTile(
                  value: isEventArea,
                  title: const Text('Für Veranstaltungsgäste relevant'),
                  onChanged: (value) => setDialogState(() => isEventArea = value),
                ),
                _text(allowedController, 'Zugelassene Personen', isNumber: true),
                _text(sizeController, 'Fläche (qm)', isNumber: true),
                _text(concertController, 'Konzert-Gebühr', isNumber: true, suffixText: 'EUR'),
                _text(partyController, 'Party-Gebühr', isNumber: true, suffixText: 'EUR'),
                _text(privateController, 'Gebühr geschl. Gesellschaft', isNumber: true, suffixText: 'EUR'),
                _text(notesController, 'Hinweis'),
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text('Abbrechen')),
            FilledButton(
              onPressed: () {
                Navigator.of(context).pop(
                  LocationGemaProfile(
                    id: existing?.id ?? 'gema_${DateTime.now().millisecondsSinceEpoch}',
                    areaName: areaController.text.trim(),
                    isEventArea: isEventArea,
                    allowedPersons: int.tryParse(allowedController.text) ?? 0,
                    areaSizeSqm: parseEuroInput(sizeController.text),
                    concertFee: parseEuroInput(concertController.text),
                    partyFee: parseEuroInput(partyController.text),
                    privateEventFee: parseEuroInput(privateController.text),
                    notes: notesController.text.trim(),
                  ),
                );
              },
              child: const Text('Übernehmen'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _text(TextEditingController controller, String label, {bool isNumber = false, String? suffixText}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: TextField(
        controller: controller,
        keyboardType: isNumber ? const TextInputType.numberWithOptions(decimal: true) : TextInputType.text,
        decoration: InputDecoration(labelText: label, suffixText: suffixText, border: const OutlineInputBorder()),
      ),
    );
  }

  Widget _switch(String label, bool value, ValueChanged<bool> onChanged) {
    return SwitchListTile(value: value, title: Text(label), onChanged: onChanged);
  }

  Widget _section(String title) {
    return Padding(
      padding: const EdgeInsets.only(top: 12, bottom: 8),
      child: Text(title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
    );
  }

  String _assemblyLabel(AssemblyVenueReviewStatus status) {
    switch (status) {
      case AssemblyVenueReviewStatus.notRelevant:
        return 'Nicht relevant';
      case AssemblyVenueReviewStatus.approvedBelowThreshold:
        return 'Genehmigt unter Schwelle';
      case AssemblyVenueReviewStatus.approvedAsAssemblyVenue:
        return 'Als Versammlungsstätte genehmigt';
      case AssemblyVenueReviewStatus.needsReview:
        return 'Prüfung erforderlich';
      case AssemblyVenueReviewStatus.unclear:
        return 'Unklar';
    }
  }

  String _setupTypeLabel(LocationSetupType type) {
    switch (type) {
      case LocationSetupType.standingParty:
        return 'Stehparty';
      case LocationSetupType.seatedConcert:
        return 'Konzert bestuhlt';
      case LocationSetupType.standingConcert:
        return 'Konzert stehend';
      case LocationSetupType.movieNight:
        return 'Filmabend';
      case LocationSetupType.dinner:
        return 'Dinnerparty';
      case LocationSetupType.publicViewing:
        return 'Public Viewing';
      case LocationSetupType.privateEvent:
        return 'Geschlossene Gesellschaft';
      case LocationSetupType.seminar:
        return 'Seminar';
      case LocationSetupType.custom:
        return 'Individuell';
    }
  }

  String _gemaEventTypeLabel(GemaEventType type) {
    switch (type) {
      case GemaEventType.concert:
        return 'Konzert';
      case GemaEventType.party:
        return 'Party';
      case GemaEventType.privateEvent:
        return 'Geschlossene Gesellschaft';
      case GemaEventType.none:
        return 'Keine';
      case GemaEventType.custom:
        return 'Sonderfall';
    }
  }

  String _gemaProfileNameById(String id) {
    for (final profile in _gemaProfiles) {
      if (profile.id == id) return profile.areaName;
    }
    return 'Nicht gesetzt';
  }

  String _formatEuroInput(double value) {
    return formatEuro(value).replaceAll(' EUR', '');
  }
}



