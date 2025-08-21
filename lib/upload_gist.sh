#!/usr/bin/env bash
set -euo pipefail

upload_gist() {
  : "${GH_TOKEN:?GH_TOKEN is required}"
  : "${SNAP_DIR:?SNAP_DIR is not set}"

  local body="${SNAP_DIR}/.gist.body.json"
  local resp="${SNAP_DIR}/.gist.response.json"

  python3 - "$SNAP_DIR" <<'PY' > "$body"
import json, sys, pathlib
snap = pathlib.Path(sys.argv[1])

def read(p):
    try:
        return (snap/p).read_text(encoding='utf-8', errors='replace')
    except Exception as e:
        return f"[error reading {p}: {e}]"

payload = {
  "description": f"somleng-snapctl {snap.name}",
  "public": False,
  "files": {
    "index.md": {"content": read("index.md")},
    "manifest.sha256": {"content": read("manifest.sha256")}
  }
}
print(json.dumps(payload))
PY

  curl -sS \
    -H "Authorization: token ${GH_TOKEN}" \
    -H "Content-Type: application/json" \
    -X POST https://api.github.com/gists \
    --data @"$body" > "$resp"

  # извлекаем html_url без jq
  local url
  url="$(sed -n 's/.*"html_url": *"\([^"]*\)".*/\1/p' "$resp" | head -n1)" || true
  if [ -n "${url:-}" ]; then
    echo "$url" | tee "${SNAP_DIR}/gist.url"
  else
    echo "[-] Gist upload failed; see ${resp}" >&2
    return 1
  fi
}
