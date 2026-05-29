\# AGENTS.md - Eventsprouts Manager App



\## Projektkontext



Dieses Projekt ist ein älterer Flutter-Prototyp für die Eventsprouts Manager-App. Es darf und soll umfangreich umgebaut werden. Ziel ist nicht, den alten Stand möglichst unverändert zu erhalten, sondern daraus eine saubere, moderne Manager-, Admin- und Einlass-App für Eventsprouts zu entwickeln.



Eventsprouts besteht langfristig aus:



1\. User-Webapp / PWA

&#x20;  Für Gäste und normale Nutzer: Events ansehen, anmelden, abmelden, EVC nutzen, Tickets anzeigen und QR-Code vorzeigen.



2\. Flutter Manager-App

&#x20;  Für Admins, Veranstalter, Manager und Einlasspersonal: Eventverwaltung, Teilnehmerverwaltung, Eventkalkulation, QR-Scan, Offline-Einlass und spätere Synchronisierung.



Dieses Repository betrifft die Flutter Manager-App.



\## Hauptziel dieser App



Die Manager-App soll zwei unterschiedliche Nutzungsarten unterstützen:



1\. Einlassmodus

&#x20;  Optimiert für Smartphone im Portrait-Layout.

&#x20;  Zweck: Event auswählen, QR-Code scannen, Eintritt prüfen, Check-in speichern.



2\. Manager-/Adminmodus

&#x20;  Optimiert für Desktop, Windows, Tablet und Landscape-Layout.

&#x20;  Zweck: Events verwalten, Teilnehmer verwalten, Eventkalkulation durchführen, Status prüfen und administrative Aufgaben erledigen.



Die App darf optisch zunächst schlicht sein. Funktion, Struktur, Wartbarkeit und klare Architektur sind wichtiger als perfektes UI-Design.



\## Zugriff und Arbeitsweise



Du darfst das Projekt umfassend umbauen, Dateien ändern, verschieben, löschen und neu strukturieren, wenn es dem Ziel einer sauberen Manager-App dient.



Du darfst:



\* vorhandene Dateien analysieren

\* Code refaktorieren

\* Ordnerstrukturen umbauen

\* alte unpassende Dateien entfernen

\* neue Feature-Ordner anlegen

\* Screens, Widgets, Models und Provider neu erstellen

\* Dependencies vorschlagen oder ergänzen, wenn sie fachlich sinnvoll sind

\* veraltete Flutter-Strukturen modernisieren

\* Namen von Klassen, Dateien und Variablen ins Englische überführen



Bitte arbeite trotzdem schrittweise und nachvollziehbar. Bei größeren Umbauten zuerst kurz erklären, was geändert wird.



\## Sprache und Namenskonventionen



Code, Datei- und Klassennamen sind Englisch.



Beispiele:



\* ManagerDashboardScreen

\* EventManagementScreen

\* AdmissionScannerScreen

\* EventCalculationScreen

\* ParticipantManagementScreen



Sichtbare UI-Texte dürfen Deutsch sein.



Beispiele:



\* "Einlass"

\* "Eventverwaltung"

\* "Teilnehmer"

\* "Kalkulation"

\* "Einstellungen"



Keine neuen deutschen Klassennamen, Dateinamen oder Variablennamen verwenden.



\## Architekturvorgaben



Verwende eine klare Feature-Struktur.



Zielstruktur ungefähr:



```text

lib/

&#x20; app/

&#x20; core/

&#x20; data/

&#x20; features/

&#x20;   auth/

&#x20;   dashboard/

&#x20;   events/

&#x20;   participants/

&#x20;   admission/

&#x20;   event\_calculation/

&#x20;   tickets/

&#x20;   wallet\_admin/

&#x20;   security/

&#x20;   settings/

&#x20; shared/

```



Die genaue Struktur darf angepasst werden, wenn es sinnvoll ist. Wichtig ist eine klare Trennung nach Features.



\## State Management



Riverpod ist die bevorzugte Zielarchitektur.



Wenn im Altprojekt Provider, setState-lastige Logik oder andere Muster vorhanden sind, dürfen diese schrittweise ersetzt werden.



