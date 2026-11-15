# `_nime`

`_nime` is a terminal client for watching anime. Search for a show, pick an
episode from a list, and it resolves the stream and hands it to your player.
It reads [animesuge.cz](https://animesuge.cz) and
[anichan.to](https://anichan.to), talks to their player directly — including
the encrypted stream payload — and runs as a single POSIX shell script with no
runtime, no build step and no installer.

Everything happens in the terminal: you search, you pick an anime and an
episode from a list, and the stream is handed to a local player. Nothing is
installed, no account is needed and no daemon runs in the background.

> **This is a personal project.** It scrapes third party sites. Read
> [disclaimer.md](disclaimer.md) before using it.

## Dependencies

`_nime` checks these itself with `_nime --check-deps`.

**Required**

| program | why |
| --- | --- |
| `curl` | every request |
| `openssl` | decrypting the stream payload |
| `sed`, `grep`, `awk` | parsing |

These ship with every base install of Debian, Ubuntu, Fedora, Arch, Alpine,
macOS and Termux, so a fresh system already has them.

**Optional**

| program | why |
| --- | --- |
| `fzf` | fuzzy menu. Without it `_nime` falls back to a numbered prompt |
| `mpv` | the preferred player |
| `vlc` | alternative player |
| `yt-dlp` / `ffmpeg` | `--download` |
| `syncplay` | `--syncplay` |
| `termux-am` | `am` intents on Android |

**No player?** `_nime` still resolves the episode and prints the stream URL,
the subtitle URL and the required referer, so you can paste them anywhere. It
never installs anything for you.

## Install

`_nime` is one script, and `_nime-dl` is a two-line wrapper around it. Put both
anywhere on your `PATH`.

```sh
git clone https://github.com/USERNAME/_nime.git
cd _nime
mkdir -p ~/.local/bin
cp _nime _nime-dl ~/.local/bin/
chmod +x ~/.local/bin/_nime ~/.local/bin/_nime-dl
```

Make sure `~/.local/bin` is on your `PATH`:

```sh
# add to ~/.bashrc or ~/.zshrc
export PATH="$HOME/.local/bin:$PATH"
```

For a system wide install, use `/usr/local/bin` instead:

```sh
sudo cp _nime _nime-dl /usr/local/bin/
```

The man page is optional:

```sh
sudo cp _nime.1 /usr/local/share/man/man1/
sudo mandb
```

### Update

```sh
_nime -U
```

That fetches `_nime` from this repository, compares the version line, and
replaces the installed copy while keeping the old one as `_nime.bak`. Set
`repo_user` at the top of the script to your GitHub username once, or export
`_NIME_USER` / `_NIME_BRANCH`.

## Commands

One command per job, so you never have to remember a flag:

| command | what it does |
| --- | --- |
| `_nime` | browse and play |
| `_nime-dl` | same menus, but saves the episode |

```sh
_nime                       # search prompt, then play
_nime "<title>"             # play
_nime "<title>" -e 3        # play episode 3
_nime-dl "<title>"          # download
_nime-dl "<title>" -e 1-5   # download episodes 1 to 5
```

`_nime-dl` is the same program with `--download` already set, so every option
below works in both.

## Usage

```sh
_nime                    # opens a search prompt
_nime [options] [query]
_nime-dl [options] [query]
```

Typing `_nime` on its own gives you a search bar: type a title, press enter, and
the anime list appears. Or pass the name directly:

```sh
_nime "<title>"
```

Pick from the menu:

```sh
_nime "<title>"
```

The progress lines it prints while it works (`Searching...`, `Resolving episode
2...`, `Stream ready`) are erased once the player has the stream, so your
terminal is left as it was.

Dubs are the default. If the source you picked has no dub for that show,
`_nime` checks the other source and switches to whichever one has it:

```
No dub here, checking anichan...
Switched to anichan: <title, as the other site spells it> (dubbed)
```

The switch only happens when the title actually matches, so it never lands you
on a different show. If no source has a dub, it says so and plays the subbed version. Add `--sub` to ask for subs from the start.

Each audio language has its own flag: `-engdub`, `-gerdub`, `-spadub`,
`-fredub`, `-itadub`, `-pordub`, `-rusdub` and `-aradub`. Only English dubs are
served by the sources `_nime` can read, so `-gerdub` and the rest stop with a
message that says exactly that, instead of playing the wrong audio.

```sh
_nime --sub "<title>"
```

Continue where you left off:

```sh
_nime -c
```

A specific episode, or a range:

```sh
_nime -e 5 "<title>"
_nime -e 1-3 "<title>"
```

The other source:

```sh
_nime -s anichan "<title>"
```

Skip openings and endings automatically:

```sh
_nime --skip "<title>"
```

Watch together with someone else:

```sh
_nime --syncplay "<title>"
```

Download instead of playing:

```sh
_nime -d -e 1-3 "<title>"
```

## Downloads

`_nime -d` writes into a folder called `_nime downloads`, inside whichever
folder your system calls downloads:

1. `_NIME_DOWNLOAD_DIR`, if you set it,
2. the XDG download dir from `~/.config/user-dirs.dirs`,
3. `~/Downloads`,
4. `~/Desktop`,
5. your home directory.

On Android that is `/storage/emulated/0/Download/_nime downloads`. The folder is
created if it does not exist, and every file is named
`<title>_E<episode>.mp4`.

Downloads are `.mp4` with the subtitles **muxed into the file** as a soft track,
so they travel with the video: every normal player (mpv, VLC, QuickTime, IINA,
the Android players, most TVs) lists the track under its subtitle menu and you
switch languages there. No sidecar `.srt` to keep in sync, and the track is
marked default so players turn it on by themselves.

If `ffmpeg` is missing, the subtitles cannot be embedded and are saved next to
the video as `<title>_E<episode>.en.vtt` instead.

```sh
_nime -d -e 1-3 "<title>"     # three files in ~/Downloads/_nime downloads
```

### Subtitle languages

A source usually offers a dozen tracks: Arabic, English, French, German,
Italian, Portuguese, Russian, Spanish, sometimes regional variants. Look at what
an episode has:

```sh
_nime --list-subs -e 1 "<title>"
```

```
Subtitles for episode 1:
  ara  Arabic
  eng  English                            (default)
  fre  French
  ger  German
  ...
```

Then pick one, either by language code or by name:

```sh
_nime -d -e 1 --sub-lang ger "<title>"    # German only
_nime -d -e 1 --sub-lang german "<title>" # same thing
_nime --sub-lang spa "<title>"            # play with Spanish subtitles
_nime -d -e 1 --sub-lang all "<title>"    # embed all nine tracks
```

Without the flag you get the track the source marks as default, which is
English here. With `--sub-lang all` every track is muxed in and flagged
`default` on the one you would otherwise have got, so the player's subtitle menu
shows all languages. If you ask for a language an episode does not have, `_nime`
says so, lists what is available, and falls back to the default rather than
failing.

## Options

| flag | meaning |
| --- | --- |
| `-s, --source <name>` | `animesuge` (default) or `anichan` |
| `-c, --continue` | continue from history |
| `-d, --download` | download instead of playing |
| `-D, --delete` | delete history |
| `-e, --episode <n>` | episode, or a range like `1-3` |
| `-r, --range <n>` | same as `--episode` |
| `-q, --quality <q>` | `best`, `worst`, `1080`, `720`, ... |
| `-S, --select-nth <n>` | pick the nth entry without a menu |
| `-v, --vlc` | use VLC |
| `--dub` | dubbed audio (**default**) |
| `-engdub` | English dub (same as `--dub`) |
| `-gerdub` `-spadub` `-fredub` `-itadub` `-pordub` `-rusdub` `-aradub` | that language's dub, when a source has one |
| `--sub` | subtitled instead of dubbed |
| `--skip` | skip intros and outros (mpv) |
| `--sub-lang <lang>` | subtitle language, as a code (`eng`, `ger`, `spa`) or a name (`german`); `all` embeds every track when downloading |
| `--list-subs` | list the subtitle tracks of an episode and exit |
| `--syncplay` | play through Syncplay |
| `--no-detach` | keep the player in the foreground |
| `--check-deps` | show the state of every dependency |
| `-U, --update` | update the script from git |
| `-V, --version` | version |
| `-h, --help` | help |

## Environment

| variable | meaning |
| --- | --- |
| `_NIME_SOURCE` | default source |
| `_NIME_MODE` | `dub` (default) or `sub` |
| `_NIME_QUALITY` | default quality |
| `_NIME_PLAYER` | player command to use |
| `_NIME_PLAYER_FLAGS` | extra flags for the player |
| `_NIME_MENU` | `fzf` (default) or `none` |
| `_NIME_HIST_DIR` | history directory |
| `_NIME_DOWNLOAD_DIR` | where downloads go (default: `<download folder>/_nime downloads`) |
| `_NIME_SKIP` | `1` to always skip intros and outros |
| `_NIME_SUB_LANG` | default subtitle language |
| `_NIME_COLOR` | `0` to disable colours |
| `_NIME_USER`, `_NIME_BRANCH` | repository used by `-U` |

## Players

| platform | order tried |
| --- | --- |
| Linux | `mpv`, flatpak `mpv`, `vlc` |
| macOS | `iina`, `mpv`, `vlc` |
| Windows (Git Bash / WSL) | `mpv.exe`, `vlc.exe` |
| Android / Termux | `mpv-android`, VLC, through `am` intents |
| iOS (iSH) | prints a tappable `vlc://` link |
| none | prints the stream url |

## How it works

1. The query goes to the source's search endpoint.
2. The anime page yields an internal id, which returns the episode list as
   sub/dub availability plus server ids.
3. The server list is walked until one returns a player url.
4. The player embeds an AES-256-CBC encrypted payload. `_nime` decrypts it with
   `openssl` and gets the master playlist plus the intro/outro marks.
5. The playlist is parsed, a quality is chosen, and the result is handed to the
   player with the referer the CDN expects.

There is no Python, no Node and no build step: `sh`, `curl` and `openssl`.

## FAQ

**Can I add another source?**
Yes. A source needs three functions: a search, an episode list and an embed
resolver. See `as_search`, `as_episode_maps` and `provider_embed`.

**The menu looks broken without fzf.**
Set `_NIME_MENU=none`, or install `fzf`. Without it you get a numbered list and
type a number.

**Playing fails / no sources found.**
The sites change their markup regularly. Run `_nime --check-deps`, then try the
other source with `-s`. If both fail, the endpoint probably moved and the
parsing needs an update.

**Subs are out of sync.**
Pass player flags through `_NIME_PLAYER_FLAGS`, for example
`_NIME_PLAYER_FLAGS="--sub-delay=0.5"`.

**Why is the file called `_nime` and not `nime`?**
The leading underscore keeps it out of the way in shell completion and makes it
obvious which command belongs to this project. Both spellings work if you
symlink `nime` to it.

## Contributing

See [CONTRIBUTING.md](CONTRIBUTING.md). Issues and pull requests are welcome.

## License

GPL-3.0, see [LICENSE](LICENSE).
