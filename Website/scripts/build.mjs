import fs from 'node:fs';
import path from 'node:path';
import { fileURLToPath } from 'node:url';
import { locales } from '../locales/registry.mjs';
import { compactCatalog } from '../locales/additional.mjs';

const project = fileURLToPath(new URL('../', import.meta.url));
const publicDir = path.join(project, 'public');
const template = fs.readFileSync(path.join(project, 'templates/index.html'), 'utf8');
const origin = 'https://moreclock.skyviiew.com';
const repo = 'https://github.com/binarrii/MoreClock';
const version = '1.0.1';
const build = 8;
const dmgBytes = 2974465;
const dmgSize = `${(dmgBytes / 1_000_000).toFixed(1)} MB`;
const release = `${repo}/releases/tag/v${version}`;
const releaseAssets = `${repo}/releases/download/v${version}`;
const download = `${releaseAssets}/MoreClock-${version}-universal.dmg`;
const appIcon = `${origin}/media/app-icon.png`;
const languageTags = locales.map(locale => locale.lang);
const routes = Object.fromEntries(locales.map(locale => [locale.id, locale.path]));
const existing = new Set(['en', 'zh-CN']);
const escape = value => String(value).replaceAll('&', '&amp;').replaceAll('<', '&lt;').replaceAll('>', '&gt;').replaceAll('"', '&quot;').replaceAll("'", '&#39;');
const json = value => JSON.stringify(value, null, 2).replaceAll('<', '\\u003c');
const catalogs = locales.map(locale => {
  const file = path.join(project, `locales/${locale.id}`);
  if (existing.has(locale.id)) return { ...JSON.parse(fs.readFileSync(`${file}.json`, 'utf8')), ...locale };
  const messages = compactCatalog(locale.id, fs.readFileSync(`${file}.txt`, 'utf8'));
  const sentenceEnd = ['ja', 'zh-Hant'].includes(locale.id) ? '。' : '.';
  const date = new Date('2026-11-18T09:41:00Z');
  const format = options => new Intl.DateTimeFormat(locale.lang, { ...options, timeZone: 'UTC' }).format(date);
  const dateExample = options => `🇯🇵 ${format(options)} 18:41`;
  return {
    ...messages,
    ...locale,
    meta_title: `MoreClock · ${messages.hero_title}`,
    meta_description: messages.hero_lead,
    og_description: messages.hero_lead,
    app_description: messages.clocks_lead,
    home_aria: 'MoreClock',
    preview_aria: `MoreClock · ${messages.menu_bar}`,
    zones_aria: messages.time_zone,
    london_aria: messages.city_london,
    hong_kong_aria: messages.city_hong_kong,
    san_francisco_aria: messages.city_san_francisco,
    settings_aria: `MoreClock · ${messages.settings_link}`,
    tabs_aria: messages.settings_link,
    system_default: locale.system,
    hero_version: `${messages.version_label} ${version} · macOS 26+`,
    about_version: `${messages.version_label} ${version} (${build})`,
    close_version: `${messages.version_label} ${version} · ${messages.universal_label} · ${dmgSize}`,
    preview_date: format({ weekday: 'long', month: 'long', day: 'numeric' }),
    date_example_weekday: dateExample({ weekday: 'short' }),
    date_example_date: dateExample({ month: 'short', day: 'numeric' }),
    date_example_both: dateExample({ weekday: 'short', month: 'short', day: 'numeric' }),
    date_options_aria: messages.date_display,
    languages_aria: messages.language,
    date_locale: locale.lang,
    time_locale: locale.lang,
    sentence_end: sentenceEnd,
    geo_intro: messages.hero_lead,
    geo_facts_heading: messages.facts_label,
    geo_languages_heading: messages.language,
    geo_facts: [
      `${messages.version_label} ${version} (${build})`, messages.faq_compat_answer,
      messages.clocks_lead, messages.date_lead, messages.language_lead,
      messages.faq_shortcuts_answer, messages.faq_settings_answer,
      messages.faq_arrange_answer, messages.faq_warning_answer,
    ],
    features: [messages.clocks_lead, messages.date_lead, messages.language_lead, messages.faq_shortcuts_answer],
    geo_source_labels: [messages.facts_label, messages.documentation, messages.release_notes,
      messages.download, 'SHA-256', messages.issue, messages.apple_guidance],
  };
});

