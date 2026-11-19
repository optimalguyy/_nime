# `_nime`

Watch anime in your terminal. Search for a show, pick an episode from a list, and
it resolves the stream and hands it to your player. One POSIX shell script, no
account, no config, no daemon.

> **This is a personal project.** It scrapes third party sites. Read
> [disclaimer.md](disclaimer.md) before using it.

## Install

One line, whichever system you are on. It installs `_nime` **and** the programs it
uses — the menu (`fzf`), the player (`mpv`), downloads (`yt-dlp`, `ffmpeg`) — through
your own package manager, asking for a password only if it has to. It puts
`~/.local/bin` on your `PATH` itself (`~/.profile`, `~/.bashrc` or `~/.zshrc`,
whichever your shell reads) and finishes by printing a check of what is in place,
so nothing has to be guessed afterwards. Open a new terminal once it is done.

No `curl`? `wget -qO- https://raw.githubusercontent.com/optimalguyy/_nime/master/install.sh | sh`

**Linux, macOS, Termux**

```sh
curl -fsSL https://raw.githubusercontent.com/optimalguyy/_nime/master/install.sh | sh
```

**Windows** — PowerShell, nothing needs to be installed first

```powershell
irm https://raw.githubusercontent.com/optimalguyy/_nime/master/install.ps1 | iex
```

**Arch, CachyOS, Manjaro, EndeavourOS** — pacman owns the files instead

```sh
git clone https://github.com/optimalguyy/_nime.git && cd _nime && makepkg -si
```

Then:

```sh
_nime                        # search for a show
_nime -d cyberpunk           # download it instead of playing
_nime -e 1-3 -d cyberpunk    # three episodes at once
```

On Windows, open a new terminal first so the `PATH` change applies, and start it
with `nime` rather than `_nime`.

`_nime --check-deps` says what is installed and what is missing. `_nime -U`
updates, `_nime -h` lists every flag.

## What you need

The installers above handle this. If you would rather do it yourself:

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
the subtitle URL and the required referer, so you can paste them anywhere.

The script itself never touches your system. Only the one-line installer installs
anything, and only what is missing.

### Packages per system

**Debian, Ubuntu, Mint, Pop!_OS**

```sh
apt install curl openssl mpv fzf python3 yt-dlp ffmpeg
```

**Fedora**

```sh
dnf install curl openssl python3 fzf yt-dlp ffmpeg-free
```

