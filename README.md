<h3 align="center">Foreglow Custom</h3>

A powerline-style zsh prompt, built on the Foreglow color
family. One script sets up zsh (if you don't have it), wires
up both, and lets you pick which glow you're in the mood for.

## Installation

```bash
./install.sh            # picks interactively
./install.sh airglow    # or name one directly
```

It will:

- offer to install zsh via your package manager, if missing
- offer to install a font with powerline glyphs baked in, if missing (see below)
- copy the prompt/statusline engine to `~/.config/foreglow-custom`
- wire it into `~/.zshrc` and `~/.vimrc` (and `~/.config/nvim/init.vim` if
  present) via a marked block, backing up each file first
- offer to set zsh as your default shell

Re-run `./install.sh <theme>` any time to switch, which replaces its managed
block rather than duplicating it.

### Broken separator glyphs (boxes or `?` instead of triangles)

The `` between segments is a private-use-area codepoint (U+E0B0). It needs
a font with that glyph baked in directly. A fontconfig fallback rule is
**not** enough, because GNOME Terminal and most other VTE/Pango-based
terminals skip automatic font-fallback for private-use-area codepoints
outright, no matter what fallback rule is registered.

The installer offers to download [`UbuntuMono Nerd Font
Mono`](https://www.nerdfonts.com/) (a patched Ubuntu Mono: same look, plus
the glyphs) into `~/.local/share/fonts`, and if it detects GNOME Terminal,
offers to point your profile at it directly (`dconf`). This part actually
matters, since the glyph has to be *in the font your terminal renders
with*. On another terminal (Alacritty, kitty, iTerm, Windows Terminal),
install the font, then point that terminal's own font setting at
`UbuntuMono Nerd Font Mono` yourself.

## What you get

**zsh** — a segmented prompt:

```
 ✤ user@host  ~/path  main  Mon 12:34:56 ❯
```

user@host, path, git branch (shown only inside a repo: green clean, amber
dirty), and a weekday + time segment (plain three-letter day, see
[`lib/weekday_glyphs.sh`](lib/weekday_glyphs.sh) to change it).

**Vim/Neovim** — a statusline in the same spirit, with the classic
powerline touch of the mode segment changing color with the mode:

```
 NORMAL  file.rb  main                          ruby  42:8  67% 
```

Normal/Insert/Replace/Visual each get their own color (keyword/success/
error/warning from the active theme). Git branch is looked up once per
buffer/window switch, not on every keystroke — statuslines that shell out
on every redraw make the whole editor feel laggy.

Both read live from the same four palettes, so switching `./install.sh
<theme>` re-colors shell and editor together.

## Layout

```
foreglow-custom/
├── install.sh
├── lib/weekday_glyphs.sh
├── themes/
│   └── {foreglow,afterglow,airglow,alpenglow}.theme.{sh,vim}
├── zsh/prompt.zsh
└── vim/statusline.vim
```

## Color Palette

Same roles and hex values as the [tmux](../tmux) and
[base16-foreglow-scheme](../base16-foreglow-scheme) themes: see those
repos for the full per-theme tables.

## Requirements

- zsh, and Vim or Neovim (installer offers to install zsh; not vim)
- a truecolor terminal (24-bit `#rrggbb`) and GUI colors in Vim (`termguicolors`, set automatically)
- a font with powerline glyphs baked in (installer offers to install and wire one up)

## Uninstalling

Remove the marked block from `~/.zshrc` and `~/.vimrc` (and
`~/.config/nvim/init.vim`), then delete `~/.config/foreglow-custom`.
