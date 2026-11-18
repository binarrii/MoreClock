# Website validation

## 13-language update

- `npm run check` covered all 13 editions, including localized titles, FAQ answer parity, reciprocal `hreflang`, the sitemap, language headers and every locale’s GEO fact sheet.
- Routing tests covered browser language selection, both Chinese scripts, English fallback, saved preferences, System Default and restricted browser storage.
- Local Chrome checks verified the Arabic picker at 320px, navigation to Persian, saved-language redirects and resetting to the browser language. English and French navigation were checked at 1024px.
- The results below describe the earlier English and Simplified Chinese release.

## Build and content

- Kind: software, a native macOS menu-bar clock app.
- The existing blue-black-cornflower palette, Instrument Sans / DM Mono pairing, centred hero, tonal buttons and column footer are preserved. The still silk-folds background and iris-opens Settings transition use the unchanged kit runtime.
- English at `/`; Simplified Chinese at `/zh-CN/`. The homepage uses the browser’s primary language or a saved manual choice. Chinese tags open the Simplified Chinese page, and other tags default to English. Direct links to `/zh-CN/` keep that language.
- Shared source: `templates/index.html`; translation catalogs: `locales/en.json` and `locales/zh-CN.json`; static generator: `scripts/build.mjs`. Missing, empty or mismatched translation keys fail the build. Both pages contain their localized content before JavaScript runs.
- Chinese translations cover product copy, navigation, accessible names, settings controls, city names, example dates, FAQ, footer and source links. Preview dates use `Intl.DateTimeFormat` with the page locale; IANA identifiers remain unchanged. Asynchronously mounted animation controls also receive localized labels.
- No invented price, rating, review or customer count. The app's English and 12 translations remain distinct from the website's English and Simplified Chinese editions.
- Product artwork: the real app icon, repository General settings screenshot, and a separate screenshot-based hero sharing image for each website language. No stock or stand-in assets.

## SEO and GEO

- Both pages have their own title, description, canonical URL, Open Graph URL/locale/alternate locale/image, Twitter card and HTML language.
- Reciprocal `en`, `zh-Hans` and `x-default` links appear in each head and sitemap entry. `x-default` points to English. The Chinese URL is `/zh-CN/`; its language tag is `zh-Hans`, identifying Simplified Chinese without restricting the audience to a country.
- Localized WebPage, SoftwareApplication descriptions/features, and FAQ JSON-LD. The SoftwareApplication entity preserves the app's 13 supported languages; the WebSite entity declares two languages.
- FAQ question and answer text is checked against visible content, including the localized Apple support link.
- English and Chinese `llms.txt` fact sheets link to each other, both website pages, the release/download/checksum, the matching README language, issues and Apple guidance. These are sourced facts, not a promise of indexing or citations.
- Locale-specific Content-Language headers and UTF-8 fact sheet MIME types. Global crawl access remains enabled. The bilingual error page retains `noindex` and HTTP 404 handling.

## Verification

- `npm run check`: passed for both languages. Covers metadata, reciprocal alternates, exact FAQ parity, GEO files, local links/assets, all DOM time-zone attributes/options, localized runtime dates/cities, custom prefix preservation, date/bold controls and keyboard tabs.
- A browser check caught a translated IANA identifier during implementation. The shared template was corrected and the generated-HTML identifier checks were added before deployment. Final Chinese desktop/phone captures have no browser runtime exceptions.
- Chinese layout checked at 1440×900, 1024×768, 820×1180, 768×1024 and 390×844. The actual hero title takes one desktop line and two phone lines. No sideways overflow was found in the 320px walk. Narrow-desktop FAQ spacing was adjusted to keep translated answers readable.
- Both desktop/phone finish gates passed, including reduced-motion, rendering, focus, accessibility names, hidden-content and motion checks. English copy lint has no failures or warnings; Chinese phrase/word-count warnings from the English-oriented checker are retained rather than inserting artificial English copy.
- Chinese CPU Chrome performance: zero failures, three warnings. Approximately 634 KiB transferred on desktop and 587 KiB on phone; median LCP 312 ms / 284 ms; CLS 0.002 / 0. These are local synthetic measurements, not field-performance claims.
- Retained performance warnings: the already-loaded app icon reused below the fold, and the real settings screenshot exceeding the strict desktop 2.2× source-size threshold. These do not add extra image requests for the repeated icon or obscure the UI.
- Wrangler dry-run passed before deployment. Production excludes source templates/catalogs, browser profiles, scratch data and generated checker reports.
- Deployed bilingual version: `549d6df6-e7e2-4f31-99fb-4216f5fa70e9`. Both live URLs returned HTTP 200 over normal HTTPS with the expected Content-Language header (`en` / `zh-Hans`). Product HTML and JSON-LD matched the generated source; Cloudflare's managed markup outside the product content was not treated as a source difference.
- Both live GEO fact sheets, the multilingual sitemap, separate sharing images, JS and CSS matched local bytes. Fact sheets were served as UTF-8 plain text. `/zh-CN` redirected to `/zh-CN/` with HTTP 307. Unknown localized pages, source catalogs/templates and checker report URLs returned HTTP 404.

## Documented checker exceptions

The kit runtime was not edited. The exact waivers are in `.taste-skill/waivers.json`:

1. `container-edges` on the iris stage: the unchanged module intentionally generates its transition overlay beside the content wrap.
2. `text-only` on the mobile FAQ: the section recipe explicitly permits a pictureless, open FAQ; the screenshot is a desktop enhancement.
3. `one-sided` on the desktop FAQ screenshot: the image occupies the left column while answers occupy the right column to the content edge.
4. `hero-lines` on the Chinese stress test: the checker pads to 36 characters, a maximum calibrated for Latin glyph widths. The actual Chinese category heading fits at every tested width. Text was not shrunk to clear the test.
5. `one-section` on the tablet menu-bar preview: its toolbar and time-zone buttons are the product itself, not a separate content band.

English gate: exceptions 1–3, no open failures. Chinese gate: exceptions 1–4, no open failures. Nonblocking warnings remain for native-preview styling, transition spacing, nav/heading wording, repeated nav/hero action, tonal button contrast, FAQ density and tablet whitespace.

## Limits

- Screenshots and automated DOM/layout checks ran. External screenshot critique was not performed; the earlier MiniMax upload was blocked by automatic permission review.
- The research agents failed to start, so no independent agent review is claimed. Multilingual search guidance was read directly from Google Search Central.
- No search-engine account verification, indexing submission, rich-result approval or AI-citation measurement was performed. `llms.txt` is advisory.
