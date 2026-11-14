# Timezone Board

Mobile-friendly static page that shows office local times (with DST labels) and relative analysis against major world cities: **D+1**, **D−1**, and **03:00–04:00**.

## Open locally

Open `index.html` in a browser, or from this folder:

```bash
# Python
python -m http.server 8080

# Node
npx --yes serve .
```

Then visit `http://localhost:8080` (or the URL shown).

## GitHub Pages

1. Push this repository to GitHub.
2. Enable **Settings → Pages** (deploy from branch, root `/` or `/docs` as preferred).
3. Open:

```text
https://<user>.github.io/<repo>/timezone_tool/
```

If you set the Pages site root to the `timezone_tool` folder, the site URL is the Pages root.

## Offices

| Code | Place | IANA |
|------|-------|------|
| TW | Taiwan | `Asia/Taipei` |
| GDL | Guadalajara | `America/Mexico_City` |
| HOU | Houston | `America/Chicago` |
| SJ / LA | San Jose / Los Angeles | `America/Los_Angeles` |

Design notes (Chinese): see [DESIGN.md](DESIGN.md).
