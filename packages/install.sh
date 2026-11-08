#!/usr/bin/env bash
# Prepoznaje package manager (dnf / apt / pacman) i instalira odgovarajucu listu.
# Upotreba:  ./install.sh            (instalira)
#            ./install.sh --dry-run  (samo ispise sta bi radio)
set -uo pipefail

DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
DRY=0
[[ "${1:-}" == "--dry-run" ]] && DRY=1

# shellcheck disable=SC1091
[[ -r /etc/os-release ]] && . /etc/os-release
OS_ID="${ID:-unknown}"

log()  { printf '\033[1;34m==>\033[0m %s\n' "$*"; }
warn() { printf '\033[1;33m!!\033[0m  %s\n' "$*" >&2; }
run()  { if ((DRY)); then echo "[dry-run] $*"; else "$@"; fi; }

detect_pm() {
  if   command -v dnf     >/dev/null 2>&1; then echo dnf
  elif command -v apt-get >/dev/null 2>&1; then echo apt
  elif command -v pacman  >/dev/null 2>&1; then echo pacman
  else return 1; fi
}

# cita listu: izbaci komentare i prazne linije
read_list() { sed -e 's/#.*//' -e 's/[[:space:]]*$//' -e 's/^[[:space:]]*//' -e '/^$/d' "$1"; }

# bulk instalacija; ako padne, probaj paket po paket i ispisi sta nije uspjelo
install_list() {
  local file="$1"; shift
  local -a cmd=("$@") pkgs failed=()
  mapfile -t pkgs < <(read_list "$file")
  log "Instaliram ${#pkgs[@]} paketa iz $(basename "$file")"
  if run "${cmd[@]}" "${pkgs[@]}"; then return 0; fi
  warn "Bulk instalacija nije uspjela, probavam jedan po jedan..."
  local p
  for p in "${pkgs[@]}"; do
    run "${cmd[@]}" "$p" || failed+=("$p")
  done
  ((${#failed[@]})) && warn "Nisu instalirani: ${failed[*]}"
  return 0
}

setup_dnf() {
  if ! rpm -q rpmfusion-free-release >/dev/null 2>&1; then
    log "Ukljucujem RPM Fusion (vlc, ffmpeg)"
    run sudo dnf install -y "https://mirrors.rpmfusion.org/free/fedora/rpmfusion-free-release-$(rpm -E %fedora).noarch.rpm"
  fi
  if [[ ! -f /etc/yum.repos.d/vscode.repo ]]; then
    log "Dodajem VS Code repo"
    run sudo rpm --import https://packages.microsoft.com/keys/microsoft.asc
    if ((DRY)); then echo "[dry-run] write /etc/yum.repos.d/vscode.repo"; else
      printf '[code]\nname=Visual Studio Code\nbaseurl=https://packages.microsoft.com/yumrepos/vscode\nenabled=1\nautorefresh=1\ntype=rpm-md\ngpgcheck=1\ngpgkey=https://packages.microsoft.com/keys/microsoft.asc\n' \
        | sudo tee /etc/yum.repos.d/vscode.repo >/dev/null
    fi
  fi
  if [[ ! -f /etc/yum.repos.d/cloudflared.repo ]]; then
    log "Dodajem Cloudflare repo"
    if ((DRY)); then echo "[dry-run] curl cloudflared.repo"; else
      curl -fsSL https://pkg.cloudflare.com/cloudflared.repo | sudo tee /etc/yum.repos.d/cloudflared.repo >/dev/null
    fi
  fi
  install_list "$DIR/dnf-packages.txt" sudo dnf install -y --skip-unavailable
}

setup_apt() {
  run sudo apt-get update
  run sudo apt-get install -y curl gnupg ca-certificates
  run sudo mkdir -p --mode=0755 /usr/share/keyrings

  if [[ ! -f /etc/apt/sources.list.d/vscode.list ]]; then
    log "Dodajem VS Code repo"
    if ((DRY)); then echo "[dry-run] add vscode.list"; else
      curl -fsSL https://packages.microsoft.com/keys/microsoft.asc | gpg --dearmor | sudo tee /usr/share/keyrings/microsoft.gpg >/dev/null
      echo "deb [arch=amd64,arm64,armhf signed-by=/usr/share/keyrings/microsoft.gpg] https://packages.microsoft.com/repos/code stable main" \
        | sudo tee /etc/apt/sources.list.d/vscode.list >/dev/null
    fi
  fi
  if [[ ! -f /etc/apt/sources.list.d/cloudflared.list ]]; then
    log "Dodajem Cloudflare repo"
    if ((DRY)); then echo "[dry-run] add cloudflared.list"; else
      curl -fsSL https://pkg.cloudflare.com/cloudflare-main.gpg | sudo tee /usr/share/keyrings/cloudflare-main.gpg >/dev/null
      echo "deb [signed-by=/usr/share/keyrings/cloudflare-main.gpg] https://pkg.cloudflare.com/cloudflared any main" \
        | sudo tee /etc/apt/sources.list.d/cloudflared.list >/dev/null
    fi
  fi
  run sudo apt-get update

  # Debian koristi firefox-esr, Ubuntu firefox
  if [[ "$OS_ID" == "debian" ]]; then run sudo apt-get install -y firefox-esr
  else run sudo apt-get install -y firefox; fi

  install_list "$DIR/apt-packages.txt" sudo apt-get install -y
}

setup_pacman() {
  run sudo pacman -Sy --noconfirm
  install_list "$DIR/arch-packages.txt" sudo pacman -S --needed --noconfirm
  if command -v yay >/dev/null 2>&1; then
    install_list "$DIR/aur-packages.txt" yay -S --needed --noconfirm
  else
    warn "yay nije instaliran - preskacem AUR (aur-packages.txt). Instaliraj yay pa pokreni ponovo."
  fi
}

PM="$(detect_pm)" || { warn "Nije pronadjen dnf, apt ni pacman."; exit 1; }
log "Distro: $OS_ID | package manager: $PM"
case "$PM" in
  dnf)    setup_dnf ;;
  apt)    setup_apt ;;
  pacman) setup_pacman ;;
esac
log "Gotovo."
