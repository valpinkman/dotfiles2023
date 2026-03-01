---
name: "manga-downloader"
description: "Automates downloading manga chapters from nyaa.si via Seedr.cc and organizing them into iCloud Drive. Use this skill whenever the user asks to download a manga, fetch new manga chapters, grab manga torrents, or mentions nyaa.si or Seedr in the context of manga. Also trigger when the user says things like \"get the latest chapters of [manga name]\", \"download [manga name]\", or \"check for new [manga name] releases\"."
---

# Manga Downloader

Automates the full pipeline of finding new manga on nyaa.si, downloading through Seedr.cc, and organizing into the user's iCloud Drive manga library.

Run autonomously without asking for confirmation. Search, download, extract, organize, clean up. Only stop to tell the user if something actually goes wrong.

## Prerequisites

Seedr.cc credentials must be available as the `SEEDR_AUTH` environment variable — a Basic auth header string, set in the user's fish config (`~/dotfiles/fish/config.fish`). When running as a scheduled task the value is usually supplied inline in the task prompt; use that. If it's missing entirely, ask the user to set it up:

```fish
set -gx SEEDR_AUTH "Basic <base64_encoded_email:password>"
```

## Library location

```
~/Library/Mobile Documents/com~apple~CloudDocs/Books/Manga/{Series Name}/
```

In a sandboxed bash environment this is mounted elsewhere (e.g. `/sessions/<session>/mnt/Manga/`). Check the path mapping before running shell commands.

Folders suffixed `[ended]` are completed series — skip them when checking for new releases.

## Overview

0. **Survey** — Read the local library to establish exactly what's already there
1. **Search** — Find torrents on nyaa.si
2. **Send to Seedr** — Submit magnet links
3. **Wait & monitor** — Poll until downloads complete
4. **Retrieve** — Pull files down from Seedr
5. **Organize** — Normalize to `.cbz`, rename, move into iCloud
6. **Clean up** — Delete from Seedr, remove temp files

---

## Step 0: Survey the local library

Everything downstream depends on knowing what's already on disk. Get this wrong and you either re-download what's there or skip what's missing.

### List folders in full — never truncate

**Do not use `ls | tail -N` or `ls | head -N` to find the latest item.** Filenames do not sort the way the numbering does:

- ASCII sorts digits before letters, so `Made in Abyss 0073 [Ch].cbz` sorts *before* `Made in Abyss v01 ...`. A `tail -3` on a folder holding both loose chapters and volumes shows only volumes and silently hides every chapter.
- Plain lexical sort also breaks on unpadded numbers (`9` after `10`) and on decimal chapters (`0071.5`, `0071.7`).

Instead, parse the whole folder programmatically. This snippet handles every series in one pass:

```python
import re, pathlib
BASE = pathlib.Path("/path/to/Manga")
for p in sorted(BASE.iterdir()):
    if not p.is_dir() or p.name.endswith("[ended]"):
        continue
    vols, chaps = [], []
    for f in p.rglob("*"):
        if f.suffix.lower() not in (".cbz", ".cbr"):
            continue
        m = re.search(r"\bv(\d+(?:\.\d+)?)\b", f.name)          # "Name v14 (2026) ..."
        if m:
            vols.append(float(m.group(1))); continue
        m = (re.search(r"\b(\d{2,4}(?:\.\d+)?)\b(?=\s*\[Ch\])", f.name)   # "Name 0073 [Ch] ..."
             or re.search(r"\b(\d{3,4}(?:\.\d+)?)\b", f.name))            # bare padded number
        if m:
            chaps.append(float(m.group(1)))
    print(f"{p.name:38} maxVol={max(vols, default=None)}  maxCh={max(chaps, default=None)}")
```

Use `rglob` — some series nest their content (e.g. `JoJo's Bizarre Adventure/Part 9 - The JoJoLands/`), and a flat `iterdir` finds nothing there.

