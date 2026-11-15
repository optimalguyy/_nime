# `_nime`

`_nime` is a terminal client for watching anime. Search for a show, pick an
episode from a list, and it resolves the stream and hands it to your player.
It reads the sources it is built around, talks to their player directly —
including the encrypted stream payload — and runs as a single POSIX shell
script with no runtime, no build step and no installer.

Everything happens in the terminal: you search, you pick an anime and an
episode from a list, and the stream is handed to a local player. Every source it
knows is searched at once and the answers are merged into one list, so there is
nothing to choose up front. Only titles that match what you typed are listed,
and music videos or shows that have not aired yet are left out. The list runs
oldest first with the release year next to each title, so the series you should
start with is at the top. Nothing is installed, no account is needed and no
daemon runs in the background.

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
| `python3` | keeping one player window, see below |
| `termux-am` | `am` intents on Android |

**No player?** `_nime` still resolves the episode and prints the stream URL,
the subtitle URL and the required referer, so you can paste them anywhere. It
never installs anything for you.

## Install

One line, on any system:

```sh
curl -fsSL https://raw.githubusercontent.com/optimalguyy/_nime/master/install.sh | sh
```

That copies `_nime` and `_nime-dl` into `~/.local/bin`, adds the folder to your
shell's `PATH` if it is not there yet, installs the man page, and prints
anything still missing. Run it again later to update, or use `_nime -U`.

### Arch, CachyOS, Manjaro, EndeavourOS

The repository carries a `PKGBUILD`, so pacman can own the files:

```sh
git clone https://github.com/optimalguyy/_nime.git
cd _nime
makepkg -si
```

It builds the package and installs `_nime`, `_nime-dl` and the man page into
`/usr`, pulling `curl` and `openssl` with it.

### Packages on other systems

The script itself needs only `curl` and `openssl`; a player and a menu make it
pleasant. One line per system:

**Debian, Ubuntu, Mint, Pop!_OS**

```sh
sudo apt install curl openssl mpv fzf python3 yt-dlp ffmpeg
```

**Fedora**

```sh
sudo dnf install curl openssl mpv fzf python3 yt-dlp ffmpeg
```

**openSUSE**

```sh
sudo zypper install curl openssl mpv fzf python3 yt-dlp ffmpeg
```

