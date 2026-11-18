# MoreClock

[English](README.md) · [简体中文](README.zh-CN.md) · [繁體中文](README.zh-Hant.md) · [日本語](README.ja.md) · [한국어](README.ko.md) · [Deutsch](README.de.md) · [Français](README.fr.md) · [Español](README.es.md) · [Italiano](README.it.md) · [Português (Brasil)](README.pt-BR.md) · [Русский](README.ru.md) · [العربية](README.ar.md) · [فارسی](README.fa.md)

O MoreClock mostra a hora de vários fusos na barra de menus do macOS. Cada relógio ocupa um item separado na barra.

![MoreClock mostra um relógio adicional na barra de menus do macOS](Design/Screenshots/menu-bar.png)

## Instalação

[Baixar o MoreClock para macOS](https://github.com/binarrii/MoreClock/releases/latest). O app universal requer macOS 26 ou posterior e funciona em Macs com chip da Apple ou processador Intel.

1. Encerre o MoreClock se estiver aberto e abra o arquivo DMG baixado.
2. Arraste `MoreClock.app` para a pasta Aplicativos e abra o app por lá.
3. Ejete a imagem de disco.

O app distribuído tem assinatura ad hoc e não foi notarizado pela Apple. O macOS pode bloquear a primeira abertura. [Orientações da Apple para abrir apps](https://support.apple.com/pt-br/102445)

## Configurar os relógios

- Busque um local, um fuso horário ou uma diferença em relação ao UTC. Escolha um nome e um prefixo para cada relógio. Se o prefixo estiver vazio, o MoreClock adiciona a bandeira do país ou da região quando disponível.
- Você pode mostrar a data, o dia da semana, ambos ou nenhum deles. Segundos e negrito são opcionais para cada relógio. O formato de 12 ou 24 horas segue os ajustes do sistema.
- O menu de cada relógio mostra a data completa, a diferença em relação ao UTC e à hora local. Você também pode copiar a hora ou ocultar o relógio nesse menu.
- Mantenha ⌘ pressionado ao arrastar para mudar a ordem. Arraste um relógio para fora da barra de menus para ocultá-lo.
- O MoreClock não aparece no Dock. Abra os Ajustes pelo menu de um relógio ou reabra o app pelo Finder ou Spotlight.
- Na aba Geral, escolha o idioma do app e se ele deve abrir ao iniciar a sessão. A opção padrão segue o macOS. Na aba Sobre, veja a versão e os dados da compilação.
- Use o app Atalhos para adicionar, remover, mostrar, ocultar e configurar relógios ou consultar a hora.

## Atualizações e desenvolvimento

Ao atualizar da versão 0.1.1, os ajustes são preservados. Para migrar da versão 0.1.0, use o script de transferência de ajustes. [Guia de migração](README.md#upgrading-from-v010)

A documentação em inglês cobre [compilação e execução](README.md#build-and-run), [testes](README.md#tests) e [localização](README.md#localization).
