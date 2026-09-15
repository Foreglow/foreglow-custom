#!/usr/bin/env bash
#
# install.sh — sets up zsh and Vim/Neovim with the Foreglow Custom
# powerline prompt/statusline, for one of the four Foreglow variants.
#
# Usage: ./install.sh [foreglow|afterglow|airglow|alpenglow]
#        (omit to pick interactively)

set -euo pipefail

REPO_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
INSTALL_DIR="${FOREGLOW_HOME:-$HOME/.config/foreglow-custom}"
THEMES=(foreglow afterglow airglow alpenglow)

is_valid_theme() {
  for known in "${THEMES[@]}"; do
    [[ "$1" == "$known" ]] && return 0
  done
  return 1
}

choose_theme() {
  echo "Which glow?"
  local i=1
  for t in "${THEMES[@]}"; do
    printf '  %d) %s\n' "$i" "${t^}"
    i=$((i + 1))
  done
  local choice
  while true; do
    read -rp "> " choice
    if [[ "$choice" =~ ^[1-4]$ ]]; then
      THEME="${THEMES[$((choice - 1))]}"
      return
    fi
  done
}

ensure_zsh() {
  command -v zsh >/dev/null 2>&1 && return
  read -rp "zsh isn't installed. Install it? [y/N] " ans
  [[ "$ans" =~ ^[Yy]$ ]] || { echo "zsh is required. Aborting." >&2; exit 1; }

  if command -v apt-get >/dev/null 2>&1; then
    sudo apt-get update && sudo apt-get install -y zsh
  elif command -v pacman >/dev/null 2>&1; then
    sudo pacman -S --noconfirm zsh
  elif command -v dnf >/dev/null 2>&1; then
    sudo dnf install -y zsh
  elif command -v brew >/dev/null 2>&1; then
    brew install zsh
  else
    echo "No package manager found — install zsh manually and re-run." >&2
    exit 1
  fi
}

ensure_powerline_font() {
  fc-list 2>/dev/null | grep -qi "nerd font" && return

  echo "Segment separators need a font with those glyphs baked in — a"
  echo "fontconfig fallback alone won't render them in most terminals."
  read -rp "Install 'UbuntuMono Nerd Font Mono'? [y/N] " ans
  [[ "$ans" =~ ^[Yy]$ ]] || return 0
  command -v unzip >/dev/null 2>&1 || { echo "Need 'unzip'. Skipping." >&2; return; }

  local fonts_dir="$HOME/.local/share/fonts"
  local zip_url="https://github.com/ryanoasis/nerd-fonts/releases/latest/download/UbuntuMono.zip"
  local tmp; tmp="$(mktemp -d)"
  mkdir -p "$fonts_dir"

  if command -v curl >/dev/null 2>&1; then
    curl -fsSL "$zip_url" -o "$tmp/f.zip" || { echo "Download failed." >&2; rm -rf "$tmp"; return; }
  elif command -v wget >/dev/null 2>&1; then
    wget -q "$zip_url" -O "$tmp/f.zip" || { echo "Download failed." >&2; rm -rf "$tmp"; return; }
  else
    echo "Need curl or wget. Skipping." >&2; rm -rf "$tmp"; return
  fi

  if ! unzip -o -q "$tmp/f.zip" \
      "UbuntuMonoNerdFontMono-Regular.ttf" "UbuntuMonoNerdFontMono-Bold.ttf" \
      "UbuntuMonoNerdFontMono-Italic.ttf" "UbuntuMonoNerdFontMono-BoldItalic.ttf" \
      -d "$tmp/x"; then
    echo "Couldn't extract the font. Skipping." >&2; rm -rf "$tmp"; return
  fi

  cp "$tmp"/x/UbuntuMonoNerdFontMono-*.ttf "$fonts_dir/"
  rm -rf "$tmp"
  command -v fc-cache >/dev/null 2>&1 && fc-cache -f "$fonts_dir" >/dev/null 2>&1
  echo "Installed 'UbuntuMono Nerd Font Mono'."

  if [ -n "${GNOME_TERMINAL_SCREEN:-}" ] && command -v dconf >/dev/null 2>&1 && command -v gsettings >/dev/null 2>&1; then
    read -rp "Set it as this GNOME Terminal profile's font? [y/N] " ans2
    if [[ "$ans2" =~ ^[Yy]$ ]]; then
      local uuid path
      uuid="$(gsettings get org.gnome.Terminal.ProfilesList default | tr -d "'")"
      path="/org/gnome/terminal/legacy/profiles:/:$uuid/"
      dconf write "${path}use-system-font" false
      dconf write "${path}font" "'UbuntuMono Nerd Font Mono 11'"
    fi
  else
    echo "Set your terminal's font to 'UbuntuMono Nerd Font Mono' to see it."
  fi
}

