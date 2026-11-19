# MoreClock

[English](../../README.md) · [简体中文](README.zh-CN.md) · [繁體中文](README.zh-Hant.md) · [日本語](README.ja.md) · [한국어](README.ko.md) · [Deutsch](README.de.md) · [Français](README.fr.md) · [Español](README.es.md) · [Italiano](README.it.md) · [Português (Brasil)](README.pt-BR.md) · [Русский](README.ru.md) · [العربية](README.ar.md) · [فارسی](README.fa.md)

MoreClock zeigt in der macOS-Menüleiste die Uhrzeit mehrerer Zeitzonen an. Jede Uhr hat einen eigenen Menüleisteneintrag.

![MoreClock mit einer zusätzlichen Uhr in der macOS-Menüleiste](../../Design/Screenshots/menu-bar.png)

## Installation

[MoreClock für macOS herunterladen](https://github.com/binarrii/MoreClock/releases/latest). Die universelle App benötigt macOS 26 oder neuer und läuft auf Macs mit Apple-Chip oder Intel-Prozessor.

1. Beende eine eventuell laufende Kopie von MoreClock und öffne die heruntergeladene DMG-Datei.
2. Ziehe `MoreClock.app` in den Ordner „Programme“ und öffne die App dort.
3. Wirf das Disk-Image aus.

Die veröffentlichte App ist ad hoc signiert. Apple hat sie nicht notarisiert, daher kann macOS den ersten Start blockieren. [Hinweise von Apple zum Öffnen von Apps](https://support.apple.com/de-de/102445)

## Uhren einrichten

- Suche nach einem Ort, einer Zeitzone oder einer UTC-Abweichung. Jede Uhr kann einen eigenen Namen und ein Präfix haben. Bei leerem Präfix wird, falls verfügbar, die Flagge des Landes oder der Region eingesetzt.
- Wähle pro Uhr zwischen Datum, Wochentag, beidem oder keiner Datumsanzeige. Sekunden und Fettschrift sind optional. Das 12- oder 24-Stunden-Format folgt der Systemeinstellung.
- Im Menü einer Uhr stehen das vollständige Datum, die UTC-Abweichung und der Unterschied zur Ortszeit. Dort kannst du die Uhrzeit kopieren oder die Uhr ausblenden.
- Halte zum Umsortieren beim Ziehen die Befehlstaste ⌘ gedrückt. Ziehe eine Uhr aus der Menüleiste, um sie auszublenden.
- MoreClock hat kein Dock-Symbol. Öffne die Einstellungen über eine Uhr oder starte MoreClock erneut über den Finder oder Spotlight.
- Unter „Allgemein“ kannst du den Start bei der Anmeldung aktivieren und die App-Sprache ändern. „Systemstandard“ folgt macOS. Unter „Über“ findest du die Version und Build-Informationen.
- Mit Kurzbefehlen kannst du Uhren hinzufügen, entfernen, ein- oder ausblenden, einstellen und ihre Zeit abfragen.

## Entwicklung

Die englische Dokumentation enthält die ausführlichen [Build-Anweisungen](../../README.md#build-and-run), [Tests](../../README.md#tests) und [Hinweise zur Lokalisierung](../../README.md#localization).