Compare as **numbers, not strings**, and keep decimals intact — `.5` / `.7` interstitial chapters are real and common.

### A folder can hold both volumes AND loose chapters

This is the single most important thing to get right. Do not assume a series folder has one convention.

A typical pattern: volumes `v01`–`v14` covering the backlog, plus loose chapters `0070`, `0071`, `0071.5`, `0071.7`, `0072`, `0073` for everything published since the last volume was compiled. Both belong there.

Consequences:

- Track **two independent high-water marks** per series: highest volume, and highest chapter.
- **Never skip a release because its format doesn't match "the" folder convention.** If a series is volume-based and new loose chapters appear on nyaa, download them. The user would rather have the chapters now and the volume later. Do not reason "this folder uses volumes, so I'll skip the chapters" — that judgment call is wrong.
- A new volume does not make the loose chapters it contains redundant enough to auto-delete. Leave them unless the user asks for a cleanup.
- When reporting "up to date", state both marks (e.g. "v14 + ch 0073").

### Verify before claiming "up to date"

Before telling the user a series has nothing new, confirm the number came from a full folder listing, not a truncated one.

---

## Step 1: Search nyaa.si

RSS returns XML and parses more reliably than HTML:

```
https://nyaa.si/?page=rss&f=0&c=3_1&q={url_encoded_query}
```

Category `3_1` = Literature › English-translated. `f=0` = no filter.

Each `<item>` has `<title>`, `<link>`, `<pubDate>` (RFC 2822), `<nyaa:infoHash>`, `<nyaa:seeders>`, `<nyaa:leechers>`, `<nyaa:downloads>`.

### Rate limiting

nyaa returns **HTTP 429** when queries are fired in parallel. The body is HTML, not XML, so a naive parse yields "no results" and you'll wrongly conclude a series is up to date.

- Fetch **sequentially** with `sleep 3-4` between requests.
- Check each response is real XML — a 429 body is only ~160 bytes. Re-fetch anything under ~1000 bytes after a longer sleep.
- Sandboxed bash tools often cap at 45s per call. Ten sequential queries won't fit in one call — split into batches of ~5.

```bash
cd /tmp/nyaa
fetch(){ curl -s --max-time 20 --get "https://nyaa.si/?page=rss&f=0&c=3_1" \
           --data-urlencode "q=$2" -o "$1.xml"; echo "$1: $(stat -c%s "$1.xml")"; }
fetch onepiece "One Piece"; sleep 3
fetch dandadan "Dandadan"
```

Use `--get --data-urlencode` so spaces and punctuation in titles are encoded correctly.

Parse with a timezone-aware datetime comparison (`parsedate_to_datetime` can return naive datetimes — normalize to UTC before subtracting).

### Catch differently-named uploads

Per-series queries miss releases titled unconventionally. As a safety net, fetch the category feed with no query and regex the titles against all tracked series:

```
https://nyaa.si/?page=rss&f=0&c=3_1
```

**The RSS feed ignores the `p=` page parameter** — requesting `p=1`, `p=2`, `p=3` returns the same 75 items. There is no way to page further back via RSS. The unfiltered feed covers roughly the last 5-7 days at typical upload volume, which is enough for a weekly run but *not* for a wider window. If the user asks for a longer lookback, rely on the per-series queries (which do reach back years) and say plainly that the catch-all sweep only covered the last few days.

### Choosing between candidates

- Prefer `(Digital)` versions.
- Prefer the group already used in that folder (e.g. `1r0n`, `LuCaZ`, `Aquila`, `aro`, `Kaizen`/`TCB`).
- Prefer higher seeder counts.
- Watch for near-name collisions — a search for `Berserk` returns `Berserk of Gluttony`, an unrelated series that uploads frequently and will otherwise look like a fresh release every week. Match the series name at the start of the title.
- Batch packs (`v01-11`, `191-251`) are useful only if they extend past the local high-water mark. Check the range in the title before submitting.

