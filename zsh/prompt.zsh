# Foreglow Custom — powerline-style zsh prompt.
# Sourced from ~/.zshrc; reads the active theme from $FOREGLOW_HOME/config.

setopt PROMPT_SUBST

# Redraw once a second while sitting idle at the prompt, so the clock
# segment keeps ticking instead of only updating after each command.
TMOUT=1
TRAPALRM() {
  zle && zle reset-prompt
}

: "${FOREGLOW_HOME:=$HOME/.config/foreglow-custom}"
THEME="foreglow"
[ -f "$FOREGLOW_HOME/config" ] && source "$FOREGLOW_HOME/config"

source "$FOREGLOW_HOME/lib/weekday_glyphs.sh"
source "$FOREGLOW_HOME/themes/${THEME}.theme.sh"

# Powerline arrow separator. Needs a patched/Nerd Font to render as a solid
# triangle — see the README if it shows as a box or question mark instead.
FOREGLOW_SEP=$''
FOREGLOW_PROMPT_CHAR='❯'

_foreglow_git_branch() {
  git symbolic-ref --short HEAD 2>/dev/null || git rev-parse --short HEAD 2>/dev/null
}

_foreglow_git_dirty() {
  [ -n "$(git status --porcelain 2>/dev/null)" ]
}

# Each segment is drawn with its own background held open; the separator
# glyph between two segments is printed with fg = the segment being left and
# bg = the segment being entered, which is what makes the triangles look
# seamlessly cut into the next block of color instead of floating in a gap.
foreglow_build_prompt() {
  local out branch git_bg prev_bg

  out="%K{$KEYWORD}%F{$BACKGROUND}%B ✤ %n@%m %b"
  prev_bg="$KEYWORD"

  out+="%K{$CURRENT_LINE}%F{$prev_bg}${FOREGLOW_SEP}%F{$FOREGROUND} %~ "
  prev_bg="$CURRENT_LINE"

  branch="$(_foreglow_git_branch)"
  if [ -n "$branch" ]; then
    if _foreglow_git_dirty; then
      git_bg="$WARNING"
    else
      git_bg="$SUCCESS"
    fi
    out+="%K{$git_bg}%F{$prev_bg}${FOREGLOW_SEP}%F{$BACKGROUND}  $branch "
    prev_bg="$git_bg"
  fi

  out+="%K{$BORDER}%F{$prev_bg}${FOREGLOW_SEP}%F{$FOREGROUND_DIM} $(weekday_glyph) %D{%H:%M:%S} "
  out+="%k%F{$BORDER}${FOREGLOW_SEP}%f "
  out+="%F{$CURSOR}${FOREGLOW_PROMPT_CHAR}%f "

  printf '%s' "$out"
}

PROMPT='$(foreglow_build_prompt)'
RPROMPT=''
