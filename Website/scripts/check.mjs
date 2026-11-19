import assert from 'node:assert/strict';
import fs from 'node:fs';
import vm from 'node:vm';
import { locales } from '../locales/registry.mjs';
import { compactCatalog } from '../locales/additional.mjs';

const root = new URL('../public/', import.meta.url);
const origin = 'https://moreclock.skyviiew.com';
const sitemap = fs.readFileSync(new URL('sitemap.xml', root), 'utf8');
const headers = fs.readFileSync(new URL('_headers', root), 'utf8');
const plain = text => text.replace(/<[^>]*>/g, '').replaceAll('&amp;', '&').replaceAll('&lt;', '<').replaceAll('&gt;', '>').replaceAll('&quot;', '"').replaceAll('&#39;', "'").replace(/\s+/g, ' ').trim();
const scriptData = (html, id) => JSON.parse(html.match(new RegExp(`<script id="${id}" type="application/json">([\\s\\S]*?)<\\/script>`))[1]);
const expectedAlternates = Object.fromEntries([...locales.map(({ lang, path }) => [lang, origin + path]), ['x-default', `${origin}/`]]);
const routes = Object.fromEntries(locales.map(({ id, path }) => [id, path]));

for (const entry of locales) {
  const locale = entry.id;
  const original = ['en', 'zh-CN'].includes(locale);
  const read = extension => fs.readFileSync(new URL(`../locales/${locale}.${extension}`, import.meta.url), 'utf8');
  const catalog = original ? JSON.parse(read('json')) : compactCatalog(locale, read('txt'));
  const m = { ...catalog, ...entry, html_lang: entry.lang, date_locale: catalog.date_locale ?? entry.lang };
  assert.ok(headers.includes(`${m.path}\n  Content-Language: ${m.lang}\n`));
  assert.ok(headers.includes(`${m.path}llms.txt\n  Content-Language: ${m.lang}\n  Content-Type: text/plain; charset=utf-8`));
  const html = fs.readFileSync(new URL(`${m.path.slice(1)}index.html`, root), 'utf8');
  const schema = JSON.parse(html.match(/<script type="application\/ld\+json">([\s\S]*?)<\/script>/)[1]);
  const app = schema['@graph'].find(item => item['@type'] === 'SoftwareApplication');
  const page = schema['@graph'].find(item => item['@type'] === 'WebPage');
  const website = schema['@graph'].find(item => item['@type'] === 'WebSite');
  const canonical = origin + m.path;
  assert.ok(html.includes(`<html lang="${m.lang}" dir="${m.dir}" data-locale="${locale}"`));
  const title = original ? m.meta_title : `MoreClock · ${m.hero_title}`;
  assert.equal(plain(html.match(/<title>(.*?)<\/title>/)[1]), title);
  assert.ok(html.includes(`<link rel="canonical" href="${canonical}">`));
  assert.ok(html.includes(`<meta property="og:url" content="${canonical}">`));
  assert.ok(html.includes(`<meta property="og:locale" content="${m.og}">`));
  assert.equal((html.match(/property="og:locale:alternate"/g) ?? []).length, locales.length - 1);
  for (const [lang, url] of Object.entries(expectedAlternates)) assert.ok(html.includes(`<link rel="alternate" hreflang="${lang}" href="${url}">`), `${locale}: missing alternate ${lang}`);
  assert.equal((html.match(/hreflang="x-default"/g) ?? []).length, 1);
  assert.equal(app.name, 'MoreClock'); assert.equal(app.softwareVersion, '1.0.1');
  assert.equal(app.inLanguage.length, 13);
  assert.equal(app.description, original ? m.app_description : m.clocks_lead);
  assert.deepEqual(app.featureList, original ? m.features : [m.clocks_lead, m.date_lead, m.language_lead, m.faq_shortcuts_answer]);
  assert.equal(page.url, canonical); assert.equal(page.inLanguage, m.lang);
  assert.equal(page.description, original ? m.meta_description : m.hero_lead);
  assert.deepEqual(website.inLanguage, locales.map(item => item.lang));
  assert.deepEqual(app.inLanguage, website.inLanguage);
  const releaseBase = 'https://github.com/binarrii/MoreClock/releases';
  assert.equal(app.fileSize, '2974465 bytes');
  assert.equal(app.downloadUrl, `${releaseBase}/download/v1.0.1/MoreClock-1.0.1-universal.dmg`);
  assert.equal((html.split(`href="${app.downloadUrl}"`).length - 1), 3);
  assert.equal(app.releaseNotes, `${releaseBase}/tag/v1.0.1`);
  assert.ok(html.includes(`href="${app.releaseNotes}"`));
  assert.ok(!html.includes('{{'), `${locale}: unresolved template token`);
  assert.ok(html.includes(m.hero_title)); assert.ok(html.includes(m.hero_lead));
  const runtime = scriptData(html, 'site-i18n');
  assert.equal(runtime.locale, locale);
  assert.equal(runtime.dateLocale, m.date_locale);
  assert.equal(runtime.cities['Asia/Hong_Kong'].name, m.city_hong_kong);
  const cityOptions = html.match(/<select id="city-select">([\s\S]*?)<\/select>/)[1];
  const zoneValues = [...html.matchAll(/(?:data-clock|data-time-zone)="([^"]+)"/g), ...cityOptions.matchAll(/value="([^"]+)"/g)].map(match => match[1]);
  assert.equal(zoneValues.length, 11);
  for (const zone of zoneValues) {
    assert.ok(runtime.cities[zone], `${locale}: translated or unknown time-zone identifier ${zone}`);
    assert.doesNotThrow(() => new Intl.DateTimeFormat(runtime.timeLocale, { timeZone: zone }).format(new Date()));
  }
  const faq = schema['@graph'].find(item => item['@type'] === 'FAQPage');
  const visibleFaq = [...html.matchAll(/<div class="faq__item"><h3>(.*?)<\/h3><p>([\s\S]*?)<\/p><\/div>/g)];
  assert.equal(faq.mainEntity.length, 5); assert.equal(visibleFaq.length, 5);
  faq.mainEntity.forEach((question, index) => {
    assert.equal(question.name, plain(visibleFaq[index][1]));
    assert.equal(question.acceptedAnswer.text, plain(visibleFaq[index][2]));
  });
  for (const match of html.matchAll(/(?:src|href)="([^"#][^"]*)"/g)) {
    const target = new URL(match[1], canonical);
    if (target.origin !== origin) continue;
    const localPath = target.pathname.endsWith('/') ? `${target.pathname}index.html` : target.pathname;
    assert.ok(fs.existsSync(new URL(localPath.slice(1), root)), `${locale}: missing asset ${target.pathname}`);
  }
  const choices = Object.fromEntries([...html.matchAll(/data-language-choice="([^"]+)" href="([^"]+)"/g)].map(match => [match[1], match[2]]));
  assert.deepEqual(choices, { system: '/?lang=system', ...routes });
  const embeddedRoutes = html.match(/<script src="\/language.js" data-routes="([^"]+)">/)[1];
  assert.deepEqual(JSON.parse(plain(embeddedRoutes)), routes);
  for (const { id, flag, name } of locales) {
    const item = html.match(new RegExp(`<a data-language-choice="${id}"[^>]*>(.*?)<\\/a>`))[1];
    assert.match(flag, /^\p{Regional_Indicator}{2}$/u);
    assert.equal(plain(item), `${flag} ${name}`);
  }
  assert.equal(locales.find(item => item.id === 'zh-Hant').flag, '🇭🇰');
  const image = html.match(/<meta property="og:image" content="([^"]+)">/)[1];
  assert.equal(new URL(image).origin, origin);
  assert.ok(fs.existsSync(new URL(new URL(image).pathname.slice(1), root)));
  const geo = fs.readFileSync(new URL(`${m.path.slice(1)}llms.txt`, root), 'utf8');
  assert.ok(geo.includes(app.downloadUrl));
  assert.ok(geo.includes(original ? m.geo_intro : m.hero_lead));
  for (const edition of locales) {
    assert.ok(geo.includes(`](${origin + edition.path})`));
    assert.ok(geo.includes(`](${origin + edition.path}llms.txt)`));
  }
  assert.ok(sitemap.includes(`<loc>${canonical}</loc>`));
  const readme = { 'zh-CN': 'docs/readmes/README.zh-CN.md', 'zh-Hant': 'docs/readmes/README.zh-Hant.md' }[locale] ?? 'README.md';
  const documentation = `https://github.com/binarrii/MoreClock/blob/main/${readme}`;
  assert.ok(fs.existsSync(new URL(`../../${readme}`, import.meta.url)), `${locale}: missing ${readme}`);
  assert.ok(html.includes(`href="${documentation}"`), `${locale}: missing HTML documentation link`);
  assert.ok(geo.includes(`](${documentation})`), `${locale}: missing GEO documentation link`);
  if (locale === 'zh-CN') {
    assert.match(m.meta_description, /菜单栏/); assert.ok(geo.includes('2,974,465'));
    assert.ok(html.includes('https://support.apple.com/zh-cn/102445'));
    assert.ok(!html.includes('World clocks for your Mac'));
  }
  checkInteractions(runtime, m);
  console.log(`PASS ${locale}: static content, language switch, canonical/hreflang/social metadata, localized JSON-LD and FAQ parity, GEO facts, assets and interactive previews`);
}
assert.equal((sitemap.match(/<url>/g) ?? []).length, locales.length);
for (const block of sitemap.matchAll(/<url>(.*?)<\/url>/gs)) {
  for (const [lang, url] of Object.entries(expectedAlternates)) assert.ok(block[1].includes(`hreflang="${lang}" href="${url}"`));
}
assert.ok(fs.readFileSync(new URL('robots.txt', root), 'utf8').includes(`${origin}/sitemap.xml`));
assert.ok(fs.readFileSync(new URL('404.html', root), 'utf8').includes('noindex'));
console.log('PASS reciprocal multilingual sitemap, robots and non-indexable 404');