function links(m) {
  const readme = m.lang.startsWith('zh') ? 'README.zh-CN.md' : 'README.md';
  return { documentation: `${repo}/blob/main/${readme}`, apple: `https://support.apple.com/${m.apple}/102445` };
}

function seoHead(m) {
  const url = origin + m.path;
  const image = existing.has(m.id) ? `${url}share.jpg` : appIcon;
  const sourceLinks = links(m);
  const faq = ['compat', 'warning', 'settings', 'arrange', 'shortcuts'].map(key => ({
    '@type': 'Question', name: m[`faq_${key}_question`],
    acceptedAnswer: { '@type': 'Answer', text: key === 'warning'
      ? `${m.faq_warning_answer} ${m.apple_guidance}${m.sentence_end ?? (m.id === 'zh-CN' ? '。' : '.')}`
      : m[`faq_${key}_answer`], ...(key === 'warning' ? { url: sourceLinks.apple } : {}) },
  }));
  const graph = {
    '@context': 'https://schema.org', '@graph': [
      { '@type': 'WebSite', '@id': `${origin}/#website`, url: `${origin}/`, name: 'MoreClock', inLanguage: languageTags },
      { '@type': 'WebPage', '@id': `${url}#webpage`, url, name: m.meta_title, description: m.meta_description,
        isPartOf: { '@id': `${origin}/#website` }, mainEntity: { '@id': `${origin}/#app` }, inLanguage: m.lang, primaryImageOfPage: image },
      { '@type': 'SoftwareApplication', '@id': `${origin}/#app`, name: 'MoreClock', url, description: m.app_description,
        applicationCategory: 'UtilitiesApplication', operatingSystem: 'macOS 26+', softwareVersion: version,
        processorRequirements: 'Apple silicon, Intel', downloadUrl: download, fileSize: `${dmgBytes} bytes`, releaseNotes: release,
        image: appIcon, screenshot: `${origin}/media/clock-settings.png`, sameAs: repo,
        inLanguage: languageTags, featureList: m.features },
      { '@type': 'FAQPage', '@id': `${url}#questions`, isPartOf: { '@id': `${url}#webpage` }, inLanguage: m.lang, mainEntity: faq },
    ],
  };
  return `<meta charset="utf-8">
<meta name="viewport" content="width=device-width, initial-scale=1, viewport-fit=cover">
<title>${escape(m.meta_title)}</title>
<meta name="description" content="${escape(m.meta_description)}">
<meta name="page-type" content="software"><meta name="site-kind" content="software">
<meta name="theme-color" content="#0a0d14">
<meta name="robots" content="index, follow, max-image-preview:large, max-snippet:-1, max-video-preview:-1">
<link rel="canonical" href="${url}">
${locales.map(item => `<link rel="alternate" hreflang="${item.lang}" href="${origin + item.path}">`).join('\n')}
<link rel="alternate" hreflang="x-default" href="${origin}/">
<link rel="alternate" type="text/plain" href="${url}llms.txt" title="${escape(m.facts_label)}">
<meta property="og:type" content="website"><meta property="og:url" content="${url}">
<meta property="og:title" content="${escape(m.meta_title)}">
<meta property="og:description" content="${escape(m.og_description)}">
<meta property="og:locale" content="${m.og}">
${locales.filter(item => item.id !== m.id).map(item => `<meta property="og:locale:alternate" content="${item.og}">`).join('\n')}
<meta property="og:image" content="${image}"><meta property="og:image:alt" content="${escape(existing.has(m.id) ? m.hero_title : 'MoreClock')}">
<meta name="twitter:card" content="${existing.has(m.id) ? 'summary_large_image' : 'summary'}"><meta name="twitter:title" content="${escape(m.meta_title)}">
<meta name="twitter:description" content="${escape(m.og_description)}"><meta name="twitter:image" content="${image}">
<link rel="icon" type="image/png" href="/media/app-icon.png"><link rel="apple-touch-icon" href="/media/app-icon.png">
<script type="application/ld+json">${json(graph)}</script>`;
}