**Time window**: default to the last 7 days, or whatever the user specifies. If nothing is found in the window, say so — don't silently widen it.

### If curl is blocked

Fall back to Claude in Chrome: navigate to `https://nyaa.si/?f=0&c=3_1&q={query}` and read magnet hrefs from the results table.

---

## Step 2: Send magnets to Seedr

Build the magnet from the info hash and **always append extra trackers** — the bare `xt` parameter alone gives poor peer discovery and torrents stall:

```
magnet:?xt=urn:btih:{infoHash}&dn={url_encoded_name}&tr=http://nyaa.tracker.wf:7777/announce&tr=udp://open.stealth.si:80/announce&tr=udp://tracker.opentrackr.org:1337/announce&tr=udp://exodus.desync.com:6969/announce&tr=udp://tracker.torrent.eu.org:451/announce&tr=udp://tracker.openbittorrent.com:6969/announce
```

Submit:

```bash
curl -s -X POST "https://www.seedr.cc/rest/transfer/magnet" \
  -H "Authorization: $SEEDR_AUTH" \
  --data-urlencode "magnet=$MAGNET"
```

Use `--data-urlencode` rather than `-d` — magnets contain `&` and will be truncated otherwise.

Response: `{"user_torrent_id": ..., "title": ..., "success": true}`. Keep the `user_torrent_id` for stall handling. On error (e.g. storage full), report immediately.

---

## Step 3: Wait for downloads

**`GET /rest/transfer` returns HTTP 405 Method Not Allowed.** Do not use it. Poll the folder listing instead — its `torrents` array reflects in-progress transfers:

```bash
curl -s "https://www.seedr.cc/rest/folder" -H "Authorization: $SEEDR_AUTH"
```

A transfer is done when it leaves `torrents` and its folder appears in `folders`. Poll every 30-60s. **Budget 15+ minutes** — be patient rather than declaring failure early. The torrent is sometimes already complete on first check.

### Stall handling

If a torrent sits at `progress: 100` with `seeders: 0` for 5+ minutes, delete and resubmit **once** with the extra trackers:

```bash
curl -s -X DELETE "https://www.seedr.cc/rest/torrent/{user_torrent_id}" -H "Authorization: $SEEDR_AUTH"
```

If it stalls again after the resubmit, give up on that torrent and report it as a failure with the reason.

---

## Step 4: Retrieve from Seedr

From the `GET /rest/folder` response, match `folders`/`files` entries by name.

```bash
# folder as zip
curl -L -o "/tmp/manga-dl/out.zip" "https://www.seedr.cc/rest/folder/{folder_id}/download" -H "Authorization: $SEEDR_AUTH"

# individual file
curl -L -o "/tmp/manga-dl/{name}" "https://www.seedr.cc/rest/file/{file_id}" -H "Authorization: $SEEDR_AUTH"
```

Verify the result is a real archive (`file` command, non-trivial size) — a failed auth returns an HTML error page with a 200 status.

---

## Step 5: Organize into iCloud

### Normalize to .cbz

Contents vary by release group. Handle whatever shows up:

- **`.cbz` / `.cbr` files** — use directly.
- **Folders of images** (one per chapter) — zip each into a `.cbz`: `cd "$folder" && zip -r -0 ../out.cbz .`. A `.cbz` is just a zip of images. Ensure images are at the archive root or in one subfolder and that filenames sort correctly.
- **PDFs** — `pdftoppm -jpeg -r 150` then zip. Install `poppler-utils` if needed.

Ignore extension/content mismatches inside archives (e.g. pages named `.png` that are actually JPEG). Readers sniff magic bytes, and "fixing" it makes new files inconsistent with existing ones.

### Naming convention

Detect the pattern already in use in the target folder and rename to match. Real patterns:

