# XSearch - Deployment na strežnik

Hitri vodič za deployment XSearch na produkcijski strežnik.

## 1. Priprava strežnika

### Minimalne zahteve:
- Ubuntu 22.04 LTS (ali novejši)
- 2GB RAM
- 1GB disk prostor
- Docker in Docker Compose

### Namestitev Docker (če še ni nameščen):

```bash
# Posodobi sistem
sudo apt update && sudo apt upgrade -y

# Namesti Docker
curl -fsSL https://get.docker.com -o get-docker.sh
sudo sh get-docker.sh

# Dodaj uporabnika v docker grupo
sudo usermod -aG docker $USER

# Omogoči Docker da se zažene ob boot-u
sudo systemctl enable docker

# Odjavi se in ponovno prijavi da se docker grupa aktivira
exit
```

## 2. Clone in konfiguracija

```bash
# Clone repository
cd /opt
sudo git clone https://github.com/cognitolabs-ai/xsearch.git
sudo chown -R $USER:$USER xsearch
cd xsearch

# Ustvari .env datoteko
cp .env.example .env

# Generiraj secret key
SECRET=$(openssl rand -base64 32)
sed -i "s/CHANGE-ME-TO-RANDOM-SECRET-KEY/$SECRET/" .env

# Uredi .env in nastavi svoj BASE_URL
nano .env
```

### Pomembne nastavitve v .env:

```bash
# OBVEZNO nastavi na tvoj javni URL!
XSEARCH_BASE_URL=https://search.tvojadomena.com

# Secret key (že generiran)
XSEARCH_SECRET=...

# Priporočeno za javne instance
XSEARCH_IMAGE_PROXY=true
XSEARCH_LIMITER=true
XSEARCH_PUBLIC_INSTANCE=true

# Port (če potrebuješ drugega)
XSEARCH_PORT=8080
```

## 3. Zaženi XSearch

### Osnovni deployment (brez cache):

```bash
docker compose up -d
```

### Z Valkey cache (priporočeno):

```bash
docker compose --profile with-cache up -d
```

### Preveri če deluje:

```bash
# Preveri status
docker compose ps

# Poglej log
docker compose logs -f xsearch

# Test
curl http://localhost:8080
```

## 4. Nastavi Nginx reverse proxy

### Namesti Nginx:

```bash
sudo apt install nginx
```

### Ustvari konfiguracijo:

```bash
sudo nano /etc/nginx/sites-available/xsearch
```

Vsebina:

```nginx
server {
    listen 80;
    server_name search.tvojadomena.com;

    location / {
        proxy_pass http://127.0.0.1:8080;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
        proxy_set_header X-Script-Name "";
    }
}
```

Aktiviraj:

```bash
sudo ln -s /etc/nginx/sites-available/xsearch /etc/nginx/sites-enabled/
sudo nginx -t
sudo systemctl reload nginx
```

## 5. Nastavi SSL (Let's Encrypt)

```bash
# Namesti Certbot
sudo apt install certbot python3-certbot-nginx

# Pridobi SSL certifikat
sudo certbot --nginx -d search.tvojadomena.com

# Auto-renewal je že konfiguriran
```

## 6. Firewall (opcijsko, priporočeno)

```bash
# UFW firewall
sudo ufw allow 22/tcp    # SSH
sudo ufw allow 80/tcp    # HTTP
sudo ufw allow 443/tcp   # HTTPS
sudo ufw enable
```

## Upravljanje

### Preveri status:

```bash
cd /opt/xsearch
docker compose ps
docker compose logs -f
```

### Restart:

```bash
docker compose restart
```

### Posodobi na novo verzijo:

```bash
cd /opt/xsearch
git pull
docker compose pull
docker compose up -d
```

### Backup:

```bash
cd /opt
sudo tar -czf xsearch-backup-$(date +%Y%m%d).tar.gz xsearch/
```

### Stop:

```bash
docker compose down
```

## Troubleshooting

### Container se ne zažene:

```bash
docker compose logs xsearch
```

### Permission errors:

```bash
sudo chown -R 977:977 xsearch-config/ xsearch-data/
```

### Port že v uporabi:

Spremeni `XSEARCH_PORT` v `.env` in ponovno zaženi.

### Nginx 502 Bad Gateway:

Preveri če XSearch deluje:
```bash
docker compose ps
curl http://localhost:8080
```

## Monitoring

### Resource usage:

```bash
docker stats
```

### Logs:

```bash
# Real-time logs
docker compose logs -f xsearch

# Last 100 lines
docker compose logs --tail=100 xsearch
```

## Performance tuning za visok promet

V `.env`:

```bash
GRANIAN_WORKERS=8
GRANIAN_THREADS=4
```

Uporabi Valkey cache:

```bash
docker compose --profile with-cache up -d
```

## Varnost

1. ✅ Vedno uporabljaj HTTPS
2. ✅ Nastavi močan `XSEARCH_SECRET`
3. ✅ Omogoči `XSEARCH_LIMITER=true` za javne instance
4. ✅ Redno posodabljaj Docker images
5. ✅ Uporabi firewall
6. ✅ Naredi redne backupe

## Podpora

- Dokumentacija: `DEPLOYMENT.md`
- GitHub Issues: https://github.com/cognitolabs-ai/xsearch/issues

---

**READY TO GO!** 🚀

Po teh korakih bo tvoj XSearch instance dostopen na `https://search.tvojadomena.com`
