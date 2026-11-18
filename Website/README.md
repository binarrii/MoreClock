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

## Check

```bash
npm run check
```

Checks structured data, canonical and crawl links, required local files, FAQ question parity, time-zone conversion, custom prefixes, date/bold controls, tabs and keyboard navigation.

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

When the app version changes, update the visible version, all download links, the SoftwareApplication JSON-LD, `public/llms.txt`, the version assertions in `scripts/check.mjs`, and any relevant app screenshots together. Confirm the public download and checksum before deployment. Regenerate `public/share.jpg` when the hero design changes.

## Search and answer-engine files

- `index.html`: semantic product copy, visible FAQ, canonical link, Open Graph/Twitter metadata, and WebSite/WebPage/SoftwareApplication/FAQPage JSON-LD.
- `robots.txt`: allows public crawling and references the sitemap.
- `sitemap.xml`: the canonical product page only.
- `llms.txt`: sourced product facts, compatibility, release caveats, and links to the repository, release, checksum and support guidance.
- `404.html`: real HTTP 404 response with `noindex`.

The app has no published price or rating in the project sources, so neither is invented for structured data. Structured data and `llms.txt` aid discovery and interpretation; they do not guarantee search-result features, indexing or AI citations. No Search Console/Bing account submission was performed.
