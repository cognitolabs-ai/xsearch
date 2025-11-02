# XSearch Deployment z Coolify

Navodila za deployment XSearch na strežnik preko Coolify.

## Predpogoji

- Coolify nameščen in konfiguriran
- Dostop do Coolify dashboard
- Domena pripravljena (npr. `search.tvojadomena.com`)

## Korak 1: Dodaj nov projekt v Coolify

1. Prijavi se v **Coolify Dashboard**
2. Klikni **+ New** → **Resource**
3. Izberi **Docker Image**

## Korak 2: Konfiguracija Docker Image

### Basic Settings:

- **Name**: `XSearch`
- **Description**: `XSearch by Cognitolabs AI - Privacy-focused metasearch`
- **Docker Image**: `ghcr.io/cognitolabs-ai/xsearch:latest`
- **Port**: `8080` (internal port)

### Pomembno:
- ✅ Označi **"Publicly accessible"** če želiš da je dostopno
- Pull latest image: **Always**

## Korak 3: Environment Variables

V **Environment Variables** sekciji dodaj naslednje:

### Obvezne spremenljivke:

```bash
XSEARCH_BASE_URL=https://search.tvojadomena.com
XSEARCH_SECRET=<generiraj-naključni-secret>
```

Za generiranje secret key:
```bash
openssl rand -base64 32
```

### Priporočene spremenljivke za produkcijo:

```bash
# Privacy & Security
XSEARCH_IMAGE_PROXY=true
XSEARCH_LIMITER=true
XSEARCH_PUBLIC_INSTANCE=true

# Server settings
XSEARCH_BIND_ADDRESS=0.0.0.0
XSEARCH_PORT=8080

# Performance
GRANIAN_WORKERS=4
GRANIAN_THREADS=4
GRANIAN_BLOCKING_THREADS=4
```

### Coolify specifične nastavitve:

```bash
# Config in data paths (Coolify bo mountal volume)
CONFIG_PATH=/etc/xsearch
DATA_PATH=/var/lib/xsearch
```

## Korak 4: Persistent Storage (Volumes)

V **Volumes/Storage** sekciji dodaj:

### Volume 1 - Configuration:
- **Source**: `xsearch-config` (ime volumna)
- **Destination**: `/etc/xsearch`

### Volume 2 - Data:
- **Source**: `xsearch-data` (ime volumna)
- **Destination**: `/var/lib/xsearch`

**Pomembno**: Coolify bo avtomatsko ustvaril te volume in jih ohranil ob redeploy.

## Korak 5: Domain & SSL

1. V **Domains** sekciji:
   - Dodaj svojo domeno: `search.tvojadomena.com`
   - ✅ Označi **"Generate Let's Encrypt Certificate"** za SSL

2. **DNS Setup** (preden nadaljuješ):
   - Ustvari A record: `search.tvojadomena.com` → IP tvoje Coolify strežnika
   - Počakaj da se DNS propagira (1-10 minut)

## Korak 6: Health Check (opcijsko, priporočeno)

V **Health Check** sekciji:

- **Health Check Path**: `/`
- **Health Check Interval**: `30s`
- **Health Check Timeout**: `10s`
- **Health Check Retries**: `3`

## Korak 7: Deploy!

1. Klikni **Save**
2. Klikni **Deploy**
3. Spremljaj **Deployment Logs**