`mpv` and the full `ffmpeg` live in [RPM Fusion](https://rpmfusion.org) on Fedora
older than 40:

```sh
dnf install https://download1.rpmfusion.org/free/fedora/rpmfusion-free-release-$(rpm -E %fedora).noarch.rpm
dnf install mpv ffmpeg --allowerasing
```

The installer above does this much for you and tells you exactly what is left if
a repository is missing.

**openSUSE**

```sh
zypper install curl openssl mpv fzf python3 yt-dlp ffmpeg
```

**macOS** (with [Homebrew](https://brew.sh))

```sh
brew install mpv fzf python3 yt-dlp ffmpeg
```

`brew install --cask iina` adds IINA, which is used in place of mpv when it is
installed.

**Windows without the installer** ([Git for Windows](https://git-scm.com/download/win),
with [Scoop](https://scoop.sh))

```sh
scoop install mpv fzf python yt-dlp ffmpeg
```

**Windows, WSL2** — use the Debian line *inside* WSL and install a Linux player
there too; `mpv.exe` on the Windows side is not reachable from inside it.

**Android, Termux** ([F-Droid](https://f-droid.org/packages/com.termux/))

```sh
pkg install curl openssl-tool mpv fzf python python-yt-dlp ffmpeg termux-am
```

`openssl-tool` is the one that matters there: the package called `openssl` holds
only the library, and `_nime` needs the command to decrypt the stream links.

`pkg install` needs no root and no `sudo` on Termux, and the installer above uses
it that way.

If `pkg install` answers "Unable to locate package" on a phone that was just set
up, check where Termux came from: the Play Store build was abandoned in 2020 and
its package repositories no longer resolve, so nothing installs in it. The build
that works is the F-Droid one linked above. The installer prints the package
manager's own message when a package fails, and says this when the repository
itself is the problem, instead of leaving you with a list of things that are
still missing and no reason why.

**VLC is the recommended player on Android.** It handles these streams as they
are; a phone's gallery or stock video player does not, and answers with
"Can't play this video".

```sh
# from F-Droid, Play Store or https://www.videolan.org/vlc/download-android.html
```

If VLC is installed, the episode goes straight into VLC. These streams answer
`403` to anything that does not send the site's referrer, and the VLC app accepts
no headers at all — so `_nime` starts a small proxy in the session, which fetches
the playlist and every segment with the referrer the site wants, and hands VLC a
local address to play. The proxy keeps running while VLC is in front, and one
wake lock keeps the session alive for it.

If VLC is not installed, `_nime` **opens the Google Play page for it** (named by
package, so another store cannot take the link) and tells you the one command to
run afterwards:

```sh
_nime -c -S 1     # the episode you were on, straight into VLC
```

`-c` takes it from your history and `-S 1` picks the newest entry without a menu
prompt, so nothing is searched or chosen again. The gallery, the stock video
player and the browser are never handed the stream. `_nime --check-deps` says
whether VLC is there or the store will be opened.

`termux-setup-storage` gives `_nime` the shared `Downloads` folder; without it
downloads land in the Termux home.

**iOS, iSH** (App Store)

```sh
apk add git curl openssl
```

There is no player inside iSH, so `_nime` opens the stream in **VLC for iOS** when
it can, and otherwise prints two tappable links: the App Store page for VLC and
the `vlc://` link that plays the episode once it is installed.
[VLC for iOS](https://apps.apple.com/app/vlc-for-mobile/id650377962) is the
player to have there.

### Doing it by hand

The two files are all there is:

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
cp _nime _nime-dl /usr/local/bin/
cp _nime.1 /usr/local/share/man/man1/
mandb
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

### Remove

One command takes it all back out: the two scripts, a `yt-dlp` copy the
installer fetched, the man page, the `PATH` lines the installer added, the watch
history and the cache.

```sh
curl -fsSL https://raw.githubusercontent.com/optimalguyy/_nime/master/uninstall.sh | sh
```

Downloaded episodes are kept unless you say otherwise — `--all` removes the
`_nime downloads` folder as well, and `--keep-history` leaves what you were
watching in place:

```sh
curl -fsSL https://raw.githubusercontent.com/optimalguyy/_nime/master/uninstall.sh | sh -s -- --all
curl -fsSL https://raw.githubusercontent.com/optimalguyy/_nime/master/uninstall.sh | sh -s -- --keep-history
```

From a clone, `sh uninstall.sh`. It prints every file it removed and ends with
the one command that removes the programs the installer installed (`fzf`, `mpv`,
`ffmpeg`, `yt-dlp`); those are left alone, because something else on the machine
may be using them. Nothing of `_nime` runs in the background or is registered
anywhere, so there is nothing else to stop or disable.

If it was installed as a package instead, that is the package manager's job:

```sh
sudo pacman -Rns _nime          # Arch, from the PKGBUILD
```

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
on a different show. The sources are checked in turn, and an episode is only ever
played from the dubbed stream: a source that has the show but not the dub of that
episode is skipped rather than quietly handed over as subbed. When no source has
the dub, `_nime` says so and names what it would take:

```
No sources found for episode 3: no English dub for it (the dub may not be out yet; --sub plays the original audio)
```

A stream can hold every audio language as a rendition of one file, and the
original language is usually the one it marks as the default. A player follows
that default, so a dubbed URL could still come out Japanese. `_nime` reads the
renditions: an English one is what plays, and it is made the only and default
one on the way to the player. mpv and VLC are told the language too.

A source with no dub for an episode can still answer the dubbed URL, with no
English rendition or with the subbed file itself. The subbed stream of the same
episode is resolved and compared by media id (so the same file on a different
host still counts as the same file); a match means no dub there, and the other
source is tried instead, without printing anything about it.

The other source is searched for the same series, not for a show whose title
happens to start the same way, so a lookup that lands on a different season or a
different series is refused instead of playing someone else's episodes.

There is no quiet switch to the original audio: asking for the dub and getting
Japanese is not a thing `_nime` does, not even when no source has the dub of the
show at all. Add `--sub` to ask for subs from the start.

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

The download folder is the first of these, and it is created if it is not there
yet, so there is nothing to pick and nothing lands in your home directory by
accident:

1. `_NIME_DOWNLOAD_DIR`, if you set it,
2. the XDG download dir from `~/.config/user-dirs.dirs`,
3. `~/Downloads` (made if it does not exist),
4. `~/Download`, then `~/Desktop`,
5. your home directory, only if none of the above can be created.

On Android that is `/storage/emulated/0/Download/_nime downloads`, once
`termux-setup-storage` has given Termux the shared storage.

Downloads use the audio you asked for — the dubbed track by default, the
original one with `--sub` — so a downloaded file sounds like the version you
picked, not whichever track the stream lists first.

Episodes are fetched as several pieces at once rather than one at a time, which
on a typical connection is most of the difference between a two minute download
and a four minute one. If a server starts refusing that many requests, the
download carries on over a single connection rather than failing.

Ctrl+C stops the whole run, even halfway through a range, rather than finishing
the episode and moving on to the next one.

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