**macOS** (with [Homebrew](https://brew.sh))

```sh
brew install mpv fzf python3 yt-dlp ffmpeg
```

`brew install --cask iina` adds IINA, which is used in place of mpv when it is
installed.

**Windows, Git Bash** ([Git for Windows](https://git-scm.com/download/win), with
[Scoop](https://scoop.sh))

```sh
scoop install mpv fzf python yt-dlp ffmpeg
```

**Windows, WSL2** — use the Debian line *inside* WSL and install a Linux player
there too; `mpv.exe` on the Windows side is not reachable from inside it.

**Android, Termux** ([F-Droid](https://f-droid.org/packages/com.termux/))

```sh
pkg install git curl openssl mpv fzf python termux-am
pkg install yt-dlp ffmpeg      # only needed for downloads
```

Install the mpv app from F-Droid as well: `_nime` hands the stream over to it.
VLC works too, with `_nime -v`.

**iOS, iSH** (App Store)

```sh
apk add git curl openssl
```

There is no player inside iSH, so `_nime` prints a tappable `vlc://` link —
install VLC from the App Store and tap it.

### Doing it by hand

If you would rather not run a script, the two files are all there is:

```sh
git clone https://github.com/optimalguyy/_nime.git
cd _nime
mkdir -p ~/.local/bin
cp _nime _nime-dl ~/.local/bin/
chmod +x ~/.local/bin/_nime ~/.local/bin/_nime-dl
```

`~/.local/bin` is on the `PATH` on most Linux desktops. If the command is not
found afterwards, add it once, for your shell:

```sh
# bash
echo 'export PATH="$HOME/.local/bin:$PATH"' >> ~/.bashrc

# zsh
echo 'export PATH="$HOME/.local/bin:$PATH"' >> ~/.zshrc

# fish
fish_add_path ~/.local/bin
```

On **Windows Git Bash** use `~/bin` instead:

```sh
mkdir -p ~/bin
cp _nime _nime-dl ~/bin/
echo 'export PATH="$HOME/bin:$PATH"' >> ~/.bashrc
```

System wide, for every user on the machine, with the man page:

```sh
sudo cp _nime _nime-dl /usr/local/bin/
sudo cp _nime.1 /usr/local/share/man/man1/
sudo mandb
```

### Check it

```sh
_nime --check-deps
_nime -V
```

The first lists every dependency as `ok` or `absent`, so nothing has to be
guessed. The second prints the version.

### Update

```sh
_nime -U
```

That downloads the newest copy, compares the version line, and replaces the
installed file while keeping the old one next to it as `_nime.bak`.

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
No dub here, looking for one...
Found it dubbed: <title>
```

The switch only happens when the title actually matches, so it never lands you
on a different show. The sources are checked in turn: when one has no dub for a
show, the other is looked at before falling back to subs. If no source has a
dub, it says so and plays the subbed version. Add `--sub` to ask for subs from
the start.

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

### Seasons

A series is usually split into one entry per season. `_nime` looks up every
season of the show you picked and puts all of its episodes in a single list, so
you never have to search for "season 2" yourself:

```
2 seasons, 38 episodes
1) S1 E1
2) S1 E2
...
29) S2 E1
```

Numbering runs straight through the seasons, so ranges and `-e` work the same
way they always did:

```sh
_nime "<title>" -e 30        # episode 30 overall, whichever season that lands in
_nime-dl "<title>" -e 1-40   # the whole run
```

### One window

`next`, `previous`, `select` and `replay` load the episode into the player
window that is already open instead of opening a second one, and quitting the
menu closes it. The player is handed a control socket for this, which needs
`python3`; without it every episode simply gets its own window.

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

`_nime -d` keeps everything in one place: a `_nime downloads` folder inside the
folder your desktop calls downloads, a folder per series inside that, and the
episodes in it.

```
~/Downloads/_nime downloads/Cyberpunk_ Edgerunners/E1.mp4
~/Downloads/_nime downloads/Cyberpunk_ Edgerunners/E2.mp4
```

The download folder is the first of these that exists, so there is nothing to
pick:

1. `_NIME_DOWNLOAD_DIR`, if you set it,
2. the XDG download dir from `~/.config/user-dirs.dirs`,
3. `~/Downloads`,
4. `~/Desktop`,
5. your home directory.

On Android that is `/storage/emulated/0/Download/_nime downloads`.

Downloads use the audio you asked for — the dubbed track by default, the
original one with `--sub` — so a downloaded file sounds like the version you
picked, not whichever track the stream lists first.

Episodes are fetched as several pieces at once rather than one at a time, which
on a typical connection is most of the difference between a two minute download
and a four minute one. If a server starts refusing that many requests, the
download carries on over a single connection rather than failing.

While an episode downloads you get one line that updates in place — a bar, the
percentage, the speed and the time left — and if a download fails it says why
instead of just stopping.

Downloads are `.mp4` with the subtitles **muxed into the file** as a soft track,
so they travel with the video: every normal player (mpv, VLC, QuickTime, IINA,
the Android players, most TVs) lists the track under its subtitle menu and you
switch languages there. No sidecar `.srt` to keep in sync, and the track is
marked default so players turn it on by themselves.

If `ffmpeg` is missing, the subtitles cannot be embedded and are saved next to
the video as `<title>_E<episode>.en.vtt` instead.

```sh
_nime -d -e 1-3 "<title>"     # three files in _nime downloads/<title>/
```

### Subtitle languages

Subtitles are off unless you ask for them — an episode plays clean, and `-subs`
turns them on. A source usually offers a dozen tracks: Arabic, English, French,
German, Italian, Portuguese, Russian, Spanish, sometimes regional variants. Look
at what an episode has:

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

Pick one with `-subs` for the default track, or by language, which also turns
them on:

```sh
_nime-dl "<title>" -e 1 -gersub   # German subtitles only
_nime "<title>" -spasub           # play with Spanish subtitles
_nime-dl "<title>" -e 1 -allsub   # embed every track
```

Every language has its own flag: `-engsub`, `-gersub`, `-fresub`, `-spasub`,
`-itasub`, `-porsub`, `-rusub`, `-arasub`, and `-allsub` for all of them.
They are short for `--sub-lang <code>`, which also takes a full name
(`--sub-lang german`) and `all`.

Without the flag you get the track the source marks as default, which is
English here. With `--sub-lang all` every track is muxed in and flagged
`default` on the one you would otherwise have got, so the player's subtitle menu
shows all languages. If you ask for a language an episode does not have, `_nime`
says so, lists what is available, and falls back to the default rather than
failing.

## Options

| flag | meaning |
| --- | --- |
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
| `-engsub` `-gersub` `-spasub` `-fresub` `-itasub` `-porsub` `-rusub` `-arasub` | subtitles in that language, short for `--sub-lang` |
| `-allsub` | every subtitle track, short for `--sub-lang all` |
| `-subs, --subs` | show subtitles; off unless a subtitle flag is given |
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
| `_NIME_MODE` | `dub` (default) or `sub` |
| `_NIME_QUALITY` | default quality |
| `_NIME_PLAYER` | player command to use |
| `_NIME_PLAYER_FLAGS` | extra flags for the player |
| `_NIME_MENU` | `fzf` (default) or `none` |
| `_NIME_HIST_DIR` | history directory |
| `_NIME_DOWNLOAD_DIR` | the downloads folder itself (default: your downloads folder) |
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
