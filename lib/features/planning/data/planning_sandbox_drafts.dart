import 'package:sprouts_manager/core/domain_enums.dart';
import 'package:sprouts_manager/features/planning/domain/planning_models.dart';

const List<PlanningDraft> planningSandboxDrafts = [
  PlanningDraft(
    id: 'vengaboys',
    title: 'Vengaboys Konzert',
    category: EventCategory.concert,
    format: 'Live-Konzert mit Party-Anschluss',
    shortDescription:
        'Nostalgie-Konzert mit hohem Showfaktor und anschliessender Aftershow.',
    planningStatus: 'Early-Bird Phase',
    eventDate: '2026-07-14',
    startTime: '22:00',
    endTime: '01:00',
    registrationDeadline: '2026-07-12',
    minimumCapacity: 700,
    seatingMode: 'Stehend',
    earlyBirdPriceEvc: 39,
    normalPriceEvc: 49,
    presaleVotingPriceEvc: 45,
    expectedEarlyBirdShare: 0.35,
    leakagePercent: 0.04,
    reservePercent: 0.08,
    organizerMarginPercent: 0.06,
    postBreakEvenMarginPercent: 0.14,
    fixedSponsorAmountEur: 1500,
    supporterAmountEur: 2500,
    grantAmountEur: 1000,
    artistCostItems: [
      PlanningArtistCostItem(
        id: 'vengaboys-main-act',
        label: 'Kuenstlergage Vengaboys',
        type: PlanningArtistCostType.mainActFee,
        grossAmountEur: 22000,
        note: 'Gage nach verbindlichem Angebot prüfen.',
      ),
      PlanningArtistCostItem(
        id: 'vengaboys-travel',
        label: 'Anreise / Transfers',
        type: PlanningArtistCostType.travel,
        grossAmountEur: 2500,
      ),
      PlanningArtistCostItem(
        id: 'vengaboys-hotel',
        label: 'Unterkunft',
        type: PlanningArtistCostType.hotel,
        grossAmountEur: 1800,
      ),
      PlanningArtistCostItem(
        id: 'vengaboys-backstage',
        label: 'Backstage / Catering',
        type: PlanningArtistCostType.backstage,
        grossAmountEur: 900,
      ),
    ],
    technologyCostItems: [
      PlanningTechnologyCostItem(
        id: 'vengaboys-stage',
        label: 'Buehne / Podeste',
        type: PlanningTechnologyCostType.stage,
        quantity: 1,
        grossUnitAmountEur: 1600,
      ),
      PlanningTechnologyCostItem(
        id: 'vengaboys-sound',
        label: 'Konzert-Tonanlage',
        type: PlanningTechnologyCostType.sound,
        quantity: 1,
        grossUnitAmountEur: 2400,
      ),
      PlanningTechnologyCostItem(
        id: 'vengaboys-light',
        label: 'Showlicht',
        type: PlanningTechnologyCostType.light,
        quantity: 1,
        grossUnitAmountEur: 1800,
      ),
    ],
    scenarios: [
      PlanningScenario(
        id: 'venue-small',
        name: 'Kompakte Planung',
        locationBlockId: 'location-metropol',
        locationName: 'Metropol',
        setupName: 'Konzert kompakt',
        capacity: 500,
        targetOccupancyPercent: 0.5,
        baseRentEur: 3200,
        variableCostPerAttendeeEur: 1.2,
        variableCostThresholdAttendees: 250,
        variableCostNote:
            'Mehrgaeste ab 50 % Auslastung fuer Personal, Material und Ablaufpuffer.',
        locationNotes:
            'Kompakter Start mit hoeherem noetigem Ticketpreis, aber realistischer Auslastung.',
      ),
      PlanningScenario(
        id: 'venue-medium',
        name: 'Standardplanung',
        locationBlockId: 'location-metropol',
        locationName: 'Metropol',
        setupName: 'Konzertflaeche stehend',
        capacity: 850,
        targetOccupancyPercent: 0.5,
        baseRentEur: 6400,
        variableCostPerAttendeeEur: 1.8,
        variableCostThresholdAttendees: 425,
        variableCostNote:
            'Wachstumskosten fuer zusaetzliches Personal, GEMA-Staffel und Verbrauch.',
        locationNotes:
            'Groessere Showmoeglichkeit, mehr Werbewirkung, aber hoeherer Gesamtblock.',
      ),
      PlanningScenario(
        id: 'venue-large',
        name: 'Grosse Nachfrage',
        locationBlockId: 'location-metropol',
        locationName: 'Metropol',
        setupName: 'Konzertflaeche erweitert',
        capacity: 2000,
        targetOccupancyPercent: 0.5,
        baseRentEur: 9800,
        variableCostPerAttendeeEur: 2.5,
        variableCostThresholdAttendees: 1000,
        variableCostNote:
            'Groessere Auslastung braucht mehr Personal, Toiletten, GEMA und Logistik.',
        locationNotes:
            'Niedriger Ticketpreis moeglich, aber nur bei wirklich tragfaehiger Nachfrage.',
      ),
    ],
    partners: [
      PlanningPartnerProfile(
        name: 'Media Markt',
        type: PlanningPartnerType.advertisingPartner,
        tier: PartnerTier.gold,
        audienceFocus: '20-35, technikaffin',
        expectedAmountEur: 1200,
        note:
            'Passt gut zu Konzert- und Partyformaten, wenn Reichweite und junges Publikum klar sind.',
      ),
      PlanningPartnerProfile(
        name: 'Lokaler Getraenkepartner',
        type: PlanningPartnerType.eventSponsor,
        tier: PartnerTier.silver,
        audienceFocus: 'Konzert / Party',
        expectedAmountEur: 1500,
        note:
            'Koennte Eventkosten direkt mittragen, wenn Schankrechte oder Sichtbarkeit vereinbart werden.',
      ),
      PlanningPartnerProfile(
        name: 'Foerderkreis Eventhilfe',
        type: PlanningPartnerType.supporter,
        tier: PartnerTier.custom,
        audienceFocus: 'Event findet statt',
        expectedAmountEur: 2500,
        note:
            'Direkte Unterstuetzung, damit der Ticketpreis tragbar bleibt und das Event stattfindet.',
      ),
    ],
    upgradeStages: [
      PlanningUpgradeStage(minimumBudgetEur: 500, label: 'Bessere Lichttechnik'),
      PlanningUpgradeStage(minimumBudgetEur: 1000, label: 'Showeffekte'),
      PlanningUpgradeStage(minimumBudgetEur: 1500, label: 'Freigetraenke-Budget'),
      PlanningUpgradeStage(minimumBudgetEur: 2000, label: 'Anteilige EVC-Erstattung'),
    ],
  ),
];
