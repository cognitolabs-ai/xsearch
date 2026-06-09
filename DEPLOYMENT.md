# XSearch — Deployment & Administration

## Infrastructure

| Component | Location |
|-----------|----------|
| Git repository | https://gitlab.xdata.si/xdata/xsearch |
| Container registry | `registry.xdata.si/xdata/xsearch:latest` |
| Stack manager (Dockhand) | http://144.91.101.143:3000 |
| Live URL | https://search.xdata.si |

## CI/CD Pipeline

Every push to `master` on GitLab triggers a full build and deploy automatically:

| Stage | Trigger | Action |
|-------|---------|--------|
| `sync-upstream` | Daily schedule (04:00 UTC) | Merges `searxng/searxng:master` into `master` — our changes win all conflicts (`-X ours`) |
| `build-image` | Push to `master` | Builds Docker image, pushes to `registry.xdata.si` |
| `deploy` | After `build-image` | Triggers Dockhand webhook → pulls new image → restarts container |

## Files on the server

Dockhand clones the repo at:
```
/app/data/stacks/Production/xsearch/
```

Docker named volumes (persistent across container restarts and image updates):
```
/var/lib/docker/volumes/xsearch_xsearch-config/_data/
    ├── limiter.toml    ← copied from image on first start
    └── settings.yml   ← created by entrypoint on first start

/var/lib/docker/volumes/xsearch_xsearch-data/_data/
    └── (favicons cache, runtime data)
```

## Updating settings.yml

`searx/settings.yml` in this repo is a **default template** — it is written to the named volume on first container start and never overwritten automatically. This lets you customize it on the server without losing changes on redeploy.

**Edit directly on the server (SSH):**
```bash
nano /var/lib/docker/volumes/xsearch_xsearch-config/_data/settings.yml
docker restart xsearch
```

**Apply a template update from the repo:**
After CI/CD redeploys with an updated `searx/settings.yml`, the new version appears as `settings.yml.new` in the volume. Review the diff and apply manually:
```bash
cd /var/lib/docker/volumes/xsearch_xsearch-config/_data/
diff settings.yml settings.yml.new   # review changes
cp settings.yml.new settings.yml
docker restart xsearch
```

## Changing the public URL

Edit `docker-compose.yml` and push to `master` — CI/CD handles the rest:
```yaml
environment:
  - XSEARCH_BASE_URL=https://search.xdata.si
```

This affects how XSearch generates absolute links (image proxy, opensearch, etc.).

## Manual redeploy (without a code push)

Pulls the latest image and recreates the container without touching volumes:
```bash
curl -X POST "http://144.91.101.143:3000/api/git/stacks/1/webhook" \
     -H "X-Gitlab-Token: <DOCKHAND_WEBHOOK_SECRET>"
```

The secret is in GitLab → Settings → CI/CD → Variables as `DOCKHAND_WEBHOOK_SECRET`.

## Required CI/CD variables

Set in GitLab → Settings → CI/CD → Variables:

| Variable | Purpose |
|----------|---------|
| `GITLAB_PUSH_TOKEN` | PAT with `write_repository` scope — used by the sync job to push merged upstream commits back to `master` |
| `DOCKHAND_WEBHOOK_URL` | Full webhook URL for the xsearch stack in Dockhand |
| `DOCKHAND_WEBHOOK_SECRET` | Webhook secret token |

## Container environment variables

All set in `docker-compose.yml`. Changes require a push to `master` to take effect.

| Variable | Value | Description |
|----------|-------|-------------|
| `XSEARCH_BASE_URL` | `http://localhost:8080` | **Change to production URL** (`https://search.xdata.si`) |
| `SEARXNG_SECRET` | (hardcoded) | Flask session secret key |
| `XSEARCH_IMAGE_PROXY` | `true` | Proxy images through XSearch for privacy |
| `XSEARCH_LIMITER` | `false` | Rate limiting (requires Valkey) |
| `XSEARCH_PUBLIC_INSTANCE` | `false` | Public instance mode |
| `GRANIAN_WORKERS` | `4` | WSGI worker processes |
| `GRANIAN_THREADS` | `4` | Threads per worker |

## Viewing container logs

```bash
# On server (SSH):
docker logs xsearch
docker logs --tail 100 -f xsearch   # follow last 100 lines
```

## Upstream sync

The daily schedule merges upstream SearXNG commits with `-X ours` — our branding, settings defaults, and customisations always take precedence over conflicts.

If an upstream update needs manual review (e.g. breaking changes to `settings.yml` schema), cancel the scheduled pipeline in GitLab before 04:00 UTC, merge manually on a branch, resolve conflicts, and push to `master`.

## Troubleshooting

**Container starts but crashes in a loop:**
```bash
docker logs xsearch   # check for entrypoint errors
```
Common causes: volume permission issue, malformed `settings.yml`.

**settings.yml not created in volume:**
Verify the image was built after commit `0edb9fe` (fix for `XSEARCH_SETTINGS_PATH`). If the volume already existed from a broken build, delete and recreate it:
```bash
docker compose -p xsearch down
docker volume rm xsearch_xsearch-config
# redeploy via webhook — entrypoint will recreate settings.yml
```

**Search engines returning no results:**
Check `settings.yml` on the server. The `engines:` section controls which engines are enabled.

**Upstream sync created a bad merge:**
```bash
git revert <bad-commit-sha>
git push gitlab master
```
CI/CD will build and deploy the reverted state.
