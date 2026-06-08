# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## What this project is

XSearch is a fork of [SearXNG](https://docs.searxng.org), a privacy-respecting metasearch engine built on Flask/Python. It aggregates results from 200+ search engines without tracking users. The fork is maintained by Cognitolabs AI and published as a container image at `ghcr.io/cognitolabs-ai/xsearch`.

## Development setup and common commands

All development commands route through `./manage` (a bash script) or `make`:

```bash
make install       # create virtualenv and install all dependencies
make run           # run the dev server (installs first if needed)
make uninstall     # remove virtualenv
make clean         # clean build artifacts
```

Test commands:
```bash
make test          # full suite: yamllint, black, pyright, pylint, unit, robot, rst, shell, shfmt
make ci.test       # same + pybabel check
./manage test.unit # unit tests only (nose2 runner)
./manage test.pylint
./manage test.black
./manage test.pyright_modified   # only files modified vs git
./manage test.coverage           # unit tests with coverage report
```

Run a single test file:
```bash
./manage pyenv.cmd python -m nose2 -s tests/unit tests.unit.test_search_query
```

Format code:
```bash
make format        # format Python + shell
./manage format.python   # black only
./manage format.shell    # shfmt only
```

Container build/test:
```bash
make container     # build container via podman
./manage container.test
./manage container.push
```

The `./manage` script sets up `PATH` to include the virtualenv (`local/py3/bin`), Go tools, and Node modules automatically. Run `./manage --help` to see all subcommands.

## Architecture

### Request lifecycle

1. **`searx/webapp.py`** — Flask application entry point. Handles HTTP routes (`/search`, `/`, `/preferences`, etc.), parses query parameters into a `SearchQuery`, delegates to `SearchWithPlugins`, and renders templates.

2. **`searx/search/__init__.py`** (`SearchWithPlugins`) — Orchestrates a search: runs `pre_search` plugin hooks, fans out to engine processors concurrently, collects results into a `ResultContainer`, runs `post_search` hooks.

3. **`searx/search/processors/`** — One processor per engine type:
   - `OnlineProcessor` — HTTP engines (the vast majority)
   - `OfflineProcessor` — local/CLI engines
   - `OnlineDictionaryProcessor`, `OnlineCurrencyProcessor`, `OnlineUrlSearchProcessor` — specialized subtypes
   Each processor calls the engine's `request()` and `response()` functions and handles timeouts/errors.

4. **`searx/engines/`** — 220+ engine modules. Each is a plain Python module with module-level variables (`engine_type`, `categories`, `timeout`, etc.) and two functions: `request(query, params)` → mutates `params` to build the HTTP request; `response(resp)` → parses the HTTP response and returns `EngineResults`.

5. **`searx/results.py`** (`ResultContainer`) — Deduplicates, scores, and merges results from all engines. Scoring weights by engine weight × position.

6. **`searx/result_types/`** — Typed result classes: `MainResult`, `Answer`, `KeyValue`, `Code`, `Paper`, `File`, `WeatherAnswer`. Engines return `EngineResults` (a `ResultList`).

### Extension points

- **Plugins** (`searx/plugins/`) — Implement `Plugin` with hooks `pre_search`, `post_search`, `on_result`. Registered via `searx/plugins/__init__.py`. Examples: `calculator.py`, `tracker_url_remover.py`, `unit_converter.py`.

- **Answerers** (`searx/answerers/`) — Implement `Answerer` with `keywords` list and `answer(request, search)` method. Triggered when the query matches a keyword before engine dispatch.

- **Engine caching** (`searx/enginelib/`) — `EngineCache` (SQLite-backed via `searx/cache.py`) for engines that want to cache results.

### Configuration

- **`searx/settings.yml`** — Default configuration (bundled). Contains all engine definitions, server config, search defaults.
- Settings load order: `DEFAULT_SETTINGS_FILE` → user config at `SEARXNG_SETTINGS_PATH` (or `/etc/searxng/settings.yml`). User config can use `use_default_settings: true` to inherit and override.
- In tests, `SEARXNG_SETTINGS_PATH` is pointed at `tests/unit/settings/test_settings.yml`.

### Networking

`searx/network/` wraps `httpx` with per-engine network configuration (proxies, TLS, timeouts). Engines call `httpx` indirectly through the processor layer; the `initialize()` call in `searx/search/__init__.py` sets up per-engine `httpx` client pools.

### Bot detection / rate limiting

`searx/botdetection/` uses Valkey (Redis-compatible) for IP-based rate limiting. `searx/limiter.py` integrates it as a Flask before-request hook. Valkey is optional — the limiter degrades gracefully when unavailable.

### Frontend

`client/simple/` — The "simple" theme. Built with Node/npm (`make themes`). Static assets are served via WhiteNoise. Templates live in `searx/templates/simple/`.

## Code conventions

- Python target: 3.11+. Line length: 120 chars (black). String quotes: no normalization (black `--skip-string-normalization`).
- Type annotations are expected; `basedpyright` is the type checker (`./manage test.pyright_modified` for changed files only).
- SPDX license header required on all source files: `# SPDX-License-Identifier: AGPL-3.0-or-later`.
- Engine modules use module-level globals for configuration (not classes) — this is intentional SearXNG convention.

## Deployment

Production deployment uses Docker Compose with the pre-built image:

```bash
./deploy.sh          # automated setup
# or manually:
cp .env.example .env
# set XSEARCH_BASE_URL and XSEARCH_SECRET in .env
docker compose up -d
```

Optional Valkey cache: `docker compose --profile with-cache up -d`.

The container entrypoint is `container/entrypoint.sh`. Runtime configuration is volume-mounted at `/etc/xsearch` (maps to `./xsearch-config` in Compose). The WSGI server is Granian (not Gunicorn).
