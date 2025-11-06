# XSearch - Deployment Custom Logotipa

Navodila kako dodati svoj logotip v XSearch.

## 1. Pripravi svoj logotip

### Specifikacije:

**Format:**
- SVG (priporočeno) - skalabilno, manjše datoteke
- PNG - če SVG ni na voljo (transparent background)

**Ime datoteke:**
```
xsearch-logo.svg
```
ALI
```
xsearch-logo.png
```

**Velikost:**
- SVG: viewBox="0 0 400 100" (ali podobno razmerje)
- PNG: 800x200px (2x za retina) z transparent background

**Barve:**
- Svetle barve za dark mode kompatibilnost
- ALI ustvari 2 verziji: xsearch-logo-light.svg in xsearch-logo-dark.svg

## 2. Dodaj logotip v projekt

### Metoda 1: Volume Mount v Coolify (Najlažje)

1. **Pripravi logotip na strežniku:**
   ```bash
   # Na strežniku
   mkdir -p /opt/xsearch-assets
   # Upload svoj xsearch-logo.svg v /opt/xsearch-assets/
   ```

2. **V Coolify dodaj Storage/Volume:**
   - Pojdi na XSearch projekt
   - **Storages** tab
   - Add new volume:
     ```
     Source: /opt/xsearch-assets/xsearch-logo.svg
     Destination: /usr/local/searxng/searx/static/themes/simple/img/xsearch-logo.svg
     ```

3. **Redeploy:**
   - Klikni **Redeploy**
   - Logotip bo viden na homepage

### Metoda 2: Git Commit + Rebuild

1. **Dodaj logotip v repo:**
   ```bash
   # Lokalno
   cp your-logo.svg custom/logos/xsearch-logo.svg
   git add custom/logos/xsearch-logo.svg
   git commit -m "feat: Add custom XSearch logo"
   git push
   ```

2. **Posodobi Dockerfile da kopira logotip:**

   Dodaj v `container/dist.dockerfile` pred ENTRYPOINT:
   ```dockerfile
   # Copy custom logo if exists
   COPY --chown=977:977 ./custom/logos/xsearch-logo.* ./searx/static/themes/simple/img/ || true
   ```

3. **Rebuild in redeploy:**
   - GitHub Actions bo avtomatsko zgradil nov image
   - V Coolify: **Redeploy** ko je build končan

### Metoda 3: Runtime Copy (Quick Test)

1. **Upload logotip na strežnik**

2. **Exec v container:**
   ```bash
   # Najdi container ID
   docker ps | grep xsearch

   # Exec v container
   docker exec -it <container-id> sh
   ```

3. **Kopiraj logotip:**
   ```bash
   # V containeru
   cp /path/to/uploaded/logo.svg /usr/local/searxng/searx/static/themes/simple/img/xsearch-logo.svg

   # Preveri
   ls -la /usr/local/searxng/searx/static/themes/simple/img/xsearch-logo.svg
   ```

4. **Reload page:**
   - Odpri XSearch v brskalniku
   - Hard refresh (Ctrl+F5)

**OPOMBA:** Ta metoda NI persistent - ob restartu se logotip izgubi!

## 3. CSS Customization (Opcijsko)

Če želiš spremeniti velikost ali styling logotipa:

### V Coolify:

1. **Environment Variable:**
   Dodaj v Coolify environment variables:
   ```
   XSEARCH_CUSTOM_CSS=true
   ```

2. **Volume mount custom CSS:**
   ```
   Source: /opt/xsearch-assets/custom.css
   Destination: /usr/local/searxng/searx/static/themes/simple/css/xsearch-custom.css
   ```

3. **Custom CSS (`custom.css`):**
   ```css
   .index-logo {
       max-width: 400px !important;
       max-height: 200px !important;
   }
   ```

## 4. Preveri rezultat

1. Odpri `https://search.tvojadomena.com`
2. Logotip bi se moral prikazati namesto "XSearch" teksta
3. Preveri na mobile (responsive)

## 5. Troubleshooting

### Logotip se ne prikaže

**Preveri path:**
```bash
docker exec -it <container-id> ls -la /usr/local/searxng/searx/static/themes/simple/img/xsearch-logo.svg
```

**Preveri permissions:**
```bash
docker exec -it <container-id> stat /usr/local/searxng/searx/static/themes/simple/img/xsearch-logo.svg
```

Mora biti readable (r--r--r-- ali 644).

**Browser cache:**
- Hard refresh (Ctrl+F5)
- Clear browser cache
- Probaj incognito mode

**Check logs:**
```bash
docker logs <container-id> | grep -i logo
```

### Logotip je prevelik/premajhen

**Opcija 1:** Uredi SVG viewBox
```xml
<svg viewBox="0 0 400 100">  <!-- Spremeni to -->
```

**Opcija 2:** Dodaj custom CSS (glej zgoraj)

**Opcija 3:** Spremeni PNG resolution

### Fallback na "XSearch" tekst

To je pričakovano če logotip manjka - template ima fallback na <h1>XSearch</h1>.

Če želiš skriti tekst tudi ko logotip ne obstaja, odstrani `onerror` handler.

## Primeri

Glej `custom/logos/xsearch-logo-example.svg` za preprost primer.

Zamenjaj z svojim dejanskim logotipom!

---

**Priporočena metoda:** Volume Mount v Coolify (Metoda 1)
- Najlažje za posodabljanje
- Ni potreben rebuild
- Persistent med redeploys
