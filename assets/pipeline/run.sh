#!/usr/bin/env bash
# Processa assets/pipeline/manifest.json. Idempotente: pula itens já processados.
set -euo pipefail
cd "$(dirname "$0")/../.."
M=assets/pipeline/manifest.json
mkdir -p assets/generated/previews assets/frames assets/video assets/pipeline/state
n=$(jq length "$M")
for ((i=0;i<n;i++)); do
  id=$(jq -r ".[$i].id" "$M"); url=$(jq -r ".[$i].url" "$M"); kind=$(jq -r ".[$i].kind" "$M")
  fps=$(jq -r ".[$i].fps // 12" "$M"); mfps=$(jq -r ".[$i].mfps // 8" "$M")
  dw=$(jq -r ".[$i].dw // 1280" "$M"); mw=$(jq -r ".[$i].mw // 640" "$M")
  q=$(jq -r ".[$i].q // 80" "$M")
  stamp="assets/pipeline/state/$id.done"
  if [[ -f "$stamp" ]]; then echo "skip $id"; continue; fi
  echo "== $id ($kind)"
  if [[ "$kind" == "image" ]]; then
    curl -fsSL -o "assets/generated/$id.png" "$url"
    ffmpeg -y -loglevel error -i "assets/generated/$id.png" -vf "scale=1280:-2" -q:v 3 "assets/generated/previews/$id.jpg"
  else
    curl -fsSL -o "assets/video/$id.mp4" "$url"
    ffprobe -v error -select_streams v:0 -show_entries stream=width,height,r_frame_rate,nb_frames,duration -of default=nw=1 "assets/video/$id.mp4" > "assets/pipeline/state/$id.probe.txt" || true
    rm -rf "assets/frames/$id"; mkdir -p "assets/frames/$id/d" "assets/frames/$id/m"
    ffmpeg -y -loglevel error -i "assets/video/$id.mp4" -vf "fps=$fps,scale=$dw:-2:flags=lanczos" -c:v libwebp -quality "$q" -compression_level 6 "assets/frames/$id/d/%03d.webp"
    ffmpeg -y -loglevel error -i "assets/video/$id.mp4" -vf "fps=$mfps,scale=$mw:-2:flags=lanczos" -c:v libwebp -quality 72 -compression_level 6 "assets/frames/$id/m/%03d.webp"
    # último quadro em PNG (start_image do próximo clipe) e folha de contato para QA
    ffmpeg -y -loglevel error -sseof -0.15 -i "assets/video/$id.mp4" -update 1 -frames:v 1 "assets/generated/$id.last.png"
    ffmpeg -y -loglevel error -i "assets/video/$id.mp4" -vf "fps=1,scale=480:-2,tile=3x2" -frames:v 1 -q:v 3 "assets/generated/previews/$id.sheet.jpg"
    ffmpeg -y -loglevel error -i "assets/video/$id.mp4" -vf "scale=1280:-2" -frames:v 1 -q:v 3 "assets/generated/previews/$id.first.jpg"
    ls "assets/frames/$id/d" | wc -l > "assets/pipeline/state/$id.count.txt"
  fi
  date -u +%FT%TZ > "$stamp"
done
echo "done"
