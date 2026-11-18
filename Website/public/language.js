(() => {
  const key = 'moreclock.websiteLanguage';
  const routes = JSON.parse(document.currentScript.dataset.routes);
  const current = new URL(window.location.href);

  function browserLocale() {
    const tag = (navigator.languages?.[0] || navigator.language || '').toLowerCase();
    const [language, ...subtags] = tag.split('-');
    if (language === 'zh') {
      if (subtags.includes('hans')) return 'zh-CN';
      if (subtags.includes('hant') || subtags.some(tag => ['hk', 'mo', 'tw'].includes(tag))) return 'zh-Hant';
      return 'zh-CN';
    }
    if (language === 'pt') return 'pt-BR';
    return Object.hasOwn(routes, language) ? language : 'en';
  }

  document.addEventListener('click', event => {
    const link = event.target.closest?.('[data-language-choice]');
    if (!link || event.defaultPrevented) return;
    const locale = link.dataset.languageChoice;
    if (locale === 'system') return;
    try {
      window.localStorage.setItem(key, locale);
    } catch {
      if (locale === 'en') {
        const target = new URL(link.href);
        target.searchParams.set('lang', 'en');
        link.href = target.href;
      }
    }
  }, { capture: true });

  const override = current.searchParams.get('lang');
  if (current.pathname !== '/' || override === 'en') return;
  let savedLocale;
  try {
    if (override === 'system') window.localStorage.removeItem(key);
    else savedLocale = window.localStorage.getItem(key);
  } catch {
    // Storage can be unavailable in restricted browsing contexts.
  }
  const selected = override !== 'system' && Object.hasOwn(routes, savedLocale) ? savedLocale : browserLocale();
  if (selected !== 'en') {
    current.pathname = routes[selected];
    if (override === 'system') current.searchParams.delete('lang');
    window.location.replace(current.href);
  } else if (override === 'system') {
    current.searchParams.delete('lang');
    window.history.replaceState(null, '', current.href);
  }
})();
