# MoreClock

[English](README.md) · [简体中文](README.zh-CN.md) · [繁體中文](README.zh-Hant.md) · [日本語](README.ja.md) · [한국어](README.ko.md) · [Deutsch](README.de.md) · [Français](README.fr.md) · [Español](README.es.md) · [Italiano](README.it.md) · [Português (Brasil)](README.pt-BR.md) · [Русский](README.ru.md) · [العربية](README.ar.md) · [فارسی](README.fa.md)

MoreClock은 여러 시간대의 시계를 macOS 메뉴 막대에 추가합니다. 각 시계는 메뉴 막대에서 별도의 항목으로 표시됩니다.

![macOS 메뉴 막대에 시계를 추가한 MoreClock](Design/Screenshots/menu-bar.png)

## 설치

[macOS용 MoreClock 다운로드](https://github.com/binarrii/MoreClock/releases/latest). macOS 26 이상이 필요하며, 유니버설 버전은 Apple Silicon과 Intel Mac에서 모두 실행됩니다.

1. MoreClock이 실행 중이면 종료하고 다운로드한 DMG 파일을 엽니다.
2. `MoreClock.app`을 응용 프로그램 폴더로 드래그한 뒤 해당 폴더에서 앱을 엽니다.
3. 디스크 이미지를 추출합니다.

배포본은 애드혹 방식으로 서명되었으며 Apple의 공증을 받지 않았습니다. macOS가 최초 실행을 차단할 수 있습니다. [Apple의 앱 열기 안내](https://support.apple.com/ko-kr/102445)

## 시계 설정

- 장소, 시간대 또는 UTC 오프셋으로 검색하고 시계별 이름과 접두사를 지정할 수 있습니다. 접두사가 비어 있고 해당 국가 또는 지역의 깃발이 있는 경우 자동으로 추가됩니다.
- 날짜, 요일, 둘 다 또는 표시 안 함을 선택할 수 있습니다. 초와 굵은 글씨도 시계별로 설정할 수 있습니다. 12시간제와 24시간제는 시스템 설정을 따릅니다.
- 시계 메뉴에서 전체 날짜, UTC 오프셋, 현지 시간과의 차이를 확인할 수 있습니다. 시간을 복사하거나 시계를 숨길 수도 있습니다.
- ⌘ 키를 누른 채 시계를 드래그하면 순서를 바꿀 수 있습니다. 메뉴 막대 밖으로 드래그하면 시계가 숨겨집니다.
- MoreClock은 Dock에 나타나지 않습니다. 시계 메뉴에서 설정을 선택하거나 Finder 또는 Spotlight에서 앱을 다시 열어 설정을 엽니다.
- 일반 탭에서 로그인 시 실행과 앱 언어를 설정할 수 있습니다. 시스템 기본값을 선택하면 macOS의 언어를 따릅니다. 정보 탭에는 버전과 빌드 정보가 표시됩니다.
- 단축어에서 시계를 추가, 제거, 표시, 숨기거나 설정을 바꾸고 시간을 가져올 수 있습니다.

## 개발

자세한 [빌드 및 실행](README.md#build-and-run), [테스트](README.md#tests), [현지화](README.md#localization) 방법은 영어 README를 참고하세요.
