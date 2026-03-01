---
name: manga-downloader
description: >
  Automates downloading manga chapters from nyaa.si via Seedr.cc and organizing them into iCloud Drive.
  Use this skill whenever the user asks to download a manga, fetch new manga chapters, grab manga torrents,
  or mentions nyaa.si or Seedr in the context of manga. Also trigger when the user says things like
  "get the latest chapters of [manga name]", "download [manga name]", or "check for new [manga name] releases".
---

# Manga Downloader

This skill automates the full pipeline of finding new manga chapters on nyaa.si, downloading them through Seedr.cc, and organizing them into the user's iCloud Drive manga library.

The whole workflow should run autonomously without asking for confirmation. Just do it — search, download, extract, organize, clean up. Only stop to tell the user if something actually goes wrong.

## Prerequisites

The Seedr.cc API credentials must be available as the `SEEDR_AUTH` environment variable. This should already be set in the user's fish config (`~/dotfiles/fish/config.fish`). The value is a Basic auth header string. If it's missing, ask the user to set it up:

```fish
set -gx SEEDR_AUTH "Basic <base64_encoded_email:password>"
```

## Overview

The workflow has six stages:

1. **Search** — Find recent manga torrents on nyaa.si
2. **Send to Seedr** — Submit magnet links to Seedr.cc for cloud downloading
3. **Wait & Monitor** — Poll Seedr until downloads complete
4. **Retrieve** — Download the files from Seedr to local storage
5. **Organize** — Extract zips, find the `.cbz`/`.cbr` files or folders inside, move them to iCloud Drive
6. **Clean up** — Delete files from Seedr to free up space

## Step 1: Search nyaa.si

Extract the manga name from the user's prompt. Use it to search nyaa.si's RSS feed, which returns XML and is easier to parse than HTML.

```
URL: https://nyaa.si/?page=rss&f=0&c=3_1&q={manga_name_url_encoded}
```

Category `3_1` = Literature > English-translated. The `f=0` flag means no filter (show all).

Use `curl` to fetch the RSS feed and parse the XML. Each `<item>` contains:
- `<title>` — the torrent name
- `<link>` — link to the torrent page
- `<pubDate>` — publication date (RFC 2822 format, e.g. `Mon, 24 Mar 2026 14:30:00 +0000`)
- `<nyaa:infoHash>` — the info hash
- `<nyaa:seeders>`, `<nyaa:leechers>`, `<nyaa:downloads>` — stats

To get the magnet link, construct it from the info hash:
```
magnet:?xt=urn:btih:{infoHash}
```

**Time window**: Default to the last 7 days. If the user specifies a different timeframe (e.g., "from the last month", "last 3 days"), use that instead. Filter items by comparing `<pubDate>` against the current date. If nothing is found within the window, tell the user — don't silently widen it.

### If curl is blocked

If nyaa.si is unreachable via curl (network restrictions), fall back to Claude in Chrome:
1. Navigate to `https://nyaa.si/?f=0&c=3_1&q={manga_name_url_encoded}`
2. Read the page to extract torrent titles, dates, and magnet links from the results table
3. Each row has a magnet link icon — grab the `href` attribute

## Step 2: Send magnet links to Seedr.cc

For each magnet link found, POST it to Seedr immediately — no need to ask:

```bash
curl -s -X POST "https://www.seedr.cc/rest/torrent" \
  -H "Authorization: $SEEDR_AUTH" \
  --data-urlencode "torrent_magnet=magnet:?xt=urn:btih:{infoHash}"
```

The response includes a `user_torrent_id` and `title`. A successful response looks like:
```json
{"user_torrent_id":12345,"title":"Manga Name","success":true,"torrent_hash":"..."}
```

If the torrent was already added, you'll get `{"reason_phrase":"torrent_already_added"}`. If the API returns an error (e.g., storage full), report it to the user immediately.

## Step 3: Wait for downloads to complete

**The `/rest/transfer` endpoint is broken** (returns 405/404). Monitor progress via the root folder listing, which includes a `torrents` array of in-progress downloads:

```bash
curl -s "https://www.seedr.cc/rest/folder" -H "Authorization: $SEEDR_AUTH"
```

Each torrent in the `torrents` array has `id`, `name`, `size`, `progress` (0.0-1.0), `download_rate`, and `stopped`. When a torrent is no longer in the `torrents` array, it's complete and has moved to the `folders` list.

Use a bash loop with `until` to wait for completion — poll every 30-60 seconds. Large bundles (tens of volumes) can take an hour or more; do not give up early.

```bash
until curl -s "https://www.seedr.cc/rest/folder" -H "Authorization: $SEEDR_AUTH" \
  | python3 -c "import json,sys; d=json.load(sys.stdin); ts=[t for t in d.get('torrents',[]) if t['id']==TORRENT_ID]; sys.exit(0 if not ts else 1)"; do
  sleep 60
done
```

## Step 4: Retrieve files from Seedr

Once downloads are complete, list the root folder to find the new files:

```bash
curl -s "https://www.seedr.cc/rest/folder" \
  -H "Authorization: $SEEDR_AUTH"
```

The response contains `folders` and `files` arrays. Each item has an `id` and `name`. Match the names against the manga you just downloaded.

**The folder zip download endpoint is broken** (`GET /rest/folder/{id}/download` returns `400 archive_arr parameter missing`). Always download files individually:

```bash
curl -L -o "{local_path}" "https://www.seedr.cc/rest/file/{file_id}" \
  -H "Authorization: $SEEDR_AUTH"
```

This returns a 302 redirect to a signed URL — the `-L` flag is required.