- `Dandadan 0242 [Ch].cbz` — minimal chapter form
- `Gachiakuta 0158 [Ch] (2025) (Digital) (Aquila).cbz` — `{Name} {4-digit} [Ch] ({year}) (Digital) ({group}).cbz`
- `Berserk v42 (2025) (Digital) (LuCaZ).cbz` — `{Name} v{2-digit} ({year}) (Digital) ({group}).cbz`
- `One Piece 1189 [Ch] .cbz` — note the space before the extension; preserve quirks exactly
- `Made in Abyss 0071.5 [Ch].cbz` — decimal chapters keep their fraction

Apply per **format**, not per folder: match new volumes to the folder's volume pattern and new chapters to its chapter pattern. If a folder has volumes but no chapters yet and you're adding the first chapters, use the user's standard chapter form — `{Name} {4-digit zero-padded} [Ch].cbz` — rather than forcing a volume name.

If the folder is empty (new series), keep the original filename; that becomes the convention.

Derive folder names cleanly: strip group tags, numbers, and quality markers. `[GroupName] One Piece Chapter 1120 (Digital)` → `One Piece`.

### Deduplication

Before moving a file in, check whether that number already exists — compare **numerically**, including decimals, not by filename string. Skip if present.

When a name collision looks like a duplicate, confirm with a content hash before deciding:

```bash
shasum "$local_file"   # compare against the hash Seedr reports
```

Identical hash → genuine duplicate, skip. Different hash → likely a fixed re-release; keep the newer one and note the swap in the report.

After moving, do a dedup pass over the folder: two files are duplicates if they refer to the same number (ignoring `(1)`, `copy`, whitespace variants). Keep the one matching the folder's convention, remove the others. Volumes and the loose chapters they cover are **not** duplicates of each other.

### Verify

`ls -la` the folder, confirm sane sizes (>1MB), and validate each new archive:

```python
import zipfile
z = zipfile.ZipFile(path)
assert z.testzip() is None and len(z.namelist()) > 0
```

---

## Step 6: Clean up Seedr

Only after iCloud verification passes:

```bash
curl -s -X DELETE "https://www.seedr.cc/rest/folder/{folder_id}" -H "Authorization: $SEEDR_AUTH"
curl -s -X DELETE "https://www.seedr.cc/rest/file/{file_id}"   -H "Authorization: $SEEDR_AUTH"
```

Use `DELETE`, not `POST` to `/delete`. Confirm the item is gone from the root listing. Then `rm -rf /tmp/manga-dl/`.

---

## Execution model

After Step 2, delegate Steps 3-6 to a sub-agent via the Agent tool (`general-purpose`) so the main conversation stays responsive during the wait.

The sub-agent prompt must be fully self-contained:

- The `SEEDR_AUTH` value verbatim
- Series name, `user_torrent_id`, info hash, expected Seedr folder name
- The iCloud destination path **in the paths that agent's shell will see**
- The polling endpoint correction (`/rest/folder`, not `/rest/transfer`)
- Stall handling with the full resubmit magnet including trackers
- Format-normalization guidance (may not arrive as `.cbz`)
- The exact target filenames, plus dedup and verification instructions
- Cleanup with `DELETE`
- An instruction to flag any judgment calls explicitly in its report

If nothing new is found in Step 1, skip straight to reporting — do not submit anything to Seedr or spawn an agent.

---

## Reporting

State plainly:

- New files added, with filenames, sizes, page counts
- Series already up to date — against both volume and chapter marks
- Failures with reasons
- Any judgment call made (skipped duplicates, format choices, ambiguous numbering)

If a previous run's conclusion turns out to have been wrong, say so directly and explain what caused it.

## Important notes

- **No confirmation needed** — run the pipeline end to end and report at the finish.
- **Grab what's available.** When new chapters exist for a volume-based series, download them. Don't withhold releases over format tidiness.
- **Stop and ask only for**: Seedr storage full, credentials missing, or repeated download failure.

