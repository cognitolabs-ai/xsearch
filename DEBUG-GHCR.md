# Debug: GHCR Image Not Accessible

## Problem
```
Error Head "https://ghcr.io/v2/cognitolabs-ai/xsearch/manifests/latest": denied
```

Coolify ne more dostopati do Docker image v GitHub Container Registry.

## Razlogi in rešitve

### 1. GitHub Actions build še ni končan ali je failal

**Preveri:**
1. Pojdi na https://github.com/cognitolabs-ai/xsearch/actions
2. Preveri "Container" workflow
3. Poglej zadnji run - ali je ✅ uspešen ali ❌ failal?

**Če je failal:**
- Poglej logs
- Popravi napake
- Ponovno zaženi workflow: "Re-run jobs"

**Če se še izvaja:**
- Počakaj da se konča (~10-20 minut za vse arhitekture)
- Container mora biti built in pushed

### 2. Package je privaten (ne public)

**To je najverjetnejši problem!** GHCR packages so privat by default.

**Rešitev:**

1. Pojdi na https://github.com/orgs/cognitolabs-ai/packages

2. Najdi package `xsearch`

3. Klikni na package → **Package settings**

4. Scrollaj do **Danger Zone** → **Change package visibility**

5. Izberi **Public**

6. Potrdi spremembo

7. Poskusi ponovno v Coolify!

### 3. Workflow se ni zagnal

**Preveri trigger:**

Container workflow se zažene samo:
- Po uspešnem Integration workflow
- Ali ročno (workflow_dispatch)

**Ročni zagon:**

1. GitHub → Actions tab
2. Izberi "Container" workflow
3. Klikni "Run workflow" → "Run workflow"
4. Počakaj da se konča

### 4. Package še ne obstaja

**Preveri če package obstaja:**

Odpri v brskalniku:
```
https://github.com/cognitolabs-ai/xsearch/pkgs/container/xsearch
```

**Če ne obstaja:**
- Container workflow še ni nikoli uspešno končal
- Zaženi workflow ročno (glej zgoraj)

## Začasna rešitev: Uporabi Docker Hub

Če imaš DOCKERHUB secrets nastavljene:

1. Počakaj da se Container workflow konča
2. Image bo na Docker Hub: `docker.io/cognitolabs-ai/xsearch:latest`
3. V Coolify uporabi Docker Hub image namesto GHCR

**ALI**

Build lokalno in push:

```bash
# Build
docker build -t cognitolabs-ai/xsearch:latest .

# Push na Docker Hub (potrebuješ login)
docker login
docker push cognitolabs-ai/xsearch:latest
```

## Quick Fix Za Coolify

### Opcija A: Počakaj na GHCR build

1. Zaženi Container workflow ročno v GitHub
2. Počakaj ~15-20 minut
3. Nastavi package na Public
4. Redeploy v Coolify z `ghcr.io/cognitolabs-ai/xsearch:latest`

### Opcija B: Uporabi Docker Hub (če obstaja)

V Coolify spremeni image v:
```
docker.io/cognitolabs-ai/xsearch:latest
```

ALI če še Docker Hub build ni končan:
```
searxng/searxng:latest
```
(Originalni SearXNG image - deluje, ampak brez rebrandinga)

## Preverjanje Accessibility

Test ali je image public:

```bash
# Brez prijave
docker pull ghcr.io/cognitolabs-ai/xsearch:latest
```

Če deluje = ✅ Public
Če zahteva login = ❌ Private

## Naslednji koraki

1. ✅ Preveri GitHub Actions status
2. ✅ Nastavi GHCR package na Public
3. ✅ Počakaj na build completion
4. ✅ Retry deploy v Coolify

---

**TL;DR**: Pojdi na GitHub package settings in nastavi visibility na **Public**!
