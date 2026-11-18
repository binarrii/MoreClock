// Ordered to match MoreClock’s macOS language picker.
export const locales = [
  { id: 'de', name: 'Deutsch', flag: '🇩🇪', system: 'Systemstandard', og: 'de_DE', apple: 'de-de' },
  { id: 'en', name: 'English', flag: '🇺🇸', system: 'System Default', og: 'en_US', apple: 'en-us', path: '/' },
  { id: 'es', name: 'Español', flag: '🇪🇸', system: 'Predeterminado del sistema', og: 'es_ES', apple: 'es-es' },
  { id: 'fr', name: 'Français', flag: '🇫🇷', system: 'Langue du système', og: 'fr_FR', apple: 'fr-fr' },
  { id: 'it', name: 'Italiano', flag: '🇮🇹', system: 'Predefinita di sistema', og: 'it_IT', apple: 'it-it' },
  { id: 'pt-BR', name: 'Português (Brasil)', flag: '🇧🇷', system: 'Padrão do sistema', og: 'pt_BR', apple: 'pt-br' },
  { id: 'ru', name: 'Русский', flag: '🇷🇺', system: 'Язык системы', og: 'ru_RU', apple: 'ru-ru' },
  { id: 'ar', name: 'العربية', flag: '🇸🇦', system: 'اللغة الافتراضية للنظام', og: 'ar_SA', apple: 'ar-sa', dir: 'rtl' },
  { id: 'fa', name: 'فارسی', flag: '🇮🇷', system: 'پیش‌فرض سیستم', og: 'fa_IR', apple: 'en-us', dir: 'rtl' },
  { id: 'ko', name: '한국어', flag: '🇰🇷', system: '시스템 기본값', og: 'ko_KR', apple: 'ko-kr' },
  { id: 'ja', name: '日本語', flag: '🇯🇵', system: 'システムデフォルト', og: 'ja_JP', apple: 'ja-jp' },
  { id: 'zh-CN', name: '简体中文', flag: '🇨🇳', system: '系统默认', og: 'zh_CN', apple: 'zh-cn', lang: 'zh-Hans' },
  { id: 'zh-Hant', name: '繁體中文', flag: '🇭🇰', system: '系統預設', og: 'zh_TW', apple: 'zh-tw' },
].map(locale => ({ path: `/${locale.id}/`, lang: locale.id, dir: 'ltr', ...locale }));