To list a folder's contents (to find nested files and sub-folders):
```bash
curl -s "https://www.seedr.cc/rest/folder/{folder_id}" \
  -H "Authorization: $SEEDR_AUTH"
```

If the torrent contained nested folders (e.g. one folder per volume), recurse into each to find the `.cbz` files, then loop through and download each via its file ID.

Save downloads to a temporary working directory (e.g., `/tmp/manga-dl/`).

## Step 5: Organize into iCloud Drive

The manga library lives at:
```
~/Library/Mobile Documents/com~apple~CloudDocs/Books/Manga/{manga-name}/
```

Each manga series gets its own subfolder. The files from Seedr come down as `.zip` archives. Here's what to do:

1. Create the manga folder if it doesn't exist: `mkdir -p "{icloud_path}/{manga_name}"`
2. Extract each `.zip` file: `unzip -o "{file}" -d "/tmp/manga-dl/extracted/"`
3. Inside the extracted content, look for `.cbz` and/or `.cbr` files, or folders containing manga content. These are the actual manga volumes/chapters.
4. Move those `.cbz`/`.cbr` files (or content folders) directly into the manga's iCloud folder.
5. Clean up the temp directory: `rm -rf /tmp/manga-dl/`

Use the manga name from the torrent title to derive a clean folder name — strip out chapter numbers, group tags (e.g., `[GroupName]`), and file extensions. For example, if the torrent is `[GroupName] One Piece Chapter 1120 (Digital)`, the folder should be `One Piece`.

If a folder for this manga already exists in iCloud, use it.

### File Naming Convention

**This is critical.** Before moving any files into a manga's iCloud folder, check the existing files in that folder to detect the naming convention already in use. Downloaded files must be renamed to match.

Each manga folder has its own established naming pattern from its original source. Examples of real patterns found across different manga:

- `Dandadan 0148 [Ch] (2024) (Digital) (1r0n).cbz` — `{Name} {4-digit-number} [Ch/Vol] ({year}) (Digital) ({group}).cbz`
- `Berserk v01 (2003) (Digital) (Cyborgzx-repack).cbz` — `{Name} v{2-digit-number} ({year}) (Digital) ({group}).cbz`

**How to apply:**

1. List the existing `.cbz`/`.cbr` files in the target manga folder.
2. Analyze the naming pattern: identify the manga name prefix, the numbering format (e.g., `0001`, `v01`), whether it uses `[Vol]`/`[Ch]` tags, the year/quality/group suffixes, etc.
3. Rename each downloaded file to match this pattern before moving it in. Extract the chapter/volume number from the downloaded filename and reformat it to match the convention (e.g., zero-padded 4-digit vs `v`-prefixed 2-digit).
4. If the folder is empty (new manga), keep the original filename as-is — that becomes the convention going forward.

### Deduplication

This is important — never leave duplicate files in the manga folder. Before moving any `.cbz`/`.cbr` file into iCloud, check if a file with the same chapter/volume number already exists there (compare by number, not by exact filename). If it does, skip it.

After all new files are moved in, do a dedup pass on the entire manga folder: list all files and look for duplicates. Two files are duplicates if they refer to the same chapter/volume number (ignoring differences in naming, trailing `(1)`, `copy`, or whitespace variations). If duplicates are found, keep the one whose name matches the folder's established convention and remove the others.

This matters because re-running the skill for the same manga or overlapping time windows could otherwise pile up identical chapters.

## Step 6: Clean up Seedr

After the files are in iCloud, delete each Seedr folder via the API:

```bash
curl -s -X DELETE "https://www.seedr.cc/rest/folder/{folder_id}" \
  -H "Authorization: $SEEDR_AUTH"
```

A `{"success":true}` response with HTTP 200 means it worked. Even single-file torrents (like a lone `.cbz`) appear as folder entries in the root listing — so use the folder DELETE endpoint for everything in `folders[]`. For loose entries in `files[]`, use `DELETE /rest/file/{file_id}` instead.

Verify the files made it to iCloud (list the directory and confirm) before deleting from Seedr. After deletion, re-list `/rest/folder` and confirm the IDs are gone — if any remain despite a `success:true` response, fall back to asking the user to delete them manually at seedr.cc.

## Execution Model: Use Background Agents

**IMPORTANT**: After completing Step 2 (sending magnets to Seedr), delegate Steps 3-6 (waiting, retrieving, organizing, cleanup) to a background agent using the Agent tool with `run_in_background: true`. This prevents blocking the main conversation while waiting for Seedr downloads to complete.

The background agent should receive a self-contained prompt that includes:
- The manga name and expected folder names to look for on Seedr
- The iCloud destination path
- The Seedr API patterns (polling, downloading, deleting)
- Instructions to poll every 30-60 seconds until downloads appear and stabilize
- Instructions to report results when done (files added, errors encountered)
- Instructions to delete each Seedr folder via `DELETE /rest/folder/{id}` after files are confirmed in iCloud, then re-list to verify

The main conversation stays responsive and reports to the user once the background agent completes.

## Important Notes

- **No confirmation needed**: Run the entire pipeline automatically. The user trusts the workflow — just do it and report what happened at the end.
- **Error handling**: If Seedr is full, if nyaa.si returns no results, or if a download fails — tell the user clearly and suggest next steps. These are the only cases where you should stop and ask.
- **Naming**: Keep manga folder names clean and human-readable. Strip group tags, chapter numbers, quality tags, etc.
- **Duplicate detection**: Before downloading, check if the chapter files already exist in the iCloud manga folder to avoid re-downloading.
- **Ended series**: Folders with `[ended]` in their name are completed series — skip them when searching for new chapters. When a series is confirmed as finished, rename its folder to append `[ended]` (e.g., `Fire Punch` → `Fire Punch [ended]`).