const languageScript = fs.readFileSync(new URL('language.js', root), 'utf8');
const storageKey = 'moreclock.websiteLanguage';
function checkNavigation(path, primary, values = new Map(), blocked = false) {
  let onClick;
  let replaced;
  let cleaned;
  const window = {
    location: { href: origin + path, replace: value => { replaced = value; } },
    history: { replaceState: (_state, _unused, value) => { cleaned = value; } },
    get localStorage() { if (blocked) throw new Error('Storage blocked'); return values; },
  };
  values.getItem = key => values.get(key) ?? null;
  values.setItem = (key, value) => values.set(key, value);
  values.removeItem = key => values.delete(key);
  const document = {
    currentScript: { dataset: { routes: JSON.stringify(routes) } },
    addEventListener: (name, callback) => { if (name === 'click') onClick = callback; },
  };
  vm.runInNewContext(languageScript, { window, document, URL, navigator: primary ? { languages: [primary, 'zh-CN'], language: 'en' } : { language: 'zh-TW' } });
  return { replaced, cleaned, choose(locale) {
    const link = { dataset: { languageChoice: locale }, href: origin + routes[locale] };
    onClick({ target: { closest: () => link } });
    return link.href;
  } };
}
for (const [browser, path] of [['zh', '/zh-CN/'], ['zh-TW', '/zh-Hant/'], ['zh-Hant-HK', '/zh-Hant/'], ['zh-Hans-TW', '/zh-CN/'], ['pt-PT', '/pt-BR/'], ['de-AT', '/de/'], ['fa-IR', '/fa/'], ['ja-JP', '/ja/']]) {
  assert.equal(checkNavigation('/', browser).replaced, origin + path);
}
for (const locale of locales) {
  const expected = locale.id === 'en' ? undefined : origin + locale.path;
  assert.equal(checkNavigation('/', locale.lang).replaced, expected);
  if (locale.path !== '/') assert.equal(checkNavigation(locale.path, 'en-US').replaced, undefined);
}
assert.equal(checkNavigation('/', 'nl-NL').replaced, undefined);
assert.equal(checkNavigation('/', 'en-US').replaced, undefined);
assert.equal(checkNavigation('/', undefined).replaced, origin + '/zh-Hant/');
assert.equal(checkNavigation('/?ref=download#clocks', 'zh-CN').replaced, origin + '/zh-CN/?ref=download#clocks');
const saved = new Map();
checkNavigation('/zh-CN/', 'zh-CN', saved).choose('en');
assert.equal(saved.get(storageKey), 'en');
assert.equal(checkNavigation('/', 'zh-CN', saved).replaced, undefined);
checkNavigation('/', 'en-US', saved).choose('fa');
assert.equal(checkNavigation('/', 'en-US', saved).replaced, origin + '/fa/');
assert.equal(checkNavigation('/?lang=system', 'de-DE', saved).replaced, origin + '/de/');
assert.ok(!saved.has(storageKey));
assert.equal(checkNavigation('/?lang=system', 'en-GB').cleaned, origin + '/');
assert.equal(checkNavigation('/zh-CN/', 'zh-CN', new Map(), true).choose('en'), origin + '/?lang=en');
assert.equal(checkNavigation('/?lang=en', 'zh-CN', new Map(), true).replaced, undefined);
console.log('PASS browser language detection, saved choice, system reset, direct links and blocked storage');

