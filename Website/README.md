# MoreClock website

Product site: https://moreclock.skyviiew.com/

Static HTML, CSS and JavaScript, deployed with Cloudflare Workers Static Assets. No server-side application, forms, analytics integration or application secrets are required.

## Work locally

Use Node.js 22 or later.

```bash
npm ci
```

```bash
npm run dev
```

The interactive menu-bar and Settings previews run in the browser. Their controls do not change settings in the installed app.

## Website languages

The site supports the same 13 languages as the Mac app. The language picker follows the app’s order and includes System Default. Arabic and Persian use right-to-left layouts.

On `/`, the site matches the browser’s primary language to a supported edition and falls back to English. Traditional Chinese preferences such as `zh-TW` and `zh-HK` open `/zh-Hant/`. Simplified Chinese opens `/zh-CN/`. Portuguese preferences open the Brazilian Portuguese edition. The picker saves manual choices when browser storage is available. System Default clears that choice. Direct links to localized pages preserve their language.

The locale registry is in `locales/registry.mjs`, translations are in `locales/`, and the shared markup is in `templates/index.html`. Run `npm run build` to regenerate all static HTML, structured data, GEO fact sheets, the sitemap, and Cloudflare language headers. Development, checks and deployment run this build automatically. The homepage defaults to English when JavaScript is disabled, and the localized URLs serve fully translated HTML on their own.

Interactive city names and dates use the page locale. IANA zone identifiers are shared across editions.

## Check

```bash
npm run check
```

Checks all 13 editions for static translations, language-picker links, canonical and alternate URLs, localized social metadata, structured data that matches the visible FAQ, and GEO source links. It also tests browser-language detection, manual choices, System Default, supported time zones, dates, and preview controls.

```bash
npm run check:deploy
```

Responsive, performance and design-gate results are documented in [VALIDATION.md](VALIDATION.md). The design kit runtime is included unchanged; `.gitignore` and `public/.assetsignore` retain/publish only the runtime modules this site uses. Browser profiles, reports, demo pages, scratch files and unused kit artwork are excluded.

## Deploy

Authenticate to the Cloudflare account that owns the `skyviiew.com` zone using Wrangler, then:

```bash
npm run deploy
```

`wrangler.jsonc` configures the `moreclock-website` Worker and the `moreclock.skyviiew.com` custom domain. Cloudflare manages DNS and HTTPS. Check existing records before attaching this config to a different hostname. Never store API tokens or OAuth configuration in the repository.

## Release updates

When the app version changes, update the release facts in `scripts/build.mjs`, the download values in `templates/index.html`, the localized version copy, and the version assertions in `scripts/check.mjs`. Build all editions together and confirm the download and checksum before deployment. The English and Simplified Chinese editions use screenshots of their hero sections for sharing. The other editions use the MoreClock app icon with localized share text.

## Search and answer-engine files

- All locale pages include translated product copy and FAQs, self-referencing canonical URLs, reciprocal `hreflang` links, localized social metadata, and WebSite, WebPage, SoftwareApplication and FAQPage structured data. `x-default` points to `/`.
- `robots.txt` allows public crawling and references the sitemap. `sitemap.xml` lists all 13 canonical pages and their language alternates.
- Each locale’s `llms.txt` includes localized product facts and links to the release, download, checksum and official guidance. Every sheet links to all languages and their fact sheets.
- `_headers`: locale-specific Content-Language headers and UTF-8 plain-text fact sheets.
- `404.html`: real HTTP 404 response with `noindex` and links to both language home pages.

The app has no published price or rating in the project sources, so neither is invented for structured data. Structured data and `llms.txt` aid discovery and interpretation; they do not guarantee search-result features, indexing or AI citations. No Search Console/Bing account submission was performed.
