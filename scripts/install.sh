#!/usr/bin/env bash
set -euo pipefail

# phinbox installer — curl --proto '=https' --tlsv1.2 -sSf https://raw.githubusercontent.com/Kooshapari/phenotype-tooling/main/scripts/install.sh | sh
#
# Installs phinbox + phinbox-mcp binaries to ~/.phinbox/bin/
# Supports macOS (arm64, x64), Linux (x64, arm64).

REPO="Kooshapari/phenotype-tooling"
BINARY_NAMES=("phinbox" "phinbox-mcp")
INSTALL_DIR="${PHINBOX_INSTALL_DIR:-$HOME/.phinbox/bin}"
VERSION="${PHINBOX_VERSION:-latest}"
GITHUB_API="https://api.github.com/repos/$REPO"

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
BOLD='\033[1m'
NC='\033[0m'

info()  { echo -e "${GREEN}info${NC}: $*"; }
warn()  { echo -e "${YELLOW}warn${NC}: $*"; }
error() { echo -e "${RED}error${NC}: $*" >&2; }
die()   { error "$@"; exit 1; }

detect_platform() {
  local os arch
  case "$(uname -s)" in
    Linux*)   os="unknown-linux-gnu" ;;
    Darwin*)  os="apple-darwin" ;;
    MINGW*|MSYS*|CYGWIN*) os="pc-windows-msvc" ;;
    *) die "unsupported OS: $(uname -s)" ;;
  esac
  case "$(uname -m)" in
    x86_64|amd64)  arch="x86_64" ;;
    aarch64|arm64) arch="aarch64" ;;
    *) die "unsupported architecture: $(uname -m)" ;;
  esac
  echo "${arch}-${os}"
}

get_latest_version() {
  local tag
  tag=$(curl -sL "$GITHUB_API/releases/latest" | grep '"tag_name"' | head -1 | sed -E 's/.*"tag_name":\s*"([^"]+)".*/\1/')
  [ -z "$tag" ] && die "failed to fetch latest release from GitHub"
  echo "$tag"
}

main() {
  echo -e "${BOLD}phinbox installer${NC}"
  echo ""

  local target
  target=$(detect_platform)
  info "detected platform: $target"

  if [ "$VERSION" = "latest" ]; then
    VERSION=$(get_latest_version)
  fi
  info "version: $VERSION"

  local ext="tar.gz"
  [[ "$target" == *"windows"* ]] && ext="zip"

  local archive_name="phinbox-${VERSION}-${target}.${ext}"
  local download_url="https://github.com/$REPO/releases/download/${VERSION}/${archive_name}"

  info "downloading $archive_name ..."
  mkdir -p "$INSTALL_DIR"

  local tmp_dir
  tmp_dir=$(mktemp -d)
  trap 'rm -rf "$tmp_dir"' EXIT

  curl -fSL --progress-bar "$download_url" -o "$tmp_dir/$archive_name" \
    || die "download failed — check that $VERSION exists at $download_url"

  # Verify checksum
  local checksum_url="${download_url}.sha256"
  if curl -fsSL "$checksum_url" -o "$tmp_dir/$archive_name.sha256" 2>/dev/null; then
    info "verifying checksum ..."
    (cd "$tmp_dir" && sha256sum -c "$archive_name.sha256" 2>/dev/null || shasum -a 256 -c "$archive_name.sha256" 2>/dev/null) \
      || warn "checksum verification failed — proceeding anyway"
  else
    warn "no checksum file found — skipping verification"
  fi

  info "extracting to $INSTALL_DIR ..."
  if [[ "$ext" == "tar.gz" ]]; then
    tar -xzf "$tmp_dir/$archive_name" -C "$INSTALL_DIR"
  elif [[ "$ext" == "zip" ]]; then
    unzip -o "$tmp_dir/$archive_name" -d "$INSTALL_DIR"
  fi

  chmod +x "$INSTALL_DIR/phinbox" "$INSTALL_DIR/phinbox-mcp" 2>/dev/null || true

  local path_ok=false
  IFS=: read -ra PATH_DIRS <<< "$PATH"
  for dir in "${PATH_DIRS[@]}"; do
    [ "$dir" = "$INSTALL_DIR" ] && path_ok=true && break
  done

  echo ""
  echo -e "${GREEN}${BOLD}installed successfully!${NC}"
  echo "  binaries: $INSTALL_DIR"
  for bin in "${BINARY_NAMES[@]}"; do
    echo "    - $INSTALL_DIR/$bin"
  done

  if [ "$path_ok" = false ]; then
    echo ""
    echo -e "${YELLOW}add to your PATH:${NC}"
    case "$(uname -s)" in
      Darwin*) echo "  echo 'export PATH=\"\$HOME/.phinbox/bin:\$PATH\"' >> ~/.zshrc && source ~/.zshrc" ;;
      *)       echo "  echo 'export PATH=\"\$HOME/.phinbox/bin:\$PATH\"' >> ~/.bashrc && source ~/.bashrc" ;;
    esac
  fi

  echo ""
  echo -e "run ${BOLD}phinbox --help${NC} to get started"
}

main "$@"