Coolify bo:
- Pullal Docker image iz GHCR
- Ustvaril volume za konfiguracijo in podatke
- Nastavil SSL certifikat (Let's Encrypt)
- Zagnal XSearch container
- Konfiguriral reverse proxy

## Korak 8: Preveri da deluje

Po uspešnem deployu:

1. Odpri `https://search.tvojadomena.com`
2. Preveri da se XSearch naloži
3. Poskusi kakšno iskanje

## Opcijsko: Dodaj Valkey/Redis Cache

Če želiš dodati caching za boljšo performance:

### 1. Dodaj Valkey service:

1. V Coolify dodaj novo **Service**
2. Izberi **Redis** (ali uporabi Docker image `valkey/valkey:latest`)
3. **Name**: `xsearch-valkey`
4. **Port**: `6379`
5. **Volume**: `xsearch-valkey-data` → `/data`

### 2. Poveži XSearch z Valkey:

Dodaj environment variable v XSearch:

```bash
# Če sta oba v istem projektu/network:
VALKEY_URL=valkey://xsearch-valkey:6379/0
```

### 3. Posodobi settings.yml (custom configuration):

Po prvem zagonu, ustvari custom `settings.yml`:

1. Exec v container ali uporabi **File Editor** v Coolify
2. Uredi `/etc/xsearch/settings.yml`
3. Dodaj Valkey konfiguracijo:

```yaml
valkey:
  url: valkey://xsearch-valkey:6379/0
```

4. Restart XSearch v Coolify

## Monitoring

### Logs:
- V Coolify dashboard → **Logs** tab
- Real-time spremljanje

### Resource Usage:
- V Coolify dashboard → **Metrics** tab
- CPU, RAM, Network

### Restart:
- Če XSearch ne dela pravilno: **Restart** gumb v Coolify

## Posodabljanje

Ko je nova verzija XSearch na voljo:

1. Pojdi na XSearch projekt v Coolify
2. Klikni **Redeploy**
3. Coolify bo pulal najnovejši `latest` tag
4. Zero-downtime update (če je konfiguriran)

ALI če želiš specifično verzijo:

1. Spremeni **Docker Image** na `ghcr.io/cognitolabs-ai/xsearch:v1.2.3`
2. Klikni **Deploy**

## Troubleshooting

### Container se ne zažene:

1. Preveri **Deployment Logs** v Coolify
2. Preveri **Runtime Logs**
3. Pogoste težave:
   - Manjkajoče environment variables
   - Volume permission errors
   - Port conflicts

### Popravek volume permissions:

Če vidiš permission errors v logih:

1. **Exec/SSH** v container (Coolify ima terminal)
2. Poženi:
```bash
chown -R 977:977 /etc/xsearch /var/lib/xsearch
```

### SSL ne dela:

1. Preveri da DNS A record kaže na pravilni IP
2. Počakaj 5-10 minut za Let's Encrypt certifikat
3. Preveri Coolify proxy logs

### XSearch vrača 502:

1. Preveri da je container running (Coolify dashboard)
2. Preveri da je **Port** nastavljen na `8080`
3. Preveri health check logs

## Backup

Coolify shranjuje volume data. Za backup:

### Manual backup preko Coolify:

1. **Volumes** tab → Najdi `xsearch-config` in `xsearch-data`
2. Coolify ima build-in backup opcije (odvisno od verzije)

### Command-line backup:

```bash
# Če imaš SSH dostop do strežnika
docker volume ls | grep xsearch
docker run --rm -v xsearch-config:/source -v $(pwd):/backup alpine tar czf /backup/xsearch-config-backup.tar.gz -C /source .
docker run --rm -v xsearch-data:/source -v $(pwd):/backup alpine tar czf /backup/xsearch-data-backup.tar.gz -C /source .
```

## Dodatne nastavitve

### Custom Settings:

1. V Coolify, uporabi **Exec/Terminal** za dostop v container
2. Uredi `/etc/xsearch/settings.yml`
3. Restart container v Coolify

### Performance tuning:

Za večji promet, povečaj workers in threads:

```bash
GRANIAN_WORKERS=8
GRANIAN_THREADS=4
```

## Coolify Best Practices

1. ✅ **Vedno uporabljaj SSL** (Let's Encrypt je brezplačen)
2. ✅ **Nastavi health checks** za avtomatski restart
3. ✅ **Uporabljaj persistent volumes** za config in data
4. ✅ **Monitor logs** redno
5. ✅ **Backup volumes** pred večjimi spremembami
6. ✅ **Tag specific versions** za produkcijo (ne samo `latest`)

## Cena & Resources

Priporočeni minimalni resources v Coolify:

- **CPU**: 1-2 cores
- **RAM**: 1-2 GB
- **Disk**: 5 GB (za volumes)

Za visok promet:
- **CPU**: 4+ cores
- **RAM**: 4+ GB
- Dodaj Valkey cache

---

**GOTOVO!** 🚀

Tvoj XSearch bo dostopen na `https://search.tvojadomena.com` z avtomatskim SSL.
