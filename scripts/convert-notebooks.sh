#!/usr/bin/env bash
#
# Convert Jupyter notebooks under content/notebooks/ into HTML fragments that
# Hugo renders with the theme's "notebooks" layout.
#
# Front matter can live in a raw cell at the top of the notebook (nbconvert
# emits it verbatim). Otherwise, the front matter block at the top of an
# existing .html file is preserved across re-runs, and newly converted
# notebooks get a draft front matter stub to fill in.
#
# Usage:
#   scripts/convert-notebooks.sh                 # convert every notebook
#   scripts/convert-notebooks.sh path/to/nb.ipynb ...
#
# Requires: jupyter nbconvert (pip install nbconvert)
set -euo pipefail

cd "$(dirname "$0")/.."

notebooks=("$@")
if [ ${#notebooks[@]} -eq 0 ]; then
  notebooks=(content/notebooks/*.ipynb)
fi

for nb in "${notebooks[@]}"; do
  html="${nb%.ipynb}.html"
  body="$(mktemp)"
  out="$(mktemp)"

  jupyter nbconvert "$nb" --to html --template basic --stdout > "$body"

  if [ "$(head -n 1 "$body")" = "---" ]; then
    # The notebook's first raw cell holds the front matter; keep it as is.
    :
  elif [ -f "$html" ] && [ "$(head -n 1 "$html")" = "---" ]; then
    # Keep the existing front matter (everything up to the closing "---").
    sed -n '1,/^---$/p' "$html" > "$out"
  else
    printf -- '---\ntitle: "%s"\ndate: %s\ndraft: true\ncategories: []\n---\n' \
      "$(basename "${nb%.ipynb}")" "$(date +%F)" > "$out"
  fi

  cat "$body" >> "$out"
  mv "$out" "$html"
  rm -f "$body"
  echo "wrote $html"
done