Für den ersten Umbau sind einfache Provider und Platzhalterdaten erlaubt. Die Architektur soll aber so vorbereitet werden, dass später Firebase, Hive und echte Repositories sauber angeschlossen werden können.



\## Persistenz



Keine SharedPreferences für fachliche App-Daten verwenden.



SharedPreferences höchstens für kleine UI-Einstellungen, zum Beispiel Theme, letzter Modus oder Fensterpräferenz.



Fachliche Daten gehören später in:



\* Firebase / Firestore als serverseitige Wahrheit

\* Hive oder eine vergleichbare lokale Datenbank für Offline-Einlassdaten und lokale Caches



\## Backend-Zielbild



Backend ist später Firebase-basiert geplant:



\* Firebase Auth für Login und Rollen

\* Firestore für Events, Tickets, Userprofile, Teilnehmer, EVC, Transaktionen und SecurityEvents

\* Cloud Functions oder Cloud Run für kritische Geschäftslogik

\* Firebase Storage optional für Eventbilder

\* App Check später prüfen



Wichtige Regel:



Der Client darf später nicht allein über kritische Dinge entscheiden.



Kritische Aktionen gehören serverseitig abgesichert:



\* Ticket erzeugen

\* Ticket stornieren

\* EVC abbuchen

\* EVC erstatten

\* QR-Token invalidieren

\* User sperren

\* Check-in final synchronisieren

\* Eventstatus final setzen



\## Rollenmodell



Die App soll perspektivisch rollenbasiert funktionieren.



Geplante Rollen:



```text

admin

eventManager

admissionStaff

support

```



Bedeutung:



\* admin: Zugriff auf alles

\* eventManager: Events, Teilnehmer, Kalkulation

\* admissionStaff: nur Einlassmodus, Eventauswahl und Scanner

\* support: Tickets, Userstatus, Korrekturen, Security-Hinweise



Für den Anfang reicht ein lokaler Dummy-Rollenwechsel oder Platzhalter.



\## Responsive Verhalten



Die App muss unterschiedliche Layouts unterstützen.



Smartphone / Portrait:



\* Fokus auf Einlassmodus

\* große Buttons

\* klare Scan-Ergebnisse

\* minimale Navigation

\* für Einlassmitarbeiter geeignet



Tablet / Desktop / Landscape:



\* Manager-Dashboard

\* Navigation links oder oben

\* Tabellen und Formulare

\* Eventverwaltung

\* Teilnehmerverwaltung

\* Eventkalkulation

\* Einstellungen



Nutze sinnvolle Breakpoints und LayoutBuilder / MediaQuery oder eigene Responsive-Utilities.



\## Feature: Admission / Einlass



Der Einlassmodus ist ein Kernfeature.



Zielablauf:



```text

Event auswählen

→ Einlassdaten synchronisieren oder lokal laden

→ Scanner öffnen

→ QR-Code scannen

→ Ergebnis anzeigen

→ Check-in lokal speichern

→ später synchronisieren

```



Scan-Ergebnisse sollen klar unterscheidbar sein:



```text

valid

alreadyCheckedIn

canceled

wrongEvent

blockedUser

unknownTicket

offlineDataMissing

syncRequired

```



UI-Anzeige:



\* Grün: gültig, eingecheckt

\* Gelb: bereits eingecheckt oder Prüfung nötig

\* Rot: ungültig, storniert, falsches Event oder gesperrt



QR-Scanner später voraussichtlich mit `mobile\_scanner`.



Wenn QR-Scan noch nicht direkt umgesetzt wird, erst mit Dummy-Scan-Daten oder manueller Ticket-ID-Eingabe arbeiten.



\## Feature: Eventmanagement



Eventmanager und Admins sollen Events erstellen, bearbeiten und verwalten können.



Wichtige Felder:



\* Titel

\* Beschreibung

\* Kategorie

\* Location

\* Datum

\* Uhrzeit

\* Deadline

\* Mindestteilnehmer

\* maximale Teilnehmer

\* Early-Bird-Preis in EVC

\* Normalpreis in EVC

\* Status

\* Sichtbarkeit

