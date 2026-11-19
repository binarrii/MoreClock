# MoreClock

[English](README.md) · [简体中文](README.zh-CN.md) · [繁體中文](README.zh-Hant.md) · [日本語](README.ja.md) · [한국어](README.ko.md) · [Deutsch](README.de.md) · [Français](README.fr.md) · [Español](README.es.md) · [Italiano](README.it.md) · [Português (Brasil)](README.pt-BR.md) · [Русский](README.ru.md) · [العربية](README.ar.md) · [فارسی](README.fa.md)

MoreClock affiche l’heure de plusieurs fuseaux horaires dans la barre des menus de macOS. Chaque horloge y occupe sa propre entrée.

![MoreClock affiche une horloge supplémentaire dans la barre des menus de macOS](Design/Screenshots/menu-bar.png)

## Installation

[Télécharger MoreClock pour macOS](https://github.com/binarrii/MoreClock/releases/latest). L’app universelle nécessite macOS 26 ou une version ultérieure et fonctionne sur les Mac à puce Apple ou à processeur Intel.

1. Quittez MoreClock si l’app est ouverte, puis ouvrez le fichier DMG téléchargé.
2. Faites glisser `MoreClock.app` dans le dossier Applications et ouvrez l’app depuis ce dossier.
3. Éjectez l’image disque.

L’app publiée porte une signature ad hoc. Elle n’a pas été notarisée par Apple. macOS peut donc bloquer la première ouverture. [Consignes d’Apple pour ouvrir une app](https://support.apple.com/fr-fr/102445)

## Configurer les horloges

- Recherchez un lieu, un fuseau horaire ou un décalage UTC. Donnez à chaque horloge un nom et un préfixe. Si le préfixe est vide, le drapeau du pays ou de la région est ajouté lorsqu’il est disponible.
- Choisissez d’afficher la date, le jour de la semaine, les deux ou aucun des deux. Les secondes et le gras sont facultatifs. Le format 12 ou 24 heures suit le réglage du système.
- Le menu d’une horloge indique la date complète, le décalage UTC et l’écart avec l’heure locale. Vous pouvez aussi y copier l’heure ou masquer l’horloge.
- Maintenez la touche ⌘ enfoncée pendant le glissement pour changer l’ordre. Faites glisser une horloge hors de la barre des menus pour la masquer.
- MoreClock n’a pas d’icône dans le Dock. Ouvrez les réglages depuis le menu d’une horloge ou rouvrez l’app depuis le Finder ou Spotlight.
- Dans l’onglet Général, choisissez la langue de l’app et si elle s’ouvre à la connexion. La langue du système suit macOS. L’onglet À propos indique la version et la build.
- Utilisez Raccourcis pour ajouter, retirer, afficher, masquer ou configurer des horloges et consulter leur heure.

## Développement

La documentation en anglais détaille la [compilation](README.md#build-and-run), les [tests](README.md#tests) et la [localisation](README.md#localization).
