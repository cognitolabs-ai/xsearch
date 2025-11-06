# XSearch Custom Logos

Ta mapa je namenjena za custom logotipe ki jih lahko uporabljaš v XSearch.

## Dodajanje logotipa

### 1. Pripravi svoj logotip

Priporočene specifikacije:
- **Format**: SVG (priporočeno) ali PNG
- **Ime datoteke**: `xsearch-logo.svg` ali `xsearch-logo.png`
- **Velikost**:
  - SVG: Viewbox priporočeno 200-400px širine
  - PNG: 400-800px širina, transparent background
- **Barve**: Dark mode kompatibilno (svetle barve za dark theme)

### 2. Dodaj logotip v XSearch

#### Opcija A: Docker Volume Mount (Coolify)

1. Shrani svoj logotip kot `xsearch-logo.svg` v to mapo
2. V Coolify dodaj volume mount:
   ```
   Source: ./custom/logos/xsearch-logo.svg
   Destination: /usr/local/searxng/searx/static/themes/simple/img/xsearch-logo.svg
   ```
3. Redeploy container

#### Opcija B: Docker Build (rebuild required)

1. Kopiraj svoj logotip v `custom/logos/xsearch-logo.svg`
2. Rebuild Docker image z novim logotipom
3. Push in deploy

#### Opcija C: Runtime Copy (exec v container)

1. Upload logotip na strežnik
2. Exec v XSearch container:
   ```bash
   docker exec -it xsearch-container sh
   ```
3. Kopiraj logotip:
   ```bash
   cp /path/to/logo.svg /usr/local/searxng/searx/static/themes/simple/img/xsearch-logo.svg
   ```
4. Restart container

### 3. Preveri rezultat

Odpri XSearch homepage in logotip bi se moral prikazati namesto "XSearch" teksta.

## Primeri logotipov

Dodaj svoje logotipe tukaj:

```
custom/logos/
├── xsearch-logo.svg          # Glavni logotip (SVG)
├── xsearch-logo.png          # Backup PNG verzija
├── xsearch-logo-dark.svg     # Dark mode verzija
├── xsearch-logo-light.svg    # Light mode verzija
└── favicon/
    ├── favicon.svg           # Browser favicon
    ├── favicon.png           # PNG favicon
    └── favicon.ico           # ICO favicon
```

## CSS Styling

Default CSS za logotip:

```css
.index-logo {
    max-width: 300px;
    max-height: 150px;
    height: auto;
}
```

Če želiš custom styling, dodaj v `/etc/xsearch/settings.yml`:

```yaml
ui:
  static_use_hash: true
  # Tvoj custom CSS
```

Ali ustvari custom CSS file.

## Troubleshooting

### Logotip se ne prikaže
- Preveri da je ime datoteke točno `xsearch-logo.svg`
- Preveri permissions (mora biti readable)
- Preveri path v volume mount
- Poglej browser console za errors

### Logotip je prevelik/premajhen
- Uredi SVG viewBox ali PNG resolucijo
- Dodaj custom CSS za .index-logo class

### Fallback na tekst
Če logotip ni na voljo, se avtomatsko prikaže "XSearch" tekst.
