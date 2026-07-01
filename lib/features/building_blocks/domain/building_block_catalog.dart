import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';

enum BuildingBlockCategory {
  location,
  technology,
  program,
  staff,
  cost,
  special,
}

enum BuildingBlockCostProfile {
  none,
  gema,
}

extension BuildingBlockCostProfileX on BuildingBlockCostProfile {
  String get label {
    switch (this) {
      case BuildingBlockCostProfile.none:
        return 'Allgemein';
      case BuildingBlockCostProfile.gema:
        return 'GEMA';
    }
  }
}

enum GemaMusicType {
  live,
  phonographic,
}

extension GemaMusicTypeX on GemaMusicType {
  String get label {
    switch (this) {
      case GemaMusicType.live:
        return 'Live';
      case GemaMusicType.phonographic:
        return 'Tonträger';
    }
  }
}

enum GemaAudienceType {
  public,
  closed,
}

extension GemaAudienceTypeX on GemaAudienceType {
  String get label {
    switch (this) {
      case GemaAudienceType.public:
        return 'Öffentlich';
      case GemaAudienceType.closed:
        return 'Geschlossen';
    }
  }
}

class BuildingBlockGemaConfig {
  final GemaMusicType musicType;
  final GemaAudienceType audienceType;

  const BuildingBlockGemaConfig({
    this.musicType = GemaMusicType.live,
    this.audienceType = GemaAudienceType.public,
  });

  BuildingBlockGemaConfig copyWith({
    GemaMusicType? musicType,
    GemaAudienceType? audienceType,
  }) {
    return BuildingBlockGemaConfig(
      musicType: musicType ?? this.musicType,
      audienceType: audienceType ?? this.audienceType,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'musicType': musicType.name,
      'audienceType': audienceType.name,
    };
  }

  factory BuildingBlockGemaConfig.fromJson(Map<String, dynamic> json) {
    return BuildingBlockGemaConfig(
      musicType: _gemaMusicTypeByName(json['musicType']?.toString()) ??
          GemaMusicType.live,
      audienceType:
          _gemaAudienceTypeByName(json['audienceType']?.toString()) ??
              GemaAudienceType.public,
    );
  }
}

extension BuildingBlockCategoryX on BuildingBlockCategory {
  String get label {
    switch (this) {
      case BuildingBlockCategory.location:
        return 'Location';
      case BuildingBlockCategory.technology:
        return 'Technik';
      case BuildingBlockCategory.program:
        return 'Programm';
      case BuildingBlockCategory.staff:
        return 'Personal';
      case BuildingBlockCategory.cost:
        return 'Kosten';
      case BuildingBlockCategory.special:
        return 'Special';
    }
  }

  Color get color {
    switch (this) {
      case BuildingBlockCategory.location:
        return Colors.blueGrey;
      case BuildingBlockCategory.technology:
        return Colors.indigo;
      case BuildingBlockCategory.program:
        return Colors.deepPurple;
      case BuildingBlockCategory.staff:
        return Colors.deepOrange;
      case BuildingBlockCategory.cost:
        return Colors.green;
      case BuildingBlockCategory.special:
        return Colors.teal;
    }
  }

  IconData get icon {
    switch (this) {
      case BuildingBlockCategory.location:
        return Icons.location_on_outlined;
      case BuildingBlockCategory.technology:
        return Icons.settings_input_component_outlined;
      case BuildingBlockCategory.program:
        return Icons.local_activity_outlined;
      case BuildingBlockCategory.staff:
        return Icons.groups_outlined;
      case BuildingBlockCategory.cost:
        return Icons.receipt_long_outlined;
      case BuildingBlockCategory.special:
        return Icons.auto_awesome_outlined;
    }
  }
}

class BuildingBlock {
  final String id;
  final String name;
  final BuildingBlockCategory category;
  final BuildingBlockCostProfile costProfile;
  final double defaultAmountEur;
  final String note;
  final String address;
  final List<BuildingBlockArea> areas;
  final Set<String> selectedAreaNames;
  final BuildingBlockGemaConfig? gemaConfig;

  const BuildingBlock({
    required this.id,
    required this.name,
    required this.category,
    this.costProfile = BuildingBlockCostProfile.none,
    required this.defaultAmountEur,
    required this.note,
    this.address = '',
    this.areas = const [],
    this.selectedAreaNames = const {},
    this.gemaConfig,
  });