function checkInteractions(runtime, m) {
  class Element {
    constructor(value = '', attrs = {}) { this.value = value; this.attrs = attrs; this.dataset = {}; this.style = {}; this.listeners = {}; this.textContent = ''; this.checked = false; this.hidden = false; }
    addEventListener(name, fn) { (this.listeners[name] ??= []).push(fn); }
    setAttribute(name, value) { this.attrs[name] = value; }
    getAttribute(name) { return this.attrs[name]; }
    focus() { this.focused = true; }
    fire(name, event = {}) { for (const fn of this.listeners[name] ?? []) fn(event); }
  }
  const ids = Object.fromEntries(['city-select', 'prefix-input', 'date-select', 'bold-check', 'preview-city', 'preview-flag', 'preview-time', 'preview-date', 'preview-offset', 'settings-city', 'settings-flag', 'settings-output', 'general-pane', 'clocks-pane', 'about-pane', 'site-i18n'].map(id => [id, new Element()]));
  ids['site-i18n'].textContent = JSON.stringify(runtime);
  ids['city-select'].value = 'Asia/Hong_Kong'; ids['prefix-input'].value = '🇭🇰'; ids['date-select'].value = 'off';
  const zones = ['Europe/London', 'Asia/Hong_Kong', 'America/Los_Angeles'];
  const times = zones.map(zone => { const el = new Element(); el.dataset.timeZone = zone; return el; });
  const clocks = zones.map(zone => { const el = new Element(); el.dataset.clock = zone; return el; });
  const tabs = ['general', 'clocks', 'about'].map(name => new Element('', { 'aria-controls': `${name}-pane` }));
  const fixed = new Date('2026-11-17T12:00:00Z');
  class FixedDate extends Date { constructor(...args) { super(...(args.length ? args : [fixed])); } static now() { return +fixed; } }
  const document = {
    querySelector: selector => ids[selector.slice(1)],
    querySelectorAll: selector => selector === '[data-time-zone]' ? times : selector === '[data-clock]' ? clocks : tabs,
    getElementById: id => ids[id],
  };
  vm.runInNewContext(fs.readFileSync(new URL('site.js', root), 'utf8'), { document, Intl, Date: FixedDate, window: { setTimeout() {} } });
  const formattedTime = timeZone => new Intl.DateTimeFormat(runtime.timeLocale, { timeZone, hour: '2-digit', minute: '2-digit', hourCycle: 'h23' }).format(fixed);
  assert.equal(ids['preview-city'].textContent, m.city_hong_kong);
  assert.equal(ids['preview-time'].textContent, formattedTime('Asia/Hong_Kong'));
  clocks[0].fire('click');
  assert.equal(ids['preview-city'].textContent, m.city_london);
  assert.equal(ids['preview-time'].textContent, formattedTime('Europe/London'));
  assert.equal(clocks[0].attrs['aria-pressed'], 'true');
  assert.equal(ids['preview-date'].textContent, new Intl.DateTimeFormat(runtime.dateLocale, {
    timeZone: 'Europe/London', weekday: 'long', month: 'long', day: 'numeric',
  }).format(fixed));
  ids['prefix-input'].value = 'Team'; ids['city-select'].value = 'Asia/Tokyo'; ids['city-select'].fire('change');
  assert.equal(ids['prefix-input'].value, 'Team');
  assert.equal(ids['settings-output'].textContent, `Team ${formattedTime('Asia/Tokyo')}`);
  assert.equal(ids['settings-city'].textContent, m.city_tokyo);
  ids['prefix-input'].value = ''; ids['city-select'].fire('change'); assert.equal(ids['prefix-input'].value, '🇯🇵');
  ids['date-select'].value = 'both'; ids['date-select'].fire('input');
  const tokyoDate = new Intl.DateTimeFormat(runtime.dateLocale, {
    timeZone: 'Asia/Tokyo', weekday: 'short', month: 'short', day: 'numeric',
  }).format(fixed);
  assert.equal(ids['settings-output'].textContent, `🇯🇵 ${tokyoDate} ${formattedTime('Asia/Tokyo')}`);
  ids['bold-check'].checked = true; ids['bold-check'].fire('input'); assert.equal(ids['settings-output'].style.fontWeight, '700');
  tabs[2].fire('click'); assert.equal(ids['about-pane'].hidden, false); assert.equal(ids['clocks-pane'].hidden, true);
  let prevented = false;
  tabs[2].fire('keydown', { key: 'ArrowRight', preventDefault() { prevented = true; } });
  assert.ok(prevented); assert.ok(tabs[0].focused); assert.equal(ids['general-pane'].hidden, false);
}
