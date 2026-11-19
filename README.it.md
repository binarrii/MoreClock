# MoreClock

[English](README.md) · [简体中文](README.zh-CN.md) · [繁體中文](README.zh-Hant.md) · [日本語](README.ja.md) · [한국어](README.ko.md) · [Deutsch](README.de.md) · [Français](README.fr.md) · [Español](README.es.md) · [Italiano](README.it.md) · [Português (Brasil)](README.pt-BR.md) · [Русский](README.ru.md) · [العربية](README.ar.md) · [فارسی](README.fa.md)

MoreClock mostra l’ora di più fusi orari nella barra dei menu di macOS. Ogni orologio ha una voce separata.

![MoreClock mostra un orologio aggiuntivo nella barra dei menu di macOS](Design/Screenshots/menu-bar.png)

## Installazione

[Scarica MoreClock per macOS](https://github.com/binarrii/MoreClock/releases/latest). L’app universale richiede macOS 26 o successivo e funziona sui Mac con chip Apple o processore Intel.

1. Esci da MoreClock se è aperto e apri il file DMG scaricato.
2. Trascina `MoreClock.app` nella cartella Applicazioni e aprila da lì.
3. Espelli l’immagine disco.

L’app distribuita ha una firma ad hoc. Apple non l’ha autenticata e macOS potrebbe bloccarne la prima apertura. [Guida Apple per aprire le app](https://support.apple.com/it-it/102445)

## Configurare gli orologi

- Cerca un luogo, un fuso orario o uno scostamento da UTC. Imposta un nome e un prefisso per ogni orologio. Se il prefisso è vuoto, MoreClock aggiunge la bandiera del paese o della regione quando è disponibile.
- Mostra la data, il giorno della settimana, entrambi oppure nessuno dei due. Puoi attivare i secondi e il grassetto per ciascun orologio. Il formato a 12 o 24 ore segue le impostazioni del sistema.
- Nel menu di ogni orologio trovi la data completa, lo scostamento da UTC, la differenza rispetto all’ora locale e le opzioni per copiare l’ora o nascondere l’orologio.
- Tieni premuto ⌘ mentre trascini un orologio per riordinarlo. Per nasconderlo, trascinalo fuori dalla barra dei menu.
- MoreClock non ha un’icona nel Dock. Accedi alle impostazioni dal menu di un orologio o riapri l’app dal Finder o da Spotlight.
- In Generali puoi scegliere la lingua dell’app e avviarla all’accesso. La lingua predefinita segue macOS. In Informazioni trovi la versione e i dettagli della build.
- Con Comandi Rapidi puoi aggiungere, rimuovere, mostrare, nascondere e configurare gli orologi e leggerne l’ora.

## Sviluppo

La documentazione in inglese descrive la [compilazione](README.md#build-and-run), i [test](README.md#tests) e la [localizzazione](README.md#localization).