  BuildingBlock copyWith({
    String? name,
    BuildingBlockCategory? category,
    BuildingBlockCostProfile? costProfile,
    double? defaultAmountEur,
    String? note,
    String? address,
    List<BuildingBlockArea>? areas,
    Set<String>? selectedAreaNames,
    BuildingBlockGemaConfig? gemaConfig,
  }) {
    return BuildingBlock(
      id: id,
      name: name ?? this.name,
      category: category ?? this.category,
      costProfile: costProfile ?? this.costProfile,
      defaultAmountEur: defaultAmountEur ?? this.defaultAmountEur,
      note: note ?? this.note,
      address: address ?? this.address,
      areas: areas ?? this.areas,
      selectedAreaNames: selectedAreaNames ?? this.selectedAreaNames,
      gemaConfig: gemaConfig ?? this.gemaConfig,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'category': category.name,
      'costProfile': costProfile.name,
      'defaultAmountEur': defaultAmountEur,
      'note': note,
      'address': address,
      'areas': areas.map((area) => area.toJson()).toList(),
      'selectedAreaNames': selectedAreaNames.toList(),
      'gemaConfig': gemaConfig?.toJson(),
    };
  }

  factory BuildingBlock.fromJson(Map<String, dynamic> json) {
    return BuildingBlock(
      id: json['id']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
      category: _buildingBlockCategoryByName(json['category']?.toString()) ??
          BuildingBlockCategory.special,
      costProfile:
          _buildingBlockCostProfileByName(json['costProfile']?.toString()) ??
              BuildingBlockCostProfile.none,
      defaultAmountEur: _doubleFromJson(json['defaultAmountEur']),
      note: json['note']?.toString() ?? '',
      address: json['address']?.toString() ?? '',
      areas: [
        for (final area in json['areas'] is List ? json['areas'] as List : [])
          if (area is Map)
            BuildingBlockArea.fromJson(
              area.map((key, value) => MapEntry(key.toString(), value)),
            ),
      ],
      selectedAreaNames: {
        for (final areaName in json['selectedAreaNames'] is List
            ? json['selectedAreaNames'] as List
            : [])
          areaName.toString(),
      },
      gemaConfig: json['gemaConfig'] is Map
          ? BuildingBlockGemaConfig.fromJson(
              (json['gemaConfig'] as Map)
                  .map((key, value) => MapEntry(key.toString(), value)),
            )
          : null,
    );
  }
}

class BuildingBlockArea {
  final String name;
  final double squareMeters;
  final double amountEur;

  const BuildingBlockArea({
    required this.name,
    required this.squareMeters,
    this.amountEur = 0,
  });

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'squareMeters': squareMeters,
      'amountEur': amountEur,
    };
  }

  factory BuildingBlockArea.fromJson(Map<String, dynamic> json) {
    return BuildingBlockArea(
      name: json['name']?.toString() ?? '',
      squareMeters: _doubleFromJson(json['squareMeters']),
      amountEur: _doubleFromJson(json['amountEur']),
    );
  }
}

class BuildingBlockCatalogStore extends ValueNotifier<List<BuildingBlock>> {
  static const String _fileName = 'building_block_catalog_state.json';

  BuildingBlockCatalogStore() : super(_defaultBlocks);

  bool _isLoading = false;
  bool _hasLoaded = false;

  static const List<BuildingBlock> _defaultBlocks = [
    BuildingBlock(
      id: 'location-metropol',
      name: 'Metropol',
      category: BuildingBlockCategory.location,
      defaultAmountEur: 3200,
      note: 'Locationprofil mit Halle, Kapazität und Standardmiete.',
      areas: [
        BuildingBlockArea(name: 'Saal', squareMeters: 320, amountEur: 3200),
        BuildingBlockArea(
          name: 'Außenbereich',
          squareMeters: 375,
          amountEur: 0,
        ),
      ],
      selectedAreaNames: {'Saal', 'Außenbereich'},
    ),
    BuildingBlock(
      id: 'location-event-ship',
      name: 'Eventschiff',
      category: BuildingBlockCategory.location,
      defaultAmountEur: 0,
      note: 'Sonderlocation, Preis und Setup je Anfrage.',
    ),
    BuildingBlock(
      id: 'technology-projector',
      name: 'Beamer',
      category: BuildingBlockCategory.technology,
      defaultAmountEur: 180,
      note: 'Leihgerät für Kino, Seminar oder Präsentation.',
    ),
    BuildingBlock(
      id: 'program-dj',
      name: 'DJ',
      category: BuildingBlockCategory.program,
      defaultAmountEur: 900,
      note: 'Programmpunkt mit Standardgage.',
    ),
    BuildingBlock(
      id: 'program-artist-act',
      name: 'Künstler / Act',
      category: BuildingBlockCategory.program,
      defaultAmountEur: 0,
      note: 'Freier Künstlerbaustein für Band, Act oder Show.',
    ),
    BuildingBlock(
      id: 'staff-barkeeper',
      name: 'Barkeeper',
      category: BuildingBlockCategory.staff,
      defaultAmountEur: 0,
      note: 'Personalbaustein, Anzahl und Satz später je Planung.',
    ),
    BuildingBlock(
      id: 'cost-gema',
      name: 'GEMA',
      category: BuildingBlockCategory.cost,
      costProfile: BuildingBlockCostProfile.gema,
      defaultAmountEur: 0,
      note:
          'GEMA-Baustein mit gespeicherter Vorauswahl für Musikart und Gesellschaft.',
      gemaConfig: BuildingBlockGemaConfig(
        musicType: GemaMusicType.live,
        audienceType: GemaAudienceType.closed,
      ),
    ),
  ];

