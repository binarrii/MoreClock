# MoreClock

[English](../../README.md) · [简体中文](README.zh-CN.md) · [繁體中文](README.zh-Hant.md) · [日本語](README.ja.md) · [한국어](README.ko.md) · [Deutsch](README.de.md) · [Français](README.fr.md) · [Español](README.es.md) · [Italiano](README.it.md) · [Português (Brasil)](README.pt-BR.md) · [Русский](README.ru.md) · [العربية](README.ar.md) · [فارسی](README.fa.md)

MoreClock 可在 macOS 選單列顯示多個時區的時間。每個時鐘都是選單列中的獨立項目。

![MoreClock 在 macOS 選單列顯示額外的時鐘](../../Design/Screenshots/menu-bar.png)

## 安裝

[下載 macOS 版 MoreClock](https://github.com/binarrii/MoreClock/releases/latest)。通用版需要 macOS 26 或更新版本，可在搭載 Apple 晶片或 Intel 處理器的 Mac 上執行。

1. 如果 MoreClock 正在執行，請先結束程式，再打開下載的 DMG 檔案。
2. 將 `MoreClock.app` 拖移至「應用程式」資料夾，並從該資料夾開啟 App。
3. 退出磁碟映像檔。

發行版採用臨時簽署（ad hoc），尚未經過 Apple 公證。macOS 可能會阻止首次開啟。[Apple 的 App 開啟指南](https://support.apple.com/zh-tw/102445)

## 設定時鐘

- 可搜尋地點、時區或 UTC 偏移量。每個時鐘都能設定名稱和前置文字。前置文字留空時，若有對應的國家或地區旗幟，MoreClock 會自動填入。
- 可選擇顯示日期、星期、兩者，或只顯示時間。每個時鐘也可以個別開啟秒數和粗體。12 或 24 小時制依照系統設定。
- 時鐘選單會顯示完整日期、UTC 偏移量和與本地時間的差值，也能拷貝時間或隱藏該時鐘。
- 按住 ⌘ 鍵拖移時鐘即可重新排列。將時鐘拖出選單列即可隱藏。
- MoreClock 不會顯示在 Dock。你可以從時鐘選單開啟「設定」，也可以從 Finder 或 Spotlight 再次開啟 App。
- 在「一般」中可以設定登入時開啟和 App 語言。「系統預設」會依照 macOS 的語言設定。在「關於」中可查看版本和建置資訊。
- 「捷徑」可新增、移除、顯示、隱藏或設定時鐘，也可以取得時鐘的時間。

## 開發

詳細的[建置與執行](../../README.md#build-and-run)、[測試](../../README.md#tests)和[在地化](../../README.md#localization)說明請參閱英文 README。
