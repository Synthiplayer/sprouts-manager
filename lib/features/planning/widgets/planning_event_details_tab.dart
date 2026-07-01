part of '../planning_screen.dart';

extension _PlanningEventDetailsTab on _PlanningScreenState {
  Widget _buildEventDetailsTab(BuildContext context, PlanningDraft draft) {
    final selectedScenario = _selectedScenario(draft);
    final locationBlock = _planningLocationBlock(draft, selectedScenario);
    final locationName = locationBlock?.name ?? selectedScenario.locationName;
    final locationAddress = locationBlock?.address.trim() ?? '';

    return _sectionCard(
      context,
      title: 'Eventdaten',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: [
              SizedBox(
                width: 420,
                child: TextFormField(
                  key: ValueKey('title-${draft.id}'),
                  initialValue: _draftTitle(draft),
                  decoration: const InputDecoration(labelText: 'Titel'),
                  onChanged: (value) => _updateDraftTextField(
                    draft.id,
                    _draftTitleOverrides,
                    value,
                  ),
                ),
              ),
              SizedBox(
                width: 280,
                child: DropdownButtonFormField<String>(
                  initialValue: _draftPlanningStatus(draft),
                  decoration: const InputDecoration(labelText: 'Planungsstatus'),
                  items: [
                    for (final status
                        in _PlanningScreenState._planningStatusOptions)
                      DropdownMenuItem(
                        value: status,
                        child: Text(status),
                      ),
                  ],
                  onChanged: (status) {
                    if (status == null) {
                      return;
                    }
                    _updateDraftTextField(
                      draft.id,
                      _draftPlanningStatusOverrides,
                      status,
                    );
                  },
                ),
              ),
              SizedBox(
                width: 220,
                child: DropdownButtonFormField<EventCategory>(
                  initialValue: _planningCategory(draft),
                  decoration: const InputDecoration(labelText: 'Kategorie'),
                  items: [
                    for (final category in EventCategory.values)
                      DropdownMenuItem(
                        value: category,
                        child: Text(category.label),
                      ),
                  ],
                  onChanged: (category) {
                    if (category == null) {
                      return;
                    }
                    _refreshPlanningUi(() {
                      _draftCategoryOverrides[draft.id] = category;
                    });
                    _savePlanningSandboxState();
                  },
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: [
              SizedBox(
                width: 220,
                child: DropdownButtonFormField<int>(
                  initialValue: _draftMinimumAge(draft),
                  decoration: const InputDecoration(labelText: 'Mindestalter'),
                  items: [
                    for (final age in _PlanningScreenState._minimumAgeOptions)
                      DropdownMenuItem(
                        value: age,
                        child: Text(age == 0 ? '0 Jahre' : '$age Jahre'),
                      ),
                  ],
                  onChanged: (age) {
                    if (age == null) {
                      return;
                    }
                    _refreshPlanningUi(() {
                      _draftMinimumAgeOverrides[draft.id] = age;
                    });
                    _savePlanningSandboxState();
                  },
                ),
              ),
              SizedBox(
                width: 420,
                child: InputDecorator(
                  decoration: const InputDecoration(labelText: 'Aktueller Ort'),
                  child: Text(
                    _locationDisplayText(locationName, locationAddress),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: [
              SizedBox(
                width: 180,
                child: TextFormField(
                  key: ValueKey('event-date-${draft.id}'),
                  initialValue: _draftEventDate(draft),
                  decoration: const InputDecoration(
                    labelText: 'Datum',
                    hintText: 'YYYY-MM-DD',
                  ),
                  onChanged: (value) => _updateDraftTextField(
                    draft.id,
                    _draftEventDateOverrides,
                    value,
                  ),
                ),
              ),
              SizedBox(
                width: 150,
                child: TextFormField(
                  key: ValueKey('start-time-${draft.id}'),
                  initialValue: _draftStartTime(draft),
                  decoration: const InputDecoration(
                    labelText: 'Startzeit',
                    hintText: 'HH:MM',
                  ),
                  onChanged: (value) => _updateDraftTextField(
                    draft.id,
                    _draftStartTimeOverrides,
                    value,
                  ),
                ),
              ),
              SizedBox(
                width: 150,
                child: TextFormField(
                  key: ValueKey('end-time-${draft.id}'),
                  initialValue: _draftEndTime(draft),
                  decoration: const InputDecoration(
                    labelText: 'Endzeit',
                    hintText: 'HH:MM',
                  ),
                  onChanged: (value) => _updateDraftTextField(
                    draft.id,
                    _draftEndTimeOverrides,
                    value,
                  ),
                ),
              ),
              SizedBox(
                width: 220,
                child: TextFormField(
                  key: ValueKey('registration-deadline-${draft.id}'),
                  initialValue: _draftRegistrationDeadline(draft),
                  decoration: const InputDecoration(
                    labelText: 'Anmeldeschluss',
                    hintText: 'YYYY-MM-DD',
                  ),
                  onChanged: (value) => _updateDraftTextField(
                    draft.id,
                    _draftRegistrationDeadlineOverrides,
                    value,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          TextFormField(
            key: ValueKey('format-${draft.id}'),
            initialValue: _draftFormat(draft),
            decoration: const InputDecoration(labelText: 'Untertitel / Format'),
            onChanged: (value) => _updateDraftTextField(
              draft.id,
              _draftFormatOverrides,
              value,
            ),
          ),
          const SizedBox(height: 14),
          TextFormField(
            key: ValueKey('description-${draft.id}'),
            initialValue: _draftShortDescription(draft),
            decoration: const InputDecoration(labelText: 'Kurzbeschreibung'),
            minLines: 3,
            maxLines: 5,
            onChanged: (value) => _updateDraftTextField(
              draft.id,
              _draftShortDescriptionOverrides,
              value,
            ),
          ),
          const SizedBox(height: 14),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _planningCategory(draft).toChip(),
              _pill(context, _draftPlanningStatus(draft)),
              _pill(context, _mainDecisionStatus(draft)),
            ],
          ),
          const SizedBox(height: 18),
          Align(
            alignment: Alignment.centerRight,
            child: FilledButton.icon(
              onPressed: () => _saveEventDetails(context),
              icon: const Icon(Icons.save_outlined),
              label: const Text('Speichern'),
            ),
          ),
        ],
      ),
    );
  }

  void _updateDraftTextField(
    String draftId,
    Map<String, String> overrides,
    String value,
  ) {
    _refreshPlanningUi(() {
      overrides[draftId] = value;
    });
    _savePlanningSandboxState();
  }

  Future<void> _saveEventDetails(BuildContext context) async {
    await _savePlanningSandboxState();
    if (!context.mounted) {
      return;
    }
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Eventdaten gespeichert.')),
    );
  }

  String _locationDisplayText(String locationName, String address) {
    if (address.isEmpty) {
      return locationName;
    }
    return '$locationName · $address';
  }
}
