# RIP Addons (WoW AddOn)

Cross-reference your installed addons against the impacted list from ripaddons.com and show severity in-game.

- Source tracker: [ert00034/midnight-hitlist](https://github.com/ert00034/midnight-hitlist)
- Website: `https://ripaddons.com`

## What it does
- Scans installed addons by folder name and normalizes names
- Matches against an embedded impacted list and sorts by severity
- Outputs a chat summary and provides a simple scrollable UI
- Commands: `/ripaddons scan | show | hide`
- Keybinding: "RIP Addons: Toggle"

## Install (manual)
1. Download a release zip and extract to your WoW `Interface/AddOns/` so you have `Interface/AddOns/RipAddons/`.
2. In-game, run `/ripaddons scan` or bind the toggle keybinding.

## Install via WowUp (recommended)
1. Copy the stable download URL:
   - `https://github.com/ert00034/rip-addons-addon/releases/latest/download/RipAddons.zip`
2. In WowUp:
   - Addons → Install from URL → paste the link → Install
3. Ensure Auto Update is enabled so WowUp pulls nightly releases automatically.

## Data updates
This addon reads `RipAddons/data/impacted_addons.lua`:

```lua
RipAddons_ImpactedData = {
  version = "YYYY-MM-DD",
  addons = {
    ["weakauras"] = { severity = "high", note = "Example", link = "https://ripaddons.com" },
    ["dbmcore"] = { severity = "medium", note = "Example", link = "https://ripaddons.com" },
  }
}
```

Normalization rule: lowercase; remove non-alphanumerics. Example: `DBM-Core` → `dbmcore`.

Update this file from your source of truth (`ripaddons.com` or exports from [midnight-hitlist](https://github.com/ert00034/midnight-hitlist)).

## Releasing for WowUp/CurseForge
- Tag the repo with `vX.Y.Z`. A GitHub Action will:
  - replace `@project-version@` in `RipAddons/RipAddons.toc`
  - zip the `RipAddons` folder as `RipAddons-vX.Y.Z.zip`
  - attach the zip to the GitHub Release
- Upload the same zip to CurseForge/Wago if desired.

## Automated data updates
- Provide a JSON feed URL in repo secrets: `IMPACTED_FEED_URL`.
- Format options:
  - Object with version + items: `{ "version": "YYYY-MM-DD", "items": [ { "slug": "dbmcore", "severity": "high", "note": "…", "link": "…" } ] }`
  - Or an array: `[ { "name": "DBM-Core", "severity": "medium", "note": "…" } ]`
- A scheduled workflow runs daily to fetch the feed and regenerate `RipAddons/data/impacted_addons.lua`.
- You can also run locally:

```bash
node scripts/generate-impacted.js --in path-or-url-to-feed.json --out RipAddons/data/impacted_addons.lua
```

### Nightly automated releases
- When the daily update workflow detects changes in the generated Lua file, it will:
  - commit the update
  - create a version tag like `vYYYY.MM.DD-HHMM`
  - push the tag, which triggers the release workflow to package `RipAddons-v*.zip`
- Result: GitHub Releases always has a fresh zip containing up-to-date impacted addons, and WowUp/CurseForge can ingest the latest zip automatically or manually.

## License
MIT

## Credits
Data/idea from `ripaddons.com` and [midnight-hitlist](https://github.com/ert00034/midnight-hitlist).