function geoText(m) {
  const sourceLinks = links(m);
  const sources = [origin + m.path, sourceLinks.documentation, release, download,
    `${releaseAssets}/SHA256SUMS.txt`, `${repo}/issues`, sourceLinks.apple];
  const editions = catalogs.map(item => `- [${item.name}](${origin + item.path}) · [${item.facts_label}](${origin + item.path}llms.txt)`);
  return `# MoreClock\n\n> ${m.geo_intro}\n\n## ${m.geo_languages_heading}\n\n${editions.join('\n')}\n\n## ${m.geo_facts_heading}\n\n${m.geo_facts.map(fact => `- ${fact}`).join('\n')}\n\n## ${m.geo_sources_heading}\n\n${sources.map((url, i) => `- [${m.geo_source_labels[i]}](${url})`).join('\n')}\n`;
}

function languagePicker(m) {
  const label = m.id === 'en' ? 'Language' : m.language;
  const displayName = item => `<span class="language-picker__flag" aria-hidden="true">${escape(item.flag)}</span> <bdi dir="${item.dir}">${escape(item.name)}</bdi>`;
  return `<details class="language-picker">
  <summary class="nav__link" aria-label="${escape(`${label} · ${m.name}`)}">${displayName(m)} <span class="language-picker__chevron" aria-hidden="true"></span></summary>
  <ul class="language-picker__options">
    <li><a data-language-choice="system" href="/?lang=system">${escape(m.system)}</a></li>
    ${locales.map(item => `<li><a data-language-choice="${item.id}" href="${item.path}" lang="${item.lang}" hreflang="${item.lang}"${item.id === m.id ? ' aria-current="page"' : ''}>${displayName(item)}</a></li>`).join('\n    ')}
  </ul>
</details>`;
}

for (const m of catalogs) {
  const sourceLinks = links(m);
  const cities = {
    'Europe/London': { name: m.city_london, flag: '🇬🇧' },
    'Asia/Hong_Kong': { name: m.city_hong_kong, flag: '🇭🇰' },
    'America/Los_Angeles': { name: m.city_san_francisco, flag: '🇺🇸' },
    'Asia/Tokyo': { name: m.city_tokyo, flag: '🇯🇵' },
    'Europe/Berlin': { name: m.city_berlin, flag: '🇩🇪' },
  };
  const raw = {
    seo_head: seoHead(m),
    language_picker: languagePicker(m),
    runtime_messages: json({ locale: m.id, dateLocale: m.date_locale, timeLocale: m.time_locale, cities, animationLabels: { pause: m.animation_pause, play: m.animation_play } }),
  };
  const values = { ...m, html_lang: m.lang, locale: m.id, locale_routes: JSON.stringify(routes), documentation_url: sourceLinks.documentation,
    apple_guidance_url: sourceLinks.apple, download_url: download, release_url: release, sentence_end: m.sentence_end ?? (m.id === 'zh-CN' ? '。' : '.') };
  const html = template.replace(/\{\{([a-z0-9_]+)\}\}/g, (_, key) => {
    if (Object.hasOwn(raw, key)) return raw[key];
    if (!Object.hasOwn(values, key) || typeof values[key] !== 'string' || !values[key].trim()) throw new Error(`Missing template key: ${m.id}.${key}`);
    return escape(values[key]);
  });
  const dir = path.join(publicDir, m.path);
  fs.mkdirSync(dir, { recursive: true });
  fs.writeFileSync(path.join(dir, 'index.html'), html);
  fs.writeFileSync(path.join(dir, 'llms.txt'), geoText(m));
  console.log(`Built ${m.id}: ${m.path}`);
}
const alternates = [...locales, { lang: 'x-default', path: '/' }].map(m => `    <xhtml:link rel="alternate" hreflang="${m.lang}" href="${origin + m.path}"/>`).join('\n');
fs.writeFileSync(path.join(publicDir, 'sitemap.xml'), `<?xml version="1.0" encoding="UTF-8"?>\n<urlset xmlns="http://www.sitemaps.org/schemas/sitemap/0.9" xmlns:xhtml="http://www.w3.org/1999/xhtml">\n${locales.map(m => `  <url>\n    <loc>${origin + m.path}</loc>\n${alternates}\n  </url>`).join('\n')}\n</urlset>\n`);
const headerBase = fs.readFileSync(path.join(project, 'templates/headers.txt'), 'utf8').trimEnd();
const localizedHeaders = locales.map(m => `${m.path}\n  Content-Language: ${m.lang}\n\n${m.path}llms.txt\n  Content-Language: ${m.lang}\n  Content-Type: text/plain; charset=utf-8`).join('\n\n');
fs.writeFileSync(path.join(publicDir, '_headers'), `${headerBase}\n\n${localizedHeaders}\n`);
