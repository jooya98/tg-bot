# tgBot

[![CI](https://github.com/jooya98/tg-bot/actions/workflows/ci.yml/badge.svg)](https://github.com/jooya98/tg-bot/actions/workflows/ci.yml)
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](LICENSE)

> **Project status: Phase 0 — Bootstrap / Project Definition**
>
> This repository is intentionally not being developed as a finished product yet. Phase 0 establishes the project direction, preserves a proven downloader/Telegram runtime, and records the architecture we intend to build on top of it. See [docs/PHASE_0.md](docs/PHASE_0.md).

## What tgBot is

tgBot is the foundation for an adaptive Telegram crawler/downloader.

The long-term goal is not simply to make a bot that downloads a URL. The goal is to build a system that can **discover, resolve, acquire and deliver media according to what users actually ask for**, while using Telegram itself as a highly economical delivery and cache layer.

The core economic idea:

    User request
        ↓
    Search / Intent
        ↓
    Resolver
        ↓
    Crawler / Acquisition
        ↓
    Media Object
        ↓
    Telegram
        ↓
    file_id
        ↓
    Reusable Telegram-side cache

Once a media object has been uploaded to Telegram, subsequent deliveries can reuse its Telegram file_id instead of downloading and uploading the same object again. Our infrastructure therefore spends resources primarily on discovery, acquisition, processing and orchestration rather than permanently storing a growing media library.

Telegram file_id is a delivery/cache reference, not canonical content identity. A future catalog must own the identity of the media object so the same content can be recognized across URLs, sources and representations.

## Why this repository is the base

This repository was forked from [antlis/tg-media-bot](https://github.com/antlis/tg-media-bot), which already provides a useful operational runtime:

- Telegram bot integration with aiogram
- Local Telegram Bot API support for large uploads
- yt-dlp based acquisition
- optional headless-browser fallback
- ffmpeg processing
- asynchronous download queue and concurrency limits
- progress reporting and cancellation
- Telegram file_id reuse
- flood-control retry handling
- temporary-file cleanup
- cookies/authenticated downloads
- Docker and Nix packaging
- tests

These are expensive integration details to rebuild and are therefore retained as the runtime foundation.

The product layer we intend to add is different: **search, resolution, crawling strategy, canonical media identity, source selection, adaptive acquisition and reusable delivery.**

## Phase 0 boundary

Phase 0 is deliberately small.

### Done in Phase 0

1. Fork the upstream project into this repository as tgBot.
2. Replace the upstream project definition with our own project definition.
3. Document the economic and architectural role of Telegram file_id caching.
4. Record the intended separation between user intent/search, source resolution, acquisition/crawling, canonical media identity, representation/format, and Telegram delivery/cache.
5. Audit related open-source projects for ideas worth borrowing later:
   - [tanscope](https://github.com/tantaneity/tanscope)
   - [telegram-movie-search-bot](https://github.com/ScripterSaurav/telegram-movie-search-bot)
   - [ytdl_tg_bot](https://github.com/Desiders/ytdl_tg_bot)
6. Keep useful architectural ideas without importing unrelated deployment complexity.
7. Make the fork self-identifying as tgBot rather than depending on the upstream prebuilt image.

### Explicitly not done in Phase 0

- no universal media search engine
- no movie/series catalog
- no crawler fleet
- no new source-scraping system
- no durable distributed queue
- no PostgreSQL migration
- no remote downloader cluster
- no recommendation/ranking engine
- no monetization layer
- no production-scale deployment work

Phase 0 is a **prepared foundation**, not the first product-development sprint.

## Architectural direction

Current runtime:

    Telegram message
        ↓
    URL extraction
        ↓
    download queue
        ↓
    yt-dlp
        ↓
    Telegram upload
        ↓
    file_id cache

Target direction:

    Telegram / future interfaces
            ↓
      User Intent / Search
            ↓
          Resolver
            ↓
    Acquisition Orchestrator
        ↙       ↓       ↘
    direct HTTP  yt-dlp  source-specific adapters
            ↓
       Canonical Media
            ↓
      Representation
            ↓
     Telegram Delivery
            ↓
      Telegram file_id
            ↓
       Delivery Cache

The important boundary is that **Telegram is a delivery/cache backend, not the canonical media database**.

Future conceptual model:

    MediaObject
      ├── identity
      ├── metadata
      ├── source(s)
      └── representations
            ├── video 1080p
            ├── video 720p
            ├── audio mp3
            └── ...

    Representation
      └── TelegramFile
            ├── file_id
            ├── media kind
            └── Telegram-specific metadata

## Reference projects

### tanscope

Useful patterns include multiple acquisition engines behind one interface, search-result caching, Telegram file_id reuse, operational statistics, concurrency control, and discovery separated from acquisition.

**Decision:** borrow the architectural ideas later; do not transplant the application wholesale.

### telegram-movie-search-bot

The useful pattern is a Telegram-native media index: index media already present in Telegram, store searchable metadata, and return existing Telegram files instead of acquiring them again.

**Decision:** this is a reference for a future Telegram-native catalog/index adapter. Its older database and deployment model are not adopted as tgBot's core architecture.

### ytdl_tg_bot

Useful patterns include durable download jobs, downloader-worker separation, cached Telegram resends, a downloader-client boundary, and multiple downloader nodes.

**Decision:** reserve these for a later scaling phase. Do not introduce its Kubernetes/operator/database stack during Phase 0.

## Phase 0 principle

**Preserve proven machinery, document the target architecture, and postpone irreversible complexity until actual demand tells us where it is needed.**

## Runtime documentation inherited from the base

The operational documentation below remains relevant to the existing downloader runtime. Search/resolution and the new catalog are future product work.

---

## Configuration

All settings are loaded from `.env` (see `src/config/settings.py`).

| Variable | Required | Default | Purpose |
|----------|----------|---------|---------|
| `BOT_TOKEN` | yes | — | Telegram bot token from @BotFather |
| `TELEGRAM_API_ID` | Docker only | — | From my.telegram.org/apps; used by the local Bot API server |
| `TELEGRAM_API_HASH` | Docker only | — | From my.telegram.org/apps; used by the local Bot API server |
| `ALLOWED_USERS` | recommended | empty (open) | Comma-separated Telegram user IDs allowed to use the bot |
| `API_SERVER_URL` | no | empty | Local Bot API base URL; set automatically in Docker |
| `TEMP_DIR` | no | `/tmp/tg-media-bot` | Working directory for downloads |
| `MAX_PARALLEL_DOWNLOADS` | no | `3` | Global concurrent download limit |
| `RATE_LIMIT_PER_USER` | no | `2` | Concurrent downloads per user |
| `DOWNLOAD_TIMEOUT` | no | `3600` | Per-download timeout in seconds |
| `LOG_LEVEL` | no | `INFO` | `DEBUG`/`INFO`/`WARNING`/`ERROR` |
| `LOG_FILE` | no | empty (`/data/...` in Docker) | Persist logs to a rotating file for a durable download record |
| `USE_BROWSER_COOKIES` | no | `true` | Use browser cookies (forced off in Docker) |
| `BROWSER_NAME` | no | `firefox` | Browser to read cookies from |
| `COOKIES_FILE` | no | empty | Path to a Netscape `cookies.txt` for authenticated downloads; takes precedence over browser cookies when present (the Docker way to auth) |
| `ALLOWED_CHATS_FILE` | no | empty | Path to a JSON file persisting group chats an allowed user has activated the bot in |
| `TOPIC_LOCK_FILE` | no | empty | Path to a JSON file persisting per-chat forum-topic locks set via `/topic lock` |
| `MEDIA_CACHE_FILE` | no | empty | Path to a JSON file caching `file_id`s so repeat URLs are resent instantly |
| `PROXY_URL` | no | empty | Proxy used **only** as a fallback retry when a download fails with a geo/region block (`socks5h://…` or `http://…`) |
| `ENABLE_BROWSER_FALLBACK` | no | `true` | Try the headless-browser fallback when no yt-dlp extractor can handle a page (needs Chromium in the image — see `INSTALL_BROWSER`) |
| `BROWSER_FALLBACK_TIMEOUT` | no | `45` | Seconds the fallback waits for the page to load and start playing |
| `BOT_API_HOST_PORT` | no | `8082` | Docker only: host port for the local Bot API server |
| `YTDLP_AUTO_UPDATE` | no | `true` | Docker only: refresh yt-dlp to the latest release on container start |

The headless-browser fallback needs a Chromium binary in the image, which is **opt-in** (it adds ~450 MB). Build with it by setting `INSTALL_BROWSER=true` in `.env` before `docker compose build` (the compose file forwards it as the `INSTALL_BROWSER` build arg), or `docker build --build-arg INSTALL_BROWSER=true`. On the bare-Python/AUR install, run `playwright install chromium` once. Without Chromium the fallback simply no-ops and the bot reports the original failure.

## Access Control

The bot is gated by `ALLOWED_USERS`. An `outer_middleware` on every message (`src/bot/router.py`) checks `from_user.id` against the allowlist **before any handler runs**:

- **Empty / unset** → open to everyone.
- **Set** → only listed IDs are served; others get a denial reply and are logged.

`ALLOWED_USERS` is read at startup. To add a user, append their ID and restart:

```bash
docker compose up -d bot   # no rebuild needed — .env is read on start
```

To find a user's numeric ID, have them message [@userinfobot](https://t.me/userinfobot).

### Use in groups

The bot also works in group chats. When an allowed user uses it inside a group, that group is **activated** — its other members can then use the bot there too, without being individually allowlisted. Set `ALLOWED_CHATS_FILE` to persist activated groups across restarts (in Docker this defaults to `/data/allowed_chats.json` on the `bot-logs` volume); leave it unset to keep them in memory only.

**Required one-time setup:** Telegram bots ship with "group privacy" enabled, which stops the Bot API from forwarding plain messages (like a pasted link) sent in a group — only commands, @mentions, and replies to the bot get through. To let people just paste a link, disable it: message [@BotFather](https://t.me/BotFather) → `/mybots` → your bot → **Bot Settings** → **Group Privacy** → **Turn off**, then remove and re-add the bot to any group it's already in (the change doesn't apply retroactively to existing memberships).

**Forum topics:** in a group with topics enabled, every reply (status messages, the downloaded file) is posted into whichever topic the request came from — never "General" — so different topics can be used for different purposes without their results bleeding into each other. To confine the bot to one topic per group (e.g. a "bots" topic, ignoring everything posted elsewhere), send `/topic lock` **from inside that topic**. `/topic unlock` lifts the restriction, and `/topic status` shows the current lock. This is per-chat, so different groups can each lock to their own topic (or not lock at all). `/topic` itself always works regardless of the current lock, so a chat can't get stuck; set `TOPIC_LOCK_FILE` to persist locks across restarts.

### Authenticated downloads (cookies)

Some sources (Instagram, age-restricted videos, etc.) need a logged-in session. Two options:

- **Bare Python:** set `USE_BROWSER_COOKIES=true` and `BROWSER_NAME` to pull cookies from your local browser.
- **Docker:** export a Netscape `cookies.txt`, drop it in `./cookies/`, and it's used per-download (`COOKIES_FILE=/cookies/cookies.txt`, mounted by `docker-compose.yml`). A present `cookies.txt` takes precedence over browser cookies.

## Logs & Download History

By default the bot logs to stdout (`docker compose logs bot`), which resets when the container is recreated. Set `LOG_FILE` to also persist logs to a rotating file. In Docker this is wired by default to `/data/tg-media-bot.log` on the named `bot-logs` volume, so the record of every download (timestamp, user ID, URL, platform, filename, size) **survives restarts and rebuilds**.

```bash
# Tail the persistent log
docker compose exec bot tail -f /data/tg-media-bot.log

# Just the completed downloads
docker compose exec bot grep "Download completed" /data/tg-media-bot.log
```

Rotation keeps ~110 MB of history (10 × 10 MB files). For a privacy-minded setup, set `LOG_LEVEL=WARNING` to stop recording URLs/user IDs.

## Bot Commands

Send the bot any media **URL** (or up to 3 URLs in one message) and it downloads and returns the file. The active format mode (video/audio) applies to each download.

| Command | Description |
|---------|-------------|
| `/start` | Welcome message |
| `/help` | Show help and the list of supported platforms |
| `/audio` | Switch to audio-only mode — downloads are converted to MP3 |
| `/video` | Switch to video mode (default) — includes video when available |
| `/formats <url>` | Show inline buttons to pick a download quality (Best / 1080p / 720p / 480p / Audio) |
| `/status` | Show your queued/active downloads and their task IDs |
| `/cancel <task_id>` | Cancel one of your active downloads (get the ID from `/status`) |
| `/minimal on\|off` | Toggle minimal UI for this chat — no status/progress messages, no caption on media |
| `/topic lock\|unlock\|status` | Restrict the bot to one forum topic in this group (see [Use in groups](#use-in-groups)) |

Notes:
- `/audio` and `/video` set a **per-user** preference that persists until changed.
- A download is queued per URL; `/status` reports each one's task ID, which `/cancel` consumes.
- Per-user concurrency is bounded by `RATE_LIMIT_PER_USER`; the global cap is `MAX_PARALLEL_DOWNLOADS`.
- **Audio posts** are a single message: the MP3 with embedded cover art, an album-art thumbnail in the player, title/artist/duration tags, and the source URL in the caption. (Telegram doesn't allow a standalone photo and an audio file in one post, so the cover rides along as the player thumbnail.)
- **SoundCloud links are always audio** — no need to send `/audio` first.
- **Every post** includes the original source URL as monospace, non-linked text — copyable, but Telegram won't turn it into a link or fetch a preview.

See [Command Reference](COMMANDS.md) for full examples and sample responses.

## Testing

The test suite uses `pytest` (with `pytest-asyncio`) and covers the pure-logic units — config parsing, sanitization, URL extraction, platform detection, yt-dlp command building, the caption builder, the allowlist middleware, the queue, and ffmpeg thumbnail resizing. No network or Telegram access is required; downloads and `get_info` are mocked.

```bash
# In a virtualenv with dev deps
pip install -r requirements-dev.txt
pytest

# Or, without managing a venv (uses uv)
uv run --with pytest --with pytest-asyncio --with aiogram --with structlog \
       --with python-dotenv --with aiohttp pytest
```

The thumbnail tests need `ffmpeg` on PATH; they're skipped automatically if it's missing. yt-dlp is not required — the version probe is patched out in tests.

## Documentation

- [Architecture Overview](ARCHITECTURE.md)
- [Installation Guide](INSTALLATION.md)
- [Command Reference](COMMANDS.md)
- [Troubleshooting](TROUBLESHOOTING.md)
- [Contributor guide for AI agents](CLAUDE.md)

Downloads that use HLS/DASH fragments are fetched in parallel
(`CONCURRENT_FRAGMENTS`, default 16). This is faster and lets a download finish
before sites that expire segment URLs shortly after issuing them invalidate
them; if a high-resolution file still can't complete in that window, the bot
automatically retries at progressively lower quality.

## Custom extractor plugins

Some sites build their media URL in JavaScript or hide it behind a site-specific
API, so neither yt-dlp nor the headless-browser fallback can reach it. You can
teach the bot about such a site with a **plugin**: a small Python file that turns
a page URL into a media URL yt-dlp can download.

Drop `.py` files into a plugin directory — the `./plugins` folder mounted into the
container by default (`PLUGIN_DIR=/plugins`), or any directory named by the
`PLUGIN_DIR` env var on a bare-metal install. Each plugin exposes two callables:

```python
def match(url: str) -> bool: ...     # claim the URLs you handle
async def resolve(url: str): ...     # -> media_url | (media_url, referer) | ResolveResult | None
```

For a URL a plugin claims, its resolver runs **before** yt-dlp; the returned URL
then goes through the normal download / recode / upload path. A plugin that
returns `None` or raises is skipped, falling through to yt-dlp and the
headless-browser fallback. See [`examples/plugin_example.py`](examples/plugin_example.py)
for a complete template.

A resolver may also assemble a playlist itself and return a local `file://`
URL (e.g. after rewriting a site's rotating segment hosts) — the bot enables
yt-dlp to read it automatically.

Plugins are **not committed** — the `plugins/` directory is gitignored, so
site-specific extractors stay private to your deployment. Set `ENABLE_PLUGINS=false`
to ignore the directory entirely.
