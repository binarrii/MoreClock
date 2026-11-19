# MoreClock

[English](README.md) · [简体中文](README.zh-CN.md) · [繁體中文](README.zh-Hant.md) · [日本語](README.ja.md) · [한국어](README.ko.md) · [Deutsch](README.de.md) · [Français](README.fr.md) · [Español](README.es.md) · [Italiano](README.it.md) · [Português (Brasil)](README.pt-BR.md) · [Русский](README.ru.md) · [العربية](README.ar.md) · [فارسی](README.fa.md)

macOSのメニューバーに複数の時間帯の時計を追加するアプリです。時計はそれぞれ独立した項目として表示されます。

![macOSのメニューバーに追加したMoreClockの時計](Design/Screenshots/menu-bar.png)

## インストール

[Mac版MoreClockをダウンロード](https://github.com/binarrii/MoreClock/releases/latest)。macOS 26以降が必要です。ユニバーサル版はAppleシリコン搭載MacとIntel搭載Macの両方に対応しています。

1. MoreClockが起動している場合は終了し、ダウンロードしたDMGファイルを開きます。
2. `MoreClock.app`を「アプリケーション」フォルダにドラッグし、そこから起動します。
3. ディスクイメージを取り出します。

配布版はアドホック署名を使用しており、Appleの公証を受けていません。macOSが初回起動をブロックする場合があります。[Appleのアプリ起動ガイド](https://support.apple.com/ja-jp/102445)

## 時計の設定

- 場所、時間帯、UTCオフセットで検索し、時計ごとに名前と接頭辞を設定できます。接頭辞が空欄の場合、対応する国や地域の旗があれば自動で入力されます。
- 日付、曜日、両方、またはどちらも表示しない設定を選べます。秒と太字も時計ごとに設定できます。12時間制と24時間制はシステム設定に従います。
- 時計のメニューで、日付、UTCオフセット、現地時刻との差を確認できます。時刻のコピーと時計の非表示も同じメニューで行えます。
- ⌘キーを押しながら時計をドラッグすると並べ替えられます。メニューバーの外にドラッグすると非表示になります。
- MoreClockはDockに表示されません。設定を開くには時計のメニューから「設定」を選ぶか、FinderやSpotlightからアプリを開き直します。
- 「一般」でログイン時の起動と言語を設定できます。「システムデフォルト」ではmacOSの言語に従います。「情報」でバージョンとビルドを確認できます。
- ショートカットから時計を追加、削除、表示、非表示にしたり、設定や時刻を取得したりできます。

## 開発

詳しい[ビルド手順](README.md#build-and-run)、[テスト](README.md#tests)、[ローカライズ](README.md#localization)については英語版READMEを参照してください。
