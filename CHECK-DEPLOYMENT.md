# Kako preveriti ali so spremembe deployed

## Problem: Spremembe niso vidne na https://search.cognitolabs.eu/

### Razlog 1: GitHub Actions build še ni končan ⏳

**Preveri status:**

1. Pojdi na: **https://github.com/cognitolabs-ai/xsearch/actions**
2. Poglej zadnji "Container" workflow run
3. Ali je status:
   - 🟡 **Rumeno (In Progress)** = Build še teče, počakaj
   - 🟢 **Zeleno (Success)** = Build je končan, pojdi na korak 2
   - 🔴 **Rdeče (Failed)** = Build je failal, poglej error logs

**Časovnica:**
- Integration workflow: ~10-15 minut
- Container workflow: ~15-25 minut
- **Skupaj**: ~30-40 minut od push-a

**Zadnji push:** Najdi commit `267f610d9` v Actions

### Razlog 2: Coolify uporablja staro verzijo ⚠️

**Tudi če je build končan**, Coolify NE posodobi avtomatsko!

**Ročni redeploy:**

1. **Pojdi v Coolify Dashboard**
2. Izberi **XSearch** projekt
3. Klikni **"Redeploy"** gumb (zgoraj desno)
4. Počakaj 2-3 minute
5. Preveri logs: `XSearch 2025.11.6-267f610d9`

**Preveri trenutno verzijo:**

V Coolify Logs ali Terminal:
```bash
# Exec v container
docker exec -it <container-name> sh

# Preveri verzijo
echo $XSEARCH_VERSION

# Izhod mora biti: 2025.11.6-267f610d9 ali novejše
```

### Razlog 3: Browser cache 🔄

**Hard refresh:**
- **Chrome/Edge**: Ctrl + Shift + R (Linux/Win) ali Cmd + Shift + R (Mac)
- **Firefox**: Ctrl + F5 (Linux/Win) ali Cmd + Shift + R (Mac)
- **Safari**: Cmd + Option + R

**Clear cache:**
1. F12 → Network tab
2. ✅ Disable cache
3. Reload page

**Incognito mode:**
- Odpri novo incognito/private window
- Test URL: https://search.cognitolabs.eu/

### Razlog 4: CDN ali Proxy cache

Če uporabljaš Cloudflare ali drug CDN:

**Cloudflare:**
1. Dashboard → Caching
2. **Purge Everything**
3. Počakaj 1-2 minuti

**Nginx proxy cache:**
```bash
# SSH v strežnik
sudo rm -rf /var/cache/nginx/*
sudo systemctl reload nginx
```

## Step-by-Step Diagnostics

### 1. Preveri GitHub Actions ✅

```bash
# URL za Actions
https://github.com/cognitolabs-ai/xsearch/actions

# Išči workflow run z commit: 267f610d9
# Status mora biti ✅ zeleno
```

**Če ni zeleno:**
- Počakaj da se konča
- Če je rdeče, poglej error logs

### 2. Preveri katera verzija je deployed 🔍

**Metoda A: Check container logs**

V Coolify → Logs tab:
```
XSearch 2025.11.6-267f610d9  ← Mora biti to!
```

**Metoda B: Check homepage source**

Odpri https://search.cognitolabs.eu/ → View Source (Ctrl+U):
```html
<meta name="generator" content="searxng/2025.11.6-267f610d9">
```

**Metoda C: Check Docker image tag**

```bash
# V Coolify Terminal ali SSH
docker ps | grep xsearch
docker inspect <container-id> | grep Image
```

### 3. Redeploy če je potrebno 🔄

**V Coolify:**

1. **Stop** (opcijsko)
2. **Redeploy** ← POMEMBNO
3. Spremljaj **Deployment Logs**
4. Ko vidiš "XSearch 2025.11.6-267f610d9" = ✅ Success

**Časovnica:** ~2-5 minut

### 4. Preveri da spremembe delujejo ✨

**Homepage test:**
```
1. Odpri https://search.cognitolabs.eu/
2. Vidiš XSearch logotip (barvni)
3. Reload (F5) → drug barvni logotip
4. F12 Console → "XSearch: Using logo variant: xsearch-blue"
```

**Favicon test:**
```
1. Preveri browser tab ikono
2. Mora biti xs.png/xg.svg (tvoj custom favicon)
```

**View Source test:**
```
1. Ctrl+U (View Source)
2. Išči: <img src="/static/themes/simple/img/xsearch-blue.svg"
3. Išči: <script src="/static/js/xsearch-logo-rotator.js"
```

## Če še vedno ne deluje

### Debug Checklist:

**1. GitHub Actions:**
- [ ] Container workflow je ✅ Success
- [ ] Image je pushed na GHCR
- [ ] Commit hash je pravilen (267f610d9)

**2. Coolify:**
- [ ] Redeploy je bil izveden
- [ ] Logs kažejo novo verzijo
- [ ] Container je Running

**3. Browser:**
- [ ] Hard refresh (Ctrl+Shift+R)
- [ ] Cache clear
- [ ] Incognito mode test

**4. Files:**
```bash
# Exec v container
docker exec -it <container> sh

# Check files exist:
ls -la /usr/local/searxng/searx/static/themes/simple/img/xsearch-*.svg
ls -la /usr/local/searxng/searx/static/themes/simple/js/xsearch-logo-rotator.js

# Check template:
cat /usr/local/searxng/searx/templates/simple/index.html | grep xsearch-logo-rotator
```

### Manual Fix (Last Resort):

Če build deluje ampak Coolify ne posodobi:

1. **Delete container** v Coolify
2. **Deploy** from scratch
3. Ali **Pull latest image manually:**
   ```bash
   docker pull ghcr.io/cognitolabs-ai/xsearch:latest
   ```

## Quick Commands

### Check GitHub Actions status:
```bash
# V browse:
https://github.com/cognitolabs-ai/xsearch/actions/workflows/container.yml

# Najdi run za commit 267f610d9
```

### Check deployed version:
```bash
curl -s https://search.cognitolabs.eu/ | grep 'meta name="generator"'
```

### Force pull latest:
```bash
# V Coolify ali SSH:
docker pull ghcr.io/cognitolabs-ai/xsearch:latest
docker-compose down
docker-compose up -d
```

---

## TL;DR - Quick Fix

1. **Preveri** GitHub Actions je ✅ → https://github.com/cognitolabs-ai/xsearch/actions
2. **Redeploy** v Coolify (če build končan)
3. **Hard Refresh** browser (Ctrl+Shift+R)
4. **Done!** 🎉
