# Phase 0 — Bootstrap / Project Definition

Repository: `jooya98/tg-bot`  
Project name: **tgBot**  
Status: **Phase 0 complete**

## Objective

Phase 0 establishes tgBot as the base repository for an adaptive Telegram crawler/downloader.

The intended product is not a static media-hosting service. It should acquire media in response to user demand and use Telegram's own stored media references (`file_id`) to avoid repeatedly paying the infrastructure cost of downloading, processing and persistently hosting the same object.

    demand → discover → acquire → deliver → Telegram cache → reuse

The infrastructure should spend resources primarily when new demand requires acquisition.

## What was changed

### Repository identity

- Forked `antlis/tg-media-bot` into `jooya98/tg-bot`.
- Reframed the repository as **tgBot**.
- The default Compose workflow builds the tgBot image from this checkout instead of consuming the upstream prebuilt image.

### Project definition

The README now documents the product thesis, Telegram cache role, canonical-media distinction, target architecture, explicit Phase 0 boundaries, and the related projects investigated.

### Architecture direction

    Interface
      ↓
    Intent / Search
      ↓
    Resolver
      ↓
    Acquisition Orchestrator
      ↓
    Acquisition Providers
      ↓
    Canonical Media / Representations
      ↓
    Delivery Backend
      ↓
    Telegram file_id cache

The existing URL → yt-dlp → Telegram path remains intact as the initial runtime.

## Reference projects and decisions

### tanscope

Useful patterns: multiple acquisition engines behind one interface, search-result caching, Telegram file_id reuse, SQLite/Redis operational state, statistics, concurrency control, and discovery separated from acquisition.

**Decision:** borrow architectural ideas later; do not transplant the application wholesale.

### telegram-movie-search-bot

Useful pattern: index media already present in Telegram, attach searchable metadata, and return existing Telegram media rather than acquiring it again.

**Decision:** treat this as a reference for a future Telegram-native catalog/index adapter. Its legacy database/deployment model is not the core of tgBot.

### ytdl_tg_bot

Useful patterns: durable download jobs, downloader-worker separation, cached Telegram resends, downloader-client boundary, and multiple downloader nodes.

**Decision:** reserve these for a later scaling phase. Do not introduce its Kubernetes/operator/database stack during Phase 0.

## Current cache limitation

The inherited MediaCache currently maps approximately:

    source URL + requested format → Telegram file_id

That is useful but is not yet a canonical media catalog.

Future work should move toward:

    MediaObject
      └── Representation
            └── TelegramFile
                  └── file_id

This allows different source URLs to resolve to the same media object and allows several representations to coexist.

No such domain model is implemented in Phase 0. The limitation is documented rather than prematurely abstracted.

## Why no crawler/search implementation was added

A crawler/search system is the actual product differentiator and should be designed after the existing acquisition runtime is understood in operation.

Phase 0 therefore avoids speculative provider interfaces, premature database migration, distributed workers, search indexing, source-specific scraping, and recommendation logic.

The existing plugin mechanism is retained as an early extension point, but it is not declared the final crawler architecture.

## Explicit non-goals

Phase 0 does not attempt to:

- build a movie/series search engine;
- build a general web search engine;
- create a media CDN;
- mirror third-party media permanently;
- add a crawler fleet;
- add Kubernetes;
- replace the existing queue;
- replace the JSON file_id cache;
- add monetization;
- make production capacity claims.

## Definition of done

- [x] repository is the tgBot fork;
- [x] README defines the new project;
- [x] economic role of Telegram caching is explicit;
- [x] acquisition/delivery boundary is explicit;
- [x] reference-project decisions are documented;
- [x] upstream runtime remains usable;
- [x] default Compose workflow builds the local repository;
- [x] future work is clearly separated from current implementation.

## Next phase

The next phase should begin with an **implementation audit**, not immediate feature development.

The audit should answer:

1. Which existing modules are stable and should remain untouched?
2. Where exactly should the application/domain boundary be extracted?
3. What should canonical media identity be?
4. Which search/resolution sources provide useful demand coverage?
5. Which acquisition methods should be first-class providers?
6. When is SQLite sufficient and when is PostgreSQL justified?
7. When does the in-process queue need to become durable?
8. When is a remote downloader pool actually justified?

Only after that audit should the first real product-development phase be opened.

**Phase 0 principle:** preserve proven machinery, document the target architecture, and postpone irreversible complexity until actual demand tells us where it is needed.