\* Bild / Farbe optional



Wichtige Statuslogik:



```text

open

confirmed

soldOut

closed

past

canceled

notHappening

```



Fachliche Bedeutung:



\* confirmed bedeutet: Durchführung ist gesichert.

\* confirmed kann durch Mindestteilnehmerzahl oder manuell durch Admin/Sponsor/Veranstalter gesetzt werden.

\* Early Bird gilt nur solange ein Event noch nicht confirmed ist.

\* canceled bedeutet: Ein bereits bestätigtes/geplantes Event fällt später aktiv aus.

\* notHappening bedeutet: Das Event wurde bis zur Deadline nicht bestätigt und findet deshalb nie statt.



Nicht `canceled` und `notHappening` vermischen.



\## Feature: Teilnehmerverwaltung



Teilnehmerverwaltung soll später unterstützen:



\* Teilnehmerliste pro Event

\* Suche und Filter

\* Status angemeldet / storniert / eingecheckt / Warteliste

\* manuelle Korrekturen

\* Export oder Übersicht

\* Anzeige von auffälligen Tickets oder Userstatus



Geplante Participant-Typen:



```text

regular

wheelchair

child

waitlist

```



Tatsächliche Teilnahme ergibt sich aus Check-in.



\## Feature: Eventkalkulation



Eventkalkulation ist ein Kernfeature und soll nicht extern in Excel bleiben.



Ziel:

Die App soll helfen, Break-even, Preise, Mindestteilnehmer und wirtschaftliches Risiko eines Events zu berechnen.



Geplante Kostenfelder:



\* Künstler / DJ / Band

\* Location

\* Technik

\* Security

\* Personal

\* GEMA / Lizenz

\* Werbung

\* Versicherung

\* Sonstige Kosten



Geplante Einnahmenfelder:



\* Early-Bird-Preis

\* Normalpreis

\* maximale Teilnehmer

\* erwartete Teilnehmer

\* Sponsoranteil

\* Admin-Zuschuss

\* Promo- oder Freitickets

\* Bonus- oder Support-Anteil



Ergebnisse:



\* Gesamtkosten

\* Break-even

\* notwendige Mindestteilnehmer

\* Preisempfehlung

\* erwarteter Überschuss

\* Puffer

\* Risikoanzeige



Die Kalkulation soll später Eventfelder vorbelegen oder aktualisieren können:



```text

Kalkulation → Mindestteilnehmer, Preise, Deadline, Confirmed-Logik

```



Für den Anfang reichen lokale Modelle und Dummy-Daten.



\## Feature: EVC / Wallet Admin



Eventsprouts nutzt Eventcoins, abgekürzt EVC.



User kaufen EVC später in der User-Webapp. Die Manager-App soll administrative Einsicht und Korrekturen unterstützen, aber keine unsichere lokale Wallet-Wahrheit erzeugen.



Wichtige Grundregel:

EVC-Buchungen sind serverseitige Wahrheit und dürfen später nur über Backend-Funktionen verändert werden.



Admin-Funktionen später:



\* Transaktionshistorie ansehen

\* Korrektur buchen

\* Erstattung auslösen

\* BonusCoins vergeben

\* Problemfälle prüfen



\## Feature: Security / User-Ampel



Es ist ein UserAccessStatus geplant:



```text

green

yellow

red

```



Bedeutung:



\* green: normaler Nutzer

\* yellow: auffälliger Nutzer, zum Beispiel Early-Bird eingeschränkt

\* red: gesperrter Nutzer, keine neuen Ticketkäufe oder Anmeldungen



SecurityEvents sollen später Scanvorfälle dokumentieren:



\* storniertes Ticket gescannt

\* falsches Event

\* mehrfacher ungültiger Scan

\* bereits eingechecktes Ticket erneut verwendet

\* manuelle Admin-Hinweise



Nicht jeder ungültige Scan ist automatisch Betrug. Die UI soll sachlich bleiben.



\## QR- und Offline-Architektur



Der QR-Code ist kein Eintrittsrecht, sondern ein Prüfschlüssel.



