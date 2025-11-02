# XSearch Deployment Guide

This guide covers deploying XSearch by Cognitolabs AI on a production server.

## Quick Start

### 1. Prerequisites

- Docker Engine 20.10+ and Docker Compose v2
- At least 2GB RAM, 1GB disk space
- Linux server (Ubuntu 22.04 LTS recommended)

### 2. Basic Deployment

```bash
# Clone the repository
git clone https://github.com/cognitolabs-ai/xsearch.git
cd xsearch

# Create environment file
cp .env.example .env

# Generate a secure secret key
XSEARCH_SECRET=$(openssl rand -base64 32)
sed -i "s/CHANGE-ME-TO-RANDOM-SECRET-KEY/$XSEARCH_SECRET/" .env

# Edit .env and set your XSEARCH_BASE_URL
nano .env

# Start XSearch
docker compose up -d

# Check logs
docker compose logs -f xsearch
```

XSearch will be available at http://localhost:8080

### 3. With Valkey/Redis Cache (Recommended)

For better performance with caching:

```bash
# Start with Valkey cache
docker compose --profile with-cache up -d

# Verify both containers are running
docker compose ps
```

## Production Setup

### Environment Variables

Edit `.env` file with production values:

```bash
# REQUIRED - Set to your public URL
XSEARCH_BASE_URL=https://search.yourdomain.com

# REQUIRED - Generate secure secret
XSEARCH_SECRET=your-random-secret-here

# RECOMMENDED for public instances
XSEARCH_IMAGE_PROXY=true
XSEARCH_LIMITER=true
XSEARCH_PUBLIC_INSTANCE=true

# Optional: Adjust port
XSEARCH_PORT=8080
```

### Reverse Proxy Setup

#### Nginx

```nginx
server {
    listen 443 ssl http2;
    server_name search.yourdomain.com;

    ssl_certificate /path/to/cert.pem;
    ssl_certificate_key /path/to/key.pem;

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

#### Caddy

```caddy
search.yourdomain.com {
    reverse_proxy localhost:8080
}
```

### SSL/TLS with Let's Encrypt

Using Certbot:

```bash
sudo apt install certbot python3-certbot-nginx
sudo certbot --nginx -d search.yourdomain.com
```

## Configuration

### Custom Settings

XSearch uses `/etc/xsearch/settings.yml` inside the container. To customize:

```bash
# Copy default settings
docker compose exec xsearch cat /etc/xsearch/settings.yml > xsearch-config/settings.yml

# Edit settings
nano xsearch-config/settings.yml

# Restart to apply
docker compose restart xsearch
```

Important settings:
- `general.instance_name` - Display name
- `server.limiter` - Rate limiting (recommended for public instances)
- `server.image_proxy` - Privacy protection
- `ui` - Theme and interface customization

### Search Engines Configuration

To enable/disable search engines, edit `settings.yml`:

```yaml
engines:
  - name: google
    disabled: false
  - name: bing
    disabled: true
```

### Valkey/Redis Cache

To use caching, update `settings.yml`:

```yaml
valkey:
  url: valkey://valkey:6379/0
```

## Monitoring

### Health Check

```bash
# Check if XSearch is responding
curl http://localhost:8080/healthz

# View logs
docker compose logs -f xsearch
```

### Resource Usage

```bash
# Check container stats
docker stats xsearch
```

## Maintenance

### Updates

```bash
# Pull latest image
docker compose pull

# Restart with new image
docker compose up -d

# Clean old images
docker image prune -f
```

### Backup

```bash
# Backup configuration and data
tar -czf xsearch-backup-$(date +%Y%m%d).tar.gz \
    xsearch-config/ \
    xsearch-data/ \
    .env
```

### Restore

```bash
# Restore from backup
tar -xzf xsearch-backup-YYYYMMDD.tar.gz

# Restart services
docker compose up -d
```

## Troubleshooting

### Container won't start

```bash
# Check logs for errors
docker compose logs xsearch

# Verify configuration
docker compose config

# Check permissions
ls -la xsearch-config/ xsearch-data/
```

### Permission errors

The container runs as user `searxng` (UID 977). Fix permissions:

```bash
sudo chown -R 977:977 xsearch-config/ xsearch-data/
```

### Port already in use

Change `XSEARCH_PORT` in `.env`:

```bash
XSEARCH_PORT=8888
```

Then restart:

```bash
docker compose down
docker compose up -d
```

## Security Recommendations

1. **Always use HTTPS** in production
2. **Set strong secret key** (`XSEARCH_SECRET`)
3. **Enable rate limiting** for public instances
4. **Keep Docker images updated** regularly
5. **Restrict network access** using firewall rules
6. **Enable image proxy** to protect user privacy
7. **Regular backups** of configuration and data

## Performance Tuning

For high-traffic instances:

```bash
# Increase workers and threads
GRANIAN_WORKERS=8
GRANIAN_THREADS=4

# Enable Valkey cache
docker compose --profile with-cache up -d
```

## Support

- Documentation: https://docs.searxng.org
- Repository: https://github.com/cognitolabs-ai/xsearch
- Issues: https://github.com/cognitolabs-ai/xsearch/issues

## License

XSearch is licensed under AGPL-3.0-or-later.
