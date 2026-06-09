# XSearch — Deployment & Administration

## Infrastructure

| Component | Location |
|-----------|----------|
| Git repository | https://gitlab.xdata.si/xdata/xsearch |
| Container registry | `registry.xdata.si/xdata/xsearch:latest` |
| Stack manager (Dockhand) | http://144.91.101.143:3000 |
| Live URL | https://search.xdata.si |

## CI/CD Pipeline

Stages run automatically on GitLab:

| Stage | Trigger | Action |
|-------|---------|--------|
| `sync-upstream` | Daily schedule (04:00 UTC) | Merges `searxng/searxng:master` — our changes win all conflicts (`-X ours`) |
| `build-image` | Push to `master` | Builds Docker image, pushes to `registry.xdata.si` |
| `deploy` | After build | Triggers Dockhand webhook → pulls new image → restarts container |

Pushing to `master` on GitLab automatically builds and deploys.

## Files on the server

Dockhand repo clone (read-only, managed by Dockhand):
```
/app/data/stacks/Production/xsearch/
```

Docker named volumes (persistent data):
```
/var/lib/docker/volumes/xsearch_xsearch-config/_data/   ← settings.yml
/var/lib/docker/volumes/xsearch_xsearch-data/_data/     ← runtime cache
```

## Updating settings.yml

`settings.yml` in this repo is a **default template** — written to the volume on first container start, never overwritten automatically.

**To apply config changes (SSH to server):**
```bash
nano /var/lib/docker/volumes/xsearch_xsearch-config/_data/settings.yml
docker restart xsearch
```

**If you changed settings.yml in this repo and want to apply it:**
After CI/CD redeploys, the new template appears as `settings.yml.new` in the volume:
```bash
# On server:
cd /var/lib/docker/volumes/xsearch_xsearch-config/_data/
cp settings.yml.new settings.yml
docker restart xsearch
```

## Manual redeploy (without code push)

```bash
curl -X POST "http://144.91.101.143:3000/api/git/stacks/1/webhook" \
     -H "X-Gitlab-Token: <DOCKHAND_WEBHOOK_SECRET>"
```

The secret is stored in GitLab → Settings → CI/CD → Variables as `DOCKHAND_WEBHOOK_SECRET`.

## Required CI/CD variables

Set in GitLab → Settings → CI/CD → Variables:

| Variable | Purpose |
|----------|---------|
| `GITLAB_PUSH_TOKEN` | Token for sync job to push merged commits back to `master` |
| `DOCKHAND_WEBHOOK_URL` | Full webhook URL for the xsearch stack |
| `DOCKHAND_WEBHOOK_SECRET` | Webhook secret token |

## Container environment

Key variables in `docker-compose.yml`:

| Variable | Description |
|----------|-------------|
| `XSEARCH_BASE_URL` | Public URL — update for production domain |
| `SEARXNG_SECRET` | Flask session secret (hardcoded in compose) |
| `GRANIAN_WORKERS` | WSGI worker processes (default: 4) |
| `GRANIAN_THREADS` | Threads per worker (default: 4) |

To change the public URL, edit `docker-compose.yml` and push to `master`:
```yaml
environment:
  - XSEARCH_BASE_URL=https://search.xdata.si
```

## Viewing logs

```bash
# On server (SSH):
docker logs xsearch
docker logs -f xsearch   # follow
```

## Upstream sync

The daily sync merges upstream SearXNG changes with `-X ours` merge strategy — our branding, settings, and customizations always take precedence. If upstream makes breaking changes that need manual review, cancel the scheduled pipeline in GitLab and merge manually.
