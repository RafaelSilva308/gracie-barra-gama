# Pipeline de mídia (Higgsfield → frames)

1. Os clipes são gerados no Higgsfield (MCP) e as URLs de resultado entram em `manifest.json`.
2. Um push que altere `manifest.json` dispara `.github/workflows/media-pipeline.yml`.
3. O workflow baixa cada mídia, extrai os quadros com ffmpeg e commita no branch:
   - `assets/video/<id>.mp4` — clipe original (720p, 5 s, sem áudio)
   - `assets/frames/<id>/d/NNN.webp` — quadros desktop (1280 px, 10 fps)
   - `assets/frames/<id>/m/NNN.webp` — quadros mobile (960 px, 6 fps)
   - `assets/generated/<id>.last.png` — último quadro (usado como `start_image` do clipe seguinte)
   - `assets/generated/previews/*` — folhas de contato para revisão
4. Itens já processados são pulados (`state/<id>.done`).

Os ids/contagens de quadros usados pelo site ficam em `CLIPS` no `index.html`.