  Future<void> load() async {
    if (_hasLoaded || _isLoading) {
      return;
    }
    _isLoading = true;
    try {
      final file = await _catalogFile();
      if (!file.existsSync()) {
        _hasLoaded = true;
        return;
      }

      final decoded = jsonDecode(await file.readAsString());
      if (decoded is! Map<String, dynamic>) {
        _hasLoaded = true;
        return;
      }

      final blocks = decoded['blocks'];
      if (blocks is List) {
        final loadedBlocks = [
          for (final block in blocks)
            if (block is Map)
              BuildingBlock.fromJson(
                block.map((key, value) => MapEntry(key.toString(), value)),
              ),
        ];
        value = _mergeMissingDefaultBlocks(loadedBlocks);
      }
      _hasLoaded = true;
    } catch (_) {
      _hasLoaded = true;
    } finally {
      _isLoading = false;
    }
  }

  void upsert(BuildingBlock block) {
    final index = value.indexWhere((current) => current.id == block.id);
    if (index == -1) {
      value = [...value, block];
      _save();
      return;
    }

    final updated = [...value];
    updated[index] = block;
    value = updated;
    _save();
  }

  void delete(String blockId) {
    value = [
      for (final block in value)
        if (block.id != blockId) block,
    ];
    _save();
  }

  void setAreaSelected(
    BuildingBlock block,
    String areaName,
    bool selected,
  ) {
    final selectedAreaNames = {...block.selectedAreaNames};
    if (selected) {
      selectedAreaNames.add(areaName);
    } else {
      selectedAreaNames.remove(areaName);
    }
    upsert(block.copyWith(selectedAreaNames: selectedAreaNames));
  }

  Future<File> _catalogFile() async {
    final directory = _catalogDirectory();
    if (!directory.existsSync()) {
      directory.createSync(recursive: true);
    }
    return File('${directory.path}${Platform.pathSeparator}$_fileName');
  }

  Directory _catalogDirectory() {
    if (Platform.isWindows) {
      final appData = Platform.environment['APPDATA'];
      if (appData != null && appData.isNotEmpty) {
        return Directory('$appData${Platform.pathSeparator}SproutsManager');
      }
    }

    final home = Platform.environment['HOME'] ?? Platform.environment['USERPROFILE'];
    if (home != null && home.isNotEmpty) {
      return Directory('$home${Platform.pathSeparator}.sprouts_manager');
    }

    return Directory(
      '${Directory.systemTemp.path}${Platform.pathSeparator}sprouts_manager',
    );
  }

  Future<void> _save() async {
    if (_isLoading) {
      return;
    }

    try {
      final file = await _catalogFile();
      await file.writeAsString(
        const JsonEncoder.withIndent('  ').convert({
          'blocks': value.map((block) => block.toJson()).toList(),
        }),
      );
    } catch (_) {
      // Local catalog persistence must not block the UI.
    }
  }

  List<BuildingBlock> _mergeMissingDefaultBlocks(List<BuildingBlock> blocks) {
    final knownIds = {
      for (final block in blocks) block.id,
    };
    return [
      ...blocks,
      for (final block in _defaultBlocks)
        if (!knownIds.contains(block.id)) block,
    ];
  }
}

final buildingBlockCatalogStore = BuildingBlockCatalogStore();

BuildingBlockCategory? _buildingBlockCategoryByName(String? name) {
  if (name == null) {
    return null;
  }
  for (final category in BuildingBlockCategory.values) {
    if (category.name == name) {
      return category;
    }
  }
  return null;
}

BuildingBlockCostProfile? _buildingBlockCostProfileByName(String? name) {
  if (name == null) {
    return null;
  }
  for (final profile in BuildingBlockCostProfile.values) {
    if (profile.name == name) {
      return profile;
    }
  }
  return null;
}

GemaMusicType? _gemaMusicTypeByName(String? name) {
  if (name == null) {
    return null;
  }
  for (final type in GemaMusicType.values) {
    if (type.name == name) {
      return type;
    }
  }
  return null;
}

GemaAudienceType? _gemaAudienceTypeByName(String? name) {
  if (name == null) {
    return null;
  }
  for (final type in GemaAudienceType.values) {
    if (type.name == name) {
      return type;
    }
  }
  return null;
}

double _doubleFromJson(Object? value) {
  if (value is num) {
    return value.toDouble();
  }
  if (value is String) {
    return double.tryParse(value.replaceAll(',', '.')) ?? 0;
  }
  return 0;
}
