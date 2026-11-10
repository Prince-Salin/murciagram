# MurciaGram

Galería mobile-first para descubrir los **45 municipios de la Región de Murcia**.
Es una práctica de HTML5 semántico y CSS3, sin frameworks ni JavaScript.

## Ejecutar

Abre `index.html` en un navegador o inicia un servidor estático desde esta
carpeta:

```powershell
python -m http.server 8123
```

Visita <http://127.0.0.1:8123>.

## Requisitos de la práctica

- Estructura semántica HTML5, metadatos SEO y Open Graph.
- CSS mobile-first con rangos modernos: una columna Flexbox en móvil, masonry
  de dos columnas en tableta y Grid de página con menú lateral en escritorio.
- La galería usa masonry con columnas CSS en pantallas mayores; es la excepción
  necesaria para conservar el diseño Pinterest solicitado, ya que Flexbox no
  genera ese flujo masonry.
- Tarjetas con overlay, animaciones, foco de teclado y estado de favorito
  activo hasta recargar la página mediante CSS (`:checked`).
- `<picture>` con WebP/JPG y variantes móviles de 400 px y escritorio de
  1000 px; imágenes con `loading="lazy"`.
- Estilos de impresión con fondo blanco, texto legible y controles ocultos.
- HTML y clases preparados para la futura fase JavaScript, incluida
  `.card--favorita`.

## Imágenes y automatización

`assets/img/` contiene las cuatro variantes de cada municipio
(móvil/escritorio en WebP/JPG) y es lo único que carga la página. Los originales
no se versionan: si necesitas regenerar las variantes, crea `assets/raw/`, copia
allí las fotos originales y ejecuta el script. Los créditos y licencias de las
fotografías están en el pie de la página.

Se requiere ImageMagick 7 y PowerShell. Instálalo con
`winget install ImageMagick.ImageMagick` y ejecuta la tarea **MurciaGram:
optimizar imágenes** en VS Code (Ctrl+Shift+B), o ejecuta:

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File .\scripts\optimize-images.ps1
```

La tarea lee `assets/raw/` y regenera `assets/img/`. No requiere compilación ni
dependencias web.

## Publicación

El sitio es estático y puede publicarse desde la raíz del repositorio en GitHub
Pages, Vercel o Netlify. La publicación debe configurarse en la plataforma de
destino; este repositorio no incluye credenciales ni configuración de despliegue.

## Estructura

```text
index.html
css/                 reset.css y estilos responsive
assets/icons/        iconos SVG
assets/img/          imágenes optimizadas usadas por la página
scripts/             automatización ImageMagick
.vscode/tasks.json   tarea para generar imágenes
```
