# XSearch Logo Rotation System

XSearch uporablja sistem za random rotacijo barvnih logotipov na homepage.

## Kako deluje

### 1. Logotipi

V `custom/logos/` imamo več barvnih variant:
```
xsearch-blue.svg
xsearch-green.svg
xsearch-orange.svg
xsearch-purple.svg
xsearch-red.svg
```

### 2. JavaScript Rotator

`xsearch-logo-rotator.js` ob vsakem obisku:
1. Naključno izbere enega izmed barvnih logotipov
2. Nastavi ga kot `src` za `<img class="index-logo">`
3. Opcijsko: Shrani izbiro v sessionStorage za konsistentnost med navigacijo

### 3. Faviconi

Posebni favicon logotipi:
- `xs.png` - PNG favicon (32x32 ali 64x64)
- `xg.svg` - SVG favicon

## Kako dodati/spremeniti logotipe

### Dodaj nov barvni logotip:

1. **Ustvari logotip:**
   - Ime: `xsearch-<barva>.svg`
   - Primeri: `xsearch-pink.svg`, `xsearch-yellow.svg`
   - Format: SVG, viewBox ~350x120px

2. **Dodaj v projekt:**
   ```bash
   cp xsearch-pink.svg custom/logos/
   ```

3. **Posodobi JavaScript:**

   Uredi `searx/static/themes/simple/js/xsearch-logo-rotator.js`:
   ```javascript
   const logoVariants = [
       'xsearch-blue',
       'xsearch-green',
       'xsearch-orange',
       'xsearch-purple',
       'xsearch-red',
       'xsearch-pink'  // Dodaj novo
   ];
   ```

4. **Rebuild container:**
   ```bash
   git add custom/logos/xsearch-pink.svg
   git add searx/static/themes/simple/js/xsearch-logo-rotator.js
   git commit -m "feat: Add pink logo variant"
   git push
   ```

### Odstrani barvni logotip:

1. Odstrani datoteko iz `custom/logos/`
2. Odstrani iz JavaScript array-a
3. Commit in push

### Spremeni favicone:

1. Zamenjaj `custom/logos/xs.png` ali `custom/logos/xg.svg`
2. Rebuild container
3. Clear browser cache

## Deployment

### Docker Build (Avtomatsko)

Dockerfile avtomatsko kopira vse `xsearch-*.svg` logotipe v container:

```dockerfile
COPY --chown=977:977 ./custom/logos/xsearch-*.svg ./searx/static/themes/simple/img/
COPY --chown=977:977 ./custom/logos/xs.png ./custom/logos/xg.svg ./searx/static/themes/simple/img/
```

### Coolify Volume Mount (Za testing)

Če želiš testirati nove logotipe brez rebuilda:

```bash
# V Coolify Storage/Volumes dodaj za vsak logotip:
Source: /opt/xsearch-assets/xsearch-blue.svg
Destination: /usr/local/searxng/searx/static/themes/simple/img/xsearch-blue.svg

Source: /opt/xsearch-assets/xs.png
Destination: /usr/local/searxng/searx/static/themes/simple/img/xs.png
```

Redeploy in logotipi bodo posodobljeni.

## CSS Styling

Logotipi uporabljajo `.index-logo` class:

```css
.index-logo {
    max-width: 350px;
    max-height: 120px;
    transition: opacity 0.3s ease-in-out;
}
```

### Spremeni velikost:

Uredi `searx/static/themes/simple/css/xsearch-custom.css`:

```css
.index-logo {
    max-width: 400px;  /* Povečaj */
    max-height: 150px;
}
```

### Responsive:

Že vključeno za mobile:

```css
@media screen and (max-width: 768px) {
    .index-logo {
        max-width: 200px;
    }
}
```

## Session Persistence

**Default:** Vsak reload = nov random logotip

**Spremeni v:** Enak logotip za celotno session

V `xsearch-logo-rotator.js` spremeni `setRandomLogo()`:

```javascript
function setRandomLogo() {
    // Namesto getRandomLogo() uporabi:
    const selectedLogo = getSessionLogo(); // Ta funkcija že obstaja!
    // ...
}
```

## Testing

### Lokalno:

```bash
# Build container
make container.build

# Run
docker run -p 8080:8080 localhost/cognitolabs-ai/xsearch:latest

# Odpri http://localhost:8080
# Reload page večkrat → različni logotipi
```

### Production:

1. Push spremembe na GitHub
2. Počakaj na Container workflow (15-20min)
3. Redeploy v Coolify
4. Test: https://search.tvojadomena.com
5. Hard refresh (Ctrl+F5) večkrat

## Troubleshooting

### Logotip se ne menja:

**Preveri JavaScript console:**
```
F12 → Console → Išči "XSearch: Using logo variant:"
```

**Preveri da so vsi logotipi dostopni:**
```bash
curl https://search.tvojadomena.com/static/themes/simple/img/xsearch-blue.svg
curl https://search.tvojadomena.com/static/themes/simple/img/xsearch-red.svg
# itd...
```

**Clear cache:**
- Browser: Ctrl+Shift+Delete
- Coolify: Redeploy

### Favicon se ne prikaže:

**Preveri da datoteke obstajajo:**
```bash
docker exec -it <container> ls -la /usr/local/searxng/searx/static/themes/simple/img/xs.png
docker exec -it <container> ls -la /usr/local/searxng/searx/static/themes/simple/img/xg.svg
```

**Clear browser favicon cache:**
- Chrome: chrome://favicon/https://search.tvojadomena.com
- Firefox: Clear all history
- Hard refresh

### JavaScript error:

**Check syntax:**
```bash
# Validate JS
node -c searx/static/themes/simple/js/xsearch-logo-rotator.js
```

**Check browser console:**
```
F12 → Console → Look for errors
```

## Struktura datotek

```
xsearch/
├── custom/logos/
│   ├── xsearch-blue.svg       ← Main logos (rotated)
│   ├── xsearch-green.svg
│   ├── xsearch-orange.svg
│   ├── xsearch-purple.svg
│   ├── xsearch-red.svg
│   ├── xs.png                 ← Favicons
│   └── xg.svg
├── searx/
│   ├── static/themes/simple/
│   │   ├── img/               ← Copied here in container
│   │   │   ├── xsearch-*.svg
│   │   │   ├── xs.png
│   │   │   └── xg.svg
│   │   ├── js/
│   │   │   └── xsearch-logo-rotator.js  ← Rotation script
│   │   └── css/
│   │       └── xsearch-custom.css       ← Logo styling
│   └── templates/simple/
│       ├── index.html         ← Uses rotator
│       └── base.html          ← Favicon links
└── container/
    └── dist.dockerfile        ← Copies logos
```

---

**Vse deluje avtomatsko!** Dodaj logotipe v `custom/logos/`, commit, push, in XSearch bo random prikazal enega izmed njih. 🎨
