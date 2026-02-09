#!/usr/bin/env bash
# Generates files.json manifest for index.html auto-discovery
# Run manually or via git pre-commit hook

set -euo pipefail
cd "$(dirname "$0")"

JSON='{ "files": ['
first=true

# Root-level HTML files (exclude index.html)
for f in *.html; do
  [ "$f" = "index.html" ] && continue
  [ ! -f "$f" ] && continue
  if [ "$first" = true ]; then
    first=false
  else
    JSON+=','
  fi
  JSON+="\"$f\""
done

JSON+='], "folders": ['

# Auto-discover subdirectories containing HTML files
first_folder=true
for dir in */; do
  dir="${dir%/}"
  # Skip hidden dirs and non-directories
  [ ! -d "$dir" ] && continue
  # Check if folder has any HTML files
  html_count=$(find "$dir" -maxdepth 1 -name "*.html" ! -name "index.html" | wc -l | tr -d ' ')
  [ "$html_count" -eq 0 ] && continue

  if [ "$first_folder" = true ]; then
    first_folder=false
  else
    JSON+=','
  fi

  # Collect HTML files in this folder (exclude index.html)
  FILES_ARR='['
  first_file=true
  for hf in "$dir"/*.html; do
    [ "$(basename "$hf")" = "index.html" ] && continue
    [ ! -f "$hf" ] && continue
    if [ "$first_file" = true ]; then
      first_file=false
    else
      FILES_ARR+=','
    fi
    FILES_ARR+="\"$hf\""
  done
  FILES_ARR+=']'

  JSON+="{\"id\":\"$dir\",\"path\":\"$dir/\",\"files\":$FILES_ARR}"
done

JSON+=']}'

echo "$JSON" | python3 -m json.tool > files.json
echo "Generated files.json with $(echo "$JSON" | python3 -c "import sys,json; d=json.load(sys.stdin); print(len(d['files']))" ) files and $(echo "$JSON" | python3 -c "import sys,json; d=json.load(sys.stdin); print(len(d['folders']))" ) folders"
