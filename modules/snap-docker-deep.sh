#!/usr/bin/env bash
set -euo pipefail
HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT="$(dirname "$HERE")"
source "${ROOT}/lib/common.sh"

main() {
  mk_snap_dir "snap-docker-deep"

  if ! have docker; then
    echo "docker not installed" > "${SNAP_DIR}/docker/notice.txt"
    append_index_link docker/notice.txt docker/notice.txt
  fi

  save_cmd docker/version.txt docker version
  save_cmd docker/info.txt    docker info
  save_cmd docker/ps-all.txt  docker ps -a --no-trunc

  # Compose (если проект в /opt/somleng)
  save_cmd docker/compose-version.txt bash -lc 'docker compose version || docker-compose version || true'
  save_cmd docker/compose-config.txt  bash -lc 'cd /opt/somleng 2>/dev/null && (docker compose config || docker-compose config) || true'

  # Events за 72 часа (start/die)
  NOW="$(date -Is)"
  SINCE="$(date -Is -d '72 hours ago' 2>/dev/null || date -Is)"
  save_cmd docker/events-72h.txt bash -lc "docker events --since '${SINCE}' --until '${NOW}' --filter event=start --filter event=die 2>/dev/null || true"

  # По контейнерам: inspect + логи за 48ч
  for id in $(docker ps -aq); do
    save_cmd "docker/inspect/${id}.json" docker inspect "$id"
    save_cmd "docker/logs/${id}.log"     docker logs --since 48h "$id"
  done

  # Сети
  save_cmd docker/networks.txt docker network ls
  for net in $(docker network ls --format '{{.Name}}'); do
    save_cmd "docker/network_inspect/${net}.json" docker network inspect "$net"
  done

  gen_manifest_sha256
  finish_note
}
main "$@"
