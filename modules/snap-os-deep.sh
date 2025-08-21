#!/usr/bin/env bash
set -euo pipefail
HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT="$(dirname "$HERE")"
source "${ROOT}/lib/common.sh"

main() {
  mk_snap_dir "snap-os-deep"

  # META / OS
  [ -f /etc/os-release ] && save_file_copy /etc/os-release meta/os-release.txt
  have lsb_release && save_cmd meta/lsb_release.txt lsb_release -a || true
  save_cmd meta/uname.txt uname -a
  save_cmd meta/hostnamectl.txt bash -lc 'command -v hostnamectl >/dev/null && hostnamectl || true'
  save_cmd meta/uptime.txt bash -lc 'uptime; w'
  save_cmd meta/env.txt bash -lc 'env | sort'
  save_cmd meta/id.txt id

  # PACKAGES (разные дистры)
  have dpkg    && save_cmd os/dpkg-l.txt dpkg -l || true
  have rpm     && save_cmd os/rpm-qa.txt rpm -qa || true
  have apk     && save_cmd os/apk-info.txt apk info -vv || true
  have pacman  && save_cmd os/pacman-Qe.txt bash -lc 'pacman -Qe || true' || true

  # USERS / GROUPS
  [ -r /etc/passwd ] && save_file_copy /etc/passwd os/etc-passwd.txt
  [ -r /etc/group  ] && save_file_copy /etc/group  os/etc-group.txt
  have getent && save_cmd os/getent-passwd.txt getent passwd || true
  have getent && save_cmd os/getent-group.txt  getent group  || true

  # SYSCTL / LIMITS
  save_cmd os/sysctl-all.txt bash -lc 'sysctl -a 2>/dev/null || true'
  [ -d /etc/sysctl.d ] && save_cmd os/sysctl.d-list.txt bash -lc 'find /etc/sysctl.d -maxdepth 1 -type f -printf "%p\n" | sort'
  [ -r /etc/security/limits.conf ] && save_file_copy /etc/security/limits.conf os/limits.conf.txt

  # NETWORK / FIREWALL (deep)
  have ufw && save_cmd network/ufw.txt ufw status verbose || true
  have iptables-save && save_cmd network/iptables-save.txt iptables-save || true
  have nft && save_cmd network/nft-ruleset.txt nft list ruleset || true
  save_cmd network/ip-addr.txt  ip -br a
  save_cmd network/ip-route.txt ip r

  # KERNEL / JOURNAL (последние 48ч)
  if have journalctl; then
    save_cmd logs/journal-kernel-48h.txt bash -lc "journalctl -k --since '48 hours ago' || true"
    save_cmd logs/journal-oom-segfault-48h.txt bash -lc "journalctl -k --since '48 hours ago' | egrep -i 'out of memory|killed process|oom|segfault|general protection' || true"
  fi

  gen_manifest_sha256
  finish_note
  echo "${SNAP_DIR}"
}
main "$@"