install_files() {
  mkdir -p "$INSTALL_DIR"
  cp -r "$REPO_DIR/lib" "$REPO_DIR/themes" "$REPO_DIR/zsh" "$REPO_DIR/vim" "$INSTALL_DIR/"
  echo "THEME=\"$THEME\"" > "$INSTALL_DIR/config"
}

# Replaces its own managed block on re-run instead of duplicating it, and
# backs up the target file first.
patch_rc() {
  local rc="$1" start="$2" end="$3" body="$4"
  touch "$rc"
  if grep -qF "$start" "$rc"; then
    local tmp; tmp="$(mktemp)"
    awk -v s="$start" -v e="$end" '$0==s{skip=1} !skip{print} $0==e{skip=0}' "$rc" > "$tmp"
    mv "$tmp" "$rc"
  fi
  cp "$rc" "$rc.bak.$(date +%Y%m%d%H%M%S)"
  { echo "$start"; printf '%s\n' "$body"; echo "$end"; } >> "$rc"
}

patch_zshrc() {
  patch_rc "$HOME/.zshrc" "# >>> foreglow-custom >>>" "# <<< foreglow-custom <<<" \
    "export FOREGLOW_HOME=\"$INSTALL_DIR\"
source \"\$FOREGLOW_HOME/zsh/prompt.zsh\""
}

patch_vimrc() {
  local body
  body="let g:foreglow_home = '$INSTALL_DIR'
let g:foreglow_theme = '$THEME'
if has('termguicolors')
  set termguicolors
endif
execute 'source ' . g:foreglow_home . '/vim/statusline.vim'"

  patch_rc "$HOME/.vimrc" '" >>> foreglow-custom >>>' '" <<< foreglow-custom <<<' "$body"

  if command -v nvim >/dev/null 2>&1; then
    mkdir -p "$HOME/.config/nvim"
    patch_rc "$HOME/.config/nvim/init.vim" '" >>> foreglow-custom >>>' '" <<< foreglow-custom <<<' "$body"
  fi
}

offer_default_shell() {
  local zsh_path; zsh_path="$(command -v zsh)"
  [ "${SHELL:-}" = "$zsh_path" ] && return
  read -rp "Set zsh as your default shell? [y/N] " ans
  if [[ "$ans" =~ ^[Yy]$ ]]; then
    chsh -s "$zsh_path"
  fi
}

main() {
  cat "$REPO_DIR/assets/logo.txt"
  echo

  THEME="${1:-}"
  if [ -n "$THEME" ] && ! is_valid_theme "$THEME"; then
    echo "Unknown theme: $THEME (choose one of: ${THEMES[*]})" >&2
    exit 1
  fi
  [ -z "$THEME" ] && choose_theme

  # shellcheck disable=SC1090
  source "$REPO_DIR/themes/${THEME}.theme.sh"

  ensure_zsh
  ensure_powerline_font
  install_files
  patch_zshrc
  patch_vimrc
  offer_default_shell

  echo
  echo "$THEME_LABEL installed -> $INSTALL_DIR"
  echo "zsh: exec zsh   |   vim/nvim: just open it"
  echo "Switch anytime: ./install.sh <theme>"
}

main "$@"
