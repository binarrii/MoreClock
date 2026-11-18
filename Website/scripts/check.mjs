import assert from 'node:assert/strict';
import fs from 'node:fs';
import vm from 'node:vm';

const root = new URL('../public/', import.meta.url);
const html = fs.readFileSync(new URL('index.html', root), 'utf8');
const origin = 'https://moreclock.skyviiew.com';
const schema = JSON.parse(html.match(/<script type="application\/ld\+json">([\s\S]*?)<\/script>/)[1]);
const app = schema['@graph'].find(item => item['@type'] === 'SoftwareApplication');
assert.equal(app.name, 'MoreClock');
assert.equal(app.softwareVersion, '1.0.0');
assert.equal(app.inLanguage.length, 13);
assert.match(app.downloadUrl, /^https:\/\/github\.com\/binarrii\/MoreClock\/releases\/download\/v1\.0\.0\//);
assert.ok(html.includes(`<link rel="canonical" href="${origin}/">`));
const faq = schema['@graph'].find(item => item['@type'] === 'FAQPage');
assert.equal(faq.mainEntity.length, 5);
for (const question of faq.mainEntity) assert.ok(html.includes(question.name));
for (const match of html.matchAll(/(?:src|href)="([^"#][^"]*)"/g)) {
  const path = match[1];
  if (/^(https?:|mailto:)/.test(path)) continue;
  assert.ok(fs.existsSync(new URL(path, root)), `Missing local asset: ${path}`);
}
assert.ok(fs.readFileSync(new URL('robots.txt', root), 'utf8').includes(`${origin}/sitemap.xml`));
assert.ok(fs.readFileSync(new URL('sitemap.xml', root), 'utf8').includes(`${origin}/`));
assert.ok(fs.readFileSync(new URL('llms.txt', root), 'utf8').includes(app.downloadUrl));
console.log('PASS canonical, JSON-LD, visible FAQ parity, crawl files and local links');

class Element {
  constructor(value = '', attrs = {}) { this.value = value; this.attrs = attrs; this.dataset = {}; this.style = {}; this.listeners = {}; this.textContent = ''; this.checked = false; this.hidden = false; }
  addEventListener(name, fn) { (this.listeners[name] ??= []).push(fn); }
  setAttribute(name, value) { this.attrs[name] = value; }
  getAttribute(name) { return this.attrs[name]; }
  focus() { this.focused = true; }
  fire(name, event = {}) { for (const fn of this.listeners[name] ?? []) fn(event); }
}
const ids = Object.fromEntries(['city-select', 'prefix-input', 'date-select', 'bold-check', 'preview-city', 'preview-flag', 'preview-time', 'preview-date', 'preview-offset', 'settings-city', 'settings-flag', 'settings-output', 'general-pane', 'clocks-pane', 'about-pane'].map(id => [id, new Element()]));
ids['city-select'].value = 'Asia/Hong_Kong'; ids['prefix-input'].value = '🇭🇰'; ids['date-select'].value = 'off';
const zones = ['Europe/London', 'Asia/Hong_Kong', 'America/Los_Angeles'];
const times = zones.map(zone => { const el = new Element(); el.dataset.timeZone = zone; return el; });
const clocks = zones.map(zone => { const el = new Element(); el.dataset.clock = zone; return el; });
const tabs = ['general', 'clocks', 'about'].map(name => new Element('', {'aria-controls': `${name}-pane`}));
const fixed = new Date('2026-11-17T12:00:00Z');
class FixedDate extends Date { constructor(...args) { super(...(args.length ? args : [fixed])); } static now() { return +fixed; } }
const document = {
  querySelector: selector => ids[selector.slice(1)],
  querySelectorAll: selector => selector === '[data-time-zone]' ? times : selector === '[data-clock]' ? clocks : tabs,
  getElementById: id => ids[id],
};
vm.runInNewContext(fs.readFileSync(new URL('site.js', root), 'utf8'), { document, Intl, Date: FixedDate, window: { setTimeout() {} } });
assert.equal(ids['preview-city'].textContent, 'Hong Kong');
assert.equal(ids['preview-time'].textContent, '20:00');
clocks[0].fire('click');
assert.equal(ids['preview-city'].textContent, 'London');
assert.equal(ids['preview-time'].textContent, '12:00');
assert.equal(clocks[0].attrs['aria-pressed'], 'true');
ids['prefix-input'].value = 'Team'; ids['city-select'].value = 'Asia/Tokyo'; ids['city-select'].fire('change');
assert.equal(ids['prefix-input'].value, 'Team');
assert.equal(ids['settings-output'].textContent, 'Team 21:00');
ids['prefix-input'].value = ''; ids['city-select'].fire('change');
assert.equal(ids['prefix-input'].value, '🇯🇵');
ids['date-select'].value = 'both'; ids['date-select'].fire('input');
assert.match(ids['settings-output'].textContent, /Tue, Nov 17/);
ids['bold-check'].checked = true; ids['bold-check'].fire('input');
assert.equal(ids['settings-output'].style.fontWeight, '700');
tabs[2].fire('click');
assert.equal(ids['about-pane'].hidden, false); assert.equal(ids['clocks-pane'].hidden, true);
let prevented = false;
tabs[2].fire('keydown', {key: 'ArrowRight', preventDefault() { prevented = true; }});
assert.ok(prevented); assert.ok(tabs[0].focused); assert.equal(ids['general-pane'].hidden, false);
console.log('PASS clock selection, time zones, custom prefix preservation, date and bold controls, tabs and keyboard navigation');
