#!/usr/bin/env bash
set -euo pipefail
HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT="$(dirname "$HERE")"
source "${ROOT}/lib/common.sh"

main() {
  mk_snap_dir "snap-lite"

  # ==== META / OS ====
  [ -f /etc/os-release ] && save_file_copy /etc/os-release meta/os-release.txt
  have lsb_release && save_cmd meta/lsb_release.txt lsb_release -a || true
  save_cmd meta/uname.txt uname -a
  save_cmd meta/hostnamectl.txt bash -lc 'command -v hostnamectl >/dev/null && hostnamectl || echo "no hostnamectl"'
  save_cmd meta/uptime.txt bash -lc 'uptime; w'
  save_cmd meta/id.txt id
  save_cmd meta/env.txt bash -lc 'env | sort'

  # ==== NETWORK ====
  if have ss; then
    save_cmd network/ss.txt ss -tulpn
  else
    save_cmd network/netstat.txt netstat -tulpn || true
  fi
  have ufw && save_cmd network/ufw.txt ufw status verbose || echo > "${SNAP_DIR}/network/ufw.txt"

  # ==== DOCKER ====
  have docker && save_cmd docker/ps.txt docker ps -a --no-trunc || true
  save_cmd docker/compose-version.txt bash -lc 'docker compose version || docker-compose version || true'
  for f in docker-compose.yml docker-compose.yaml docker-compose.override.yml; do
    [ -f "/opt/somleng/$f" ] && save_file_copy "/opt/somleng/$f" "somleng/$f"
  done
  save_cmd docker/compose-config.txt bash -lc 'cd /opt/somleng 2>/dev/null && (docker compose config || docker-compose config) || echo "no compose config"'

  # ==== FS configs (дерево + права) ====
  FS_DIR="/opt/somleng/conf/freeswitch"
  if [ -d "$FS_DIR" ]; then
    if have tree; then
      save_cmd fs/tree.txt tree -apug --dirsfirst -F -L 3 "$FS_DIR"
    fi
    save_cmd fs/ls-perms.txt bash -lc "find '$FS_DIR' -printf '%M %u %g %s %TY-%Tm-%Td %TH:%TM %p\n' | sort"
  else
    echo "not found: $FS_DIR" > "${SNAP_DIR}/fs/notice.txt"
    append_index_link fs/notice.txt fs/notice.txt
  fi

  # ==== Core dumps presence ====
  CORE_DIR="/opt/somleng/core_dumps"
  if [ -d "$CORE_DIR" ]; then
    save_cmd core_dumps/ls.txt ls -lah "$CORE_DIR"
  fi

  gen_manifest_sha256
  finish_note
}
main "$@"