Die Wahrheit liegt später im Backend bzw. in final synchronisierten lokalen Einlassdaten.



Für Offline-Einlass lädt die Manager-App vor dem Event:



\* gültige Tickets

\* stornierte Tickets

\* gesperrte Token

\* Token-Versionen

\* Check-in-Status

\* UserAccessStatus

\* Eventdaten



Offline darf gescannt und lokal eingecheckt werden. Später muss synchronisiert werden.



Konflikte müssen später behandelt werden, zum Beispiel:



\* zwei Scanner checken dasselbe Ticket offline ein

\* Ticket wurde nach letztem Sync storniert

\* Token-Version ist veraltet

\* Teilnehmerliste war nicht aktuell



Für den Anfang reicht ein sauberes Datenmodell und Dummylogik.



\## UI-Stil



Das UI darf zuerst schlicht sein.



Priorität:



1\. Funktion

2\. klare Struktur

3\. gute Bedienbarkeit

4\. responsive Layouts

5\. später Design-Polish



Einlassmodus:



\* große Buttons

\* klare Farben

\* wenige Ablenkungen

\* Portrait optimiert



Adminmodus:



\* Tabellen

\* Formulare

\* Navigation

\* sachliches Dashboard

\* Landscape / Desktop optimiert



\## Dependencies



Dependencies dürfen ergänzt werden, wenn sie sinnvoll sind. Bitte nicht wahllos große UI-Frameworks einbauen.



Mögliche spätere Dependencies:



\* flutter\_riverpod

\* hive / hive\_flutter

\* firebase\_core

\* firebase\_auth

\* cloud\_firestore

\* mobile\_scanner

\* qr\_flutter

\* intl



Wenn neue Dependencies ergänzt werden, kurz begründen.



\## Build, Analyze und Tests



Wenn du Commands ausführen kannst, darfst du für diesen Umbau grundsätzlich auch sinnvolle Commands nutzen.



Trotzdem gilt:



\* keine unnötigen Builds

\* keine großen Plattformänderungen ohne Grund

\* keine Dependency-Upgrades ohne fachlichen Nutzen

\* Fehler bitte nachvollziehbar berichten

\* bei Build-/Analyze-Fehlern zuerst erklären, wodurch sie entstehen



\## Git



Falls noch kein Git-Repository existiert, nicht automatisch initialisieren, außer der Nutzer fordert es ausdrücklich.



Wenn Git bereits vorhanden ist:



\* keine Commits ohne ausdrückliche Aufforderung

\* Änderungen nachvollziehbar halten

\* große Umbauten möglichst in sinnvollen Schritten durchführen



\## Wichtige fachliche Begriffe



\* EVC = Eventcoins

\* confirmed = Event findet sicher statt

\* Early Bird = reduzierter Preis vor Confirmed-Status

\* canceled = bestätigtes/geplantes Event fällt später aktiv aus

\* notHappening = Event wurde nie bestätigt und findet wegen zu wenig Interesse nicht statt

\* Admission = Einlass

\* Check-in = tatsächlicher Eintritt vor Ort

\* Manager-App = Flutter-App für Admin, Eventmanagement und Einlass

\* User-Webapp = React/Vite/PWA für Gäste und Tickets



\## Aktueller erster Umbauauftrag



Wenn noch kein konkreter Auftrag gegeben wurde, beginne mit einer Bestandsaufnahme und einem Umbauplan.



Prüfe:



\* vorhandene Projektstruktur

\* pubspec.yaml

\* lib/

\* vorhandene Screens

\* vorhandene Models

\* vorhandene Navigation

\* vorhandene Kalkulationslogik

\* QR-/Check-in-Ansätze

\* veraltete oder unpassende Struktur



Danach erstelle einen Plan:



1\. Was kann bleiben?

2\. Was sollte entfernt werden?

3\. Was sollte neu strukturiert werden?

4\. Welche Feature-Struktur wird vorgeschlagen?

5\. Welche ersten Screens sollen angelegt werden?

6\. Welche Reihenfolge ist sinnvoll?



Wenn das Projekt bereits offensichtlich umgebaut werden muss, darf anschließend mit dem Umbau begonnen werden.



