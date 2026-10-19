# screenshot

A region screenshot to the clipboard on X11 with one key, built from three small C tools: [xregion](https://github.com/r3clusionn/xregion) selects a rectangle or a window, `grab` captures it as a PNG at any X depth (10-bit included), and `xclip` puts it on the clipboard and hands it to the program you paste into. Together they are about 59 KB and need only libX11 and zlib, where hacksaw, shotgun and xclip needed two Rust programs from an overlay and four extra X libraries. This repo is the setup: an installer that builds the three from their repos, the key binding, and how the pieces fit together.

**Status:** in daily use on an HP OmniBook 7 with Gentoo, Xorg at depth 30 and dwm, on `Alt+Shift+S`, since October 2026.

![Terminal output on a black background. "ls -l" lists the three programs: ~/.local/bin/xregion at 21192 bytes, /usr/local/bin/grab at 16104 bytes and /usr/local/bin/xclip at 21544 bytes. "xregion -h" prints its usage: -f output format (%x %y %w %h, %g = %wx%h+%x+%y by default, %i = window id), -c line colour (default #7f7f7f), -t rectangle line thickness (default 2), -g guide line thickness (default 1), -n no guide lines. "grab -h" prints "usage: grab [-g WxH+X+Y] FILE|-" and "xclip -h" prints "usage: xclip [-i|-o] [-selection primary|secondary|clipboard] [-t type] [-f] [-r] [file...]".](docs/images/terminal.png)

## Features

- **One key:** drag a rectangle, or click a window, and the PNG is on the clipboard. Esc or the right button cancels, and nothing is copied.
- **Clean pictures:** the selection lines are drawn outside the selected area and removed before the capture, so they are never in the screenshot.
- **Any X depth:** grab converts whatever pixel format X uses to 8 bits per channel, so it works at depth 30, where shotgun writes empty files.
- **Big images paste:** xclip answers `TARGETS` with `image/png` and sends large images in pieces (the ICCCM INCR protocol), so a full 2880x1800 screenshot pastes into browsers, chat programs and image editors.
- **A file instead of the clipboard:** `grab` writes a PNG file when given a name.

| Tool | What it does | Replaces | Source |
|---|---|---|---|
| `xregion` | prints the selected geometry, `WxH+X+Y` | hacksaw | [xregion](https://github.com/r3clusionn/xregion) |
| `grab` | that region of the screen as PNG, to a file or stdout | shotgun | [scripts](https://github.com/r3clusionn/scripts), `bin/grab.c` |
| `xclip` | stdin to a selection and serves it; `-o` prints a selection | xclip, libXmu, libXt, libSM, libICE | [scripts](https://github.com/r3clusionn/scripts), `bin/xclip.c` |

## How to install

Requires git, make, a C compiler, and libX11 and zlib with their headers.

```sh
git clone https://github.com/r3clusionn/screenshot
cd screenshot
sh install.sh                    # to ~/.local/bin
doas sh install.sh /usr/local    # or for everyone
```

Then bind the command to a key. In dwm's `config.h`:

```c
{ MODKEY|ShiftMask, XK_s, spawn, SHCMD("g=$(xregion) && grab -g \"$g\" - | xclip -selection clipboard -t image/png") },
```

The same command works from any window manager's key bindings; in sxhkd, for example:

```
super + shift + s
	g=$(xregion) && grab -g "$g" - | xclip -selection clipboard -t image/png
```

## How to use

```sh
g=$(xregion) && grab -g "$g" - | xclip -selection clipboard -t image/png   # region to the clipboard (the key)
g=$(xregion) && grab -g "$g" ~/shot.png                                      # region to a file
grab - | xclip -selection clipboard -t image/png                             # whole screen to the clipboard
xclip -o -selection clipboard -t TARGETS                                     # what the clipboard holds
```

## How it works

1. **xregion** grabs the pointer and keyboard and draws the guides and the rectangle as plain X windows in the root visual. On release it destroys them and waits for the X server before it prints the geometry, so the capture that follows can't see them. It exits 1 when cancelled, so `&&` stops the pipeline there.
2. **grab** reads the root window with `XGetImage` in strips of 64 rows, converts each pixel through the visual's channel masks to 8 bits per channel and writes an RGB PNG with zlib. Strips because X (glamor) reads the screen back through a GPU buffer the size of the request, and mesa keeps that buffer cached: one full-screen request used to leave about 20 MiB in the X server until it exited.
3. **xclip** reads the PNG from stdin, takes the CLIPBOARD selection and stays in the background to answer paste requests: `TARGETS` (the types it offers), the type it was given, and INCR transfers for data larger than one X request. It exits when another program takes the clipboard.

## Measurements

| | This setup | Before |
|---|---|---|
| Selection | `xregion`, 21 KB | hacksaw 1.0.4, 821 KB (Rust) |
| Capture | `grab`, 16 KB | shotgun 2.5.1, 709 KB (Rust) |
| Clipboard | `xclip`, 21 KB | xclip, which needs libXmu, libXt, libSM and libICE |
| Packages it adds to an X system | 0 (libX11 and zlib are already there) | 7: hacksaw and shotgun (from an overlay), xclip and its four libraries |

## Verification

- On the laptop (Xorg at depth 30, dwm), through the binding above: a dragged region pasted into another program was exactly that region, with no selection lines in it; a click on a window gave that window without dwm's border; Esc and the right button copied nothing.
- Terminal apps that paste images read them through this `xclip` (`-t TARGETS -o`, then `-t image/png -o`).
- `install.sh` built all three into an empty prefix from the GitHub repos (2026-10-19).

## Limits

- X11 only.
- No editing, arrows or delay timer: a PNG of the region and nothing more.
- The clipboard copy lives in the `xclip` process, as with any X clipboard: it is gone if that process is killed before you paste.

## License

MIT (see `LICENSE`).
