#!/bin/sh
# install.sh - put _nime where your shell can find it, with everything it uses.
#
#   sh install.sh                      from a clone
#   curl -fsSL <raw url> | sh          without one
#   wget -qO- <raw url> | sh           when curl is the one thing missing
#
# It copies the files into your home directory and installs whatever _nime needs
# that is missing, through your own package manager. Nothing starts on its own
# later. Set _NIME_NO_DEPS=1 to skip the dependency step, _NIME_DEST to change
# where the scripts go.

set -e

repo="https://raw.githubusercontent.com/optimalguyy/_nime/master"
dest="${_NIME_DEST:-${HOME}/.local/bin}"
tmp=""

cleanup() {
	if [ -n "$tmp" ]; then
		rm -rf "$tmp"
	fi
}
trap cleanup EXIT HUP INT TERM

# the files sit next to this script, unless it arrived through a pipe
src=$(CDPATH='' cd -- "$(dirname -- "$0")" 2>/dev/null && pwd) || src=""
if [ -z "$src" ] || [ ! -f "$src/_nime" ]; then
	if ! command -v curl >/dev/null 2>&1; then
		printf 'install.sh: curl is needed to download _nime.\n' >&2
		printf 'With wget instead:\n\n  wget -qO- %s/install.sh | sh\n' "$repo" >&2
		exit 1
	fi
	tmp=$(mktemp -d 2>/dev/null || mktemp -d -t nime) || exit 1
	src=$tmp
	for _f in _nime _nime-dl _nime.1; do
		curl -fsSL "$repo/$_f" -o "$src/$_f" || {
			printf 'install.sh: could not download %s\n' "$_f" >&2
			exit 1
		}
	done
fi

[ -f "$src/_nime-dl" ] || cp "$src/_nime" "$src/_nime-dl" 2>/dev/null || true

mkdir -p "$dest" || {
	printf 'install.sh: cannot create %s\n' "$dest" >&2
	exit 1
}
cp "$src/_nime" "$src/_nime-dl" "$dest/" || exit 1
chmod +x "$dest/_nime" "$dest/_nime-dl"

# the man page, where it can be written without a password
mandir="${_NIME_MAN_DIR:-${HOME}/.local/share/man/man1}"
if [ -f "$src/_nime.1" ] && mkdir -p "$mandir" 2>/dev/null; then
	cp "$src/_nime.1" "$mandir/" 2>/dev/null || true
fi

printf 'installed in %s\n' "$dest"

# the shell has to find it afterwards, so the directory goes on the PATH here
# rather than in a line to copy by hand: Termux and a fresh home put nothing in
# ~/.local/bin, and `_nime` was simply "command not found" after installing
path_rc=""
case ":${PATH}:" in
	*":${dest}:"*) ;;
	*)
		case "$(basename "${SHELL:-sh}" 2>/dev/null)" in
			fish)
				path_rc="${XDG_CONFIG_HOME:-$HOME/.config}/fish/config.fish"
				mkdir -p "$(dirname "$path_rc")" 2>/dev/null
				if ! grep -qF "fish_add_path $dest" "$path_rc" 2>/dev/null; then
					printf '\nfish_add_path %s\n' "$dest" >>"$path_rc"
				fi
				;;
			zsh)
				# zsh reads neither .profile nor .bashrc
				if ! grep -qF "$dest" "$HOME/.zshrc" 2>/dev/null; then
					printf '\nexport PATH="%s:$PATH"\n' "$dest" >>"$HOME/.zshrc"
				fi
				path_rc="$HOME/.zshrc"
				;;
			*)
				# .profile for login shells, .bashrc for the terminal that is open
				# now: bash reads the second, plain sh the first
				for _rc in "$HOME/.profile" "$HOME/.bashrc"; do
					grep -qF "$dest" "$_rc" 2>/dev/null && continue
					{
						[ -f "$_rc" ] || printf '# created by the _nime installer\n'
						printf '\nexport PATH="%s:$PATH"\n' "$dest"
					} >>"$_rc" 2>/dev/null
					path_rc="${path_rc:-$_rc}"
				done
				;;
		esac
		;;
esac

# ---------------------------------------------------------------------------
# dependencies
# ---------------------------------------------------------------------------
# curl for every request, sed/grep/awk for reading the pages, openssl for the
# stream payload, fzf for the menus, mpv for playing, python3 so a second
# episode replaces the first instead of opening another window, yt-dlp and
# ffmpeg for downloads
tools="curl openssl fzf mpv python3 yt-dlp ffmpeg"

# which package manager, and through it the name each program has there
pm=""
if { [ -n "${TERMUX_VERSION:-}" ] || [ -n "${ANDROID_ROOT:-}" ]; } && command -v pkg >/dev/null 2>&1; then
	pm=termux
	tools="$tools termux-am"
elif command -v pacman >/dev/null 2>&1; then
	pm=pacman
elif command -v apt-get >/dev/null 2>&1; then
	pm=apt
elif command -v dnf >/dev/null 2>&1; then
	pm=dnf
elif command -v zypper >/dev/null 2>&1; then
	pm=zypper
elif command -v apk >/dev/null 2>&1; then
	pm=apk
elif command -v brew >/dev/null 2>&1; then
	pm=brew
	tools="fzf mpv python3 yt-dlp ffmpeg"
fi

# there is no player inside iSH, so asking for one there would only fail; the
# stream url and a vlc:// link are what it gets instead
case "$(uname -a 2>/dev/null)" in
	*iSH* | *ISH*) tools="curl openssl fzf" ;;
esac

# the package that carries a program, on this system
pkg_for() {
	case "$pm:$1" in
		termux:python3) printf 'python' ;;
		termux:yt-dlp) printf 'python-yt-dlp' ;;
		# the package called openssl holds the library, the command is a second one
		termux:openssl) printf 'openssl-tool' ;;
		pacman:python3) printf 'python' ;;
		brew:python3) printf 'python' ;;
		brew:openssl) printf 'openssl@3' ;;
		dnf:ffmpeg) printf 'ffmpeg-free' ;;
		*) printf '%s' "$1" ;;
	esac
}

missing=""
for _t in $tools; do
	command -v "$_t" >/dev/null 2>&1 || missing="$missing $(pkg_for "$_t")"
done

if [ -z "$missing" ]; then
	printf 'everything _nime uses is already installed\n'
elif [ "${_NIME_NO_DEPS:-0}" = 1 ]; then
	printf 'skipped installing:%s\n' "$missing"
else
	# certificates are not a program, but every https request needs them
	case "$pm" in
		pacman | apt | dnf | zypper | apk | termux) missing="$missing ca-certificates" ;;
	esac

	if [ -z "$pm" ]; then
		printf '\nNo package manager found. Install these yourself:%s\n' "$missing"
		missing_howto="yes"
	elif [ "$pm" = brew ]; then
		printf 'installing:%s (brew)\n' "$missing"
		# shellcheck disable=SC2086
		brew install $missing || true
	else
		# pkg in Termux installs into the app's own prefix as the app user: it
		# needs no root and there is no sudo to give it
		if [ "$pm" = termux ]; then
			privileged=""
		elif [ "$(id -u)" = 0 ]; then
			privileged=""
		elif command -v sudo >/dev/null 2>&1; then
			privileged="sudo"
		else
			privileged=""
		fi

		# `curl | sh` hands the script to stdin, so sudo has nowhere to ask for
		# the password unless it is pointed at the terminal
		ask=0
		if [ "$pm" != termux ] && [ "$privileged" = sudo ] && ! sudo -n true 2>/dev/null; then
			if ( : </dev/tty ) 2>/dev/null; then
				ask=1
			else
				privileged=""
			fi
		fi

		case "$pm" in
			termux) base="pkg install -y" ;;
			pacman) base="pacman -S --needed --noconfirm" ;;
			apt) base="apt-get install -y" ;;
			dnf) base="dnf install -y" ;;
			zypper) base="zypper install -y" ;;
			apk) base="apk add" ;;
			*) base="$pm install -y" ;;
		esac

		# pkg needs no password, so Termux never lands in this branch
		if [ -z "$privileged" ] && [ "$(id -u)" != 0 ] && [ "$pm" != termux ]; then
			printf '\nInstalling these needs a password, run:\n\n  sudo %s%s\n' "$base" "$missing"
			missing_howto="yes"
		else
			# a package run that was killed half way leaves dpkg waiting to finish
			# it, and until it does every install fails with "dpkg was interrupted"
			if [ "$pm" = termux ] && command -v dpkg >/dev/null 2>&1; then
				if dpkg --audit 2>/dev/null | grep -q .; then
					printf 'finishing an interrupted package run first\n'
					dpkg --configure -a >/dev/null 2>&1 || true
				fi
			fi
			# a device that has never fetched the package lists cannot resolve any
			# name, and "Unable to locate package" on a fresh install is that more
			# often than anything else. Termux says yes to its own mirror question
			# with -y, and the first update after a new install is the slow one
			case "$pm" in
				termux)
					printf 'updating the package lists (%s)\n' "$pm"
					if ! _up=$($privileged pkg update -y 2>&1); then
						# kept, because this is the run that explains a broken Termux
						printf 'updating the package lists failed:\n'
						printf '%s\n' "$_up" |
							grep -iE 'error|E:|unable|signature|unsigned|denied|resolve' | tail -n 4 || true
					fi
					;;
				apt) $privileged apt-get update -qq || true ;;
			esac
			printf 'installing:%s (%s)\n' "$missing" "$pm"
			if [ "$ask" = 1 ]; then
				$privileged $base $missing </dev/tty || true
			else
				$privileged $base $missing || true
			fi

			# one unknown name aborts the whole list on apt and dnf, so every
			# program that is still missing is tried on its own afterwards, and
			# what the package manager said is kept: "still missing" with no reason
			# is the one message that cannot be acted on
			for _t in $tools; do
				command -v "$_t" >/dev/null 2>&1 && continue
				_p=$(pkg_for "$_t")
				printf '  %s alone (%s)\n' "$_p" "$pm"
				if [ "$ask" = 1 ]; then
					_err=$($privileged $base "$_p" </dev/tty 2>&1) || true
				else
					_err=$($privileged $base "$_p" 2>&1) || true
				fi
				command -v "$_t" >/dev/null 2>&1 && continue
				_err=$(printf '%s\n' "$_err" |
					grep -iE 'error|E:|unable|not found|no such|invalid|fail|denied' | tail -n 2 || true)
				if [ -n "$_err" ]; then
					printf '  %s\n' "$_err"
				fi
			done

			# the one program a package is missing for on some releases. it is
			# pure python, so pip can put it in the destination on the PATH
			if [ "$pm" = termux ] && ! command -v yt-dlp >/dev/null 2>&1 && [ ! -x "$dest/yt-dlp" ]; then
				_py=""
				command -v python3 >/dev/null 2>&1 && _py=python3
				[ -z "$_py" ] && command -v python >/dev/null 2>&1 && _py=python
				if [ -n "$_py" ]; then
					printf '  yt-dlp alone (pip)\n'
					$_py -m pip install --user -q yt-dlp >/dev/null 2>&1 ||
						$_py -m pip install --user -q --break-system-packages yt-dlp >/dev/null 2>&1 || true
				fi
			fi
		fi
	fi

	# yt-dlp is the one download that is a single self-contained file, so it can
	# be had even where no package carries it. it is built against glibc, so it
	# is no use on the two systems that build everything against musl
	if ! command -v yt-dlp >/dev/null 2>&1 && [ ! -x "$dest/yt-dlp" ] &&
		command -v curl >/dev/null 2>&1; then
		case "$(uname -s 2>/dev/null)" in
			Darwin) _yb=yt-dlp_macos ;;
			Linux)
				# plain yt-dlp is a python zipapp and runs anywhere python3 does;
				# yt-dlp_linux is built against glibc, no use on Alpine or Android
				if command -v python3 >/dev/null 2>&1; then
					_yb=yt-dlp
				elif [ "$pm" = apk ] || [ "$pm" = termux ]; then
					_yb=""
				else
					_yb=yt-dlp_linux
				fi
				;;
			*) _yb="" ;;
		esac
		if [ -n "$_yb" ]; then
			printf 'fetching yt-dlp (stand-alone build)\n'
			if curl -fsSL "https://github.com/yt-dlp/yt-dlp/releases/latest/download/$_yb" \
				-o "$dest/yt-dlp" 2>/dev/null; then
				chmod +x "$dest/yt-dlp"
			else
				rm -f "$dest/yt-dlp"
			fi
		fi
	fi
fi

# what is still not there, with the exact command that would fix it. a program
# that landed in the destination counts too: $dest may just not be on the PATH
# of this shell yet
left=""
for _t in $tools; do
	command -v "$_t" >/dev/null 2>&1 && continue
	[ -x "$dest/$_t" ] && continue
	left="$left $_t"
done

if [ -n "$left" ]; then
	printf '\nStill missing:%s\n' "$left"
	case "$pm" in
		termux)
			# the player on Android is an app, not the package of the same name
			printf '\nOn Android the player is an app, which pkg cannot install. VLC is the\n'
			printf 'one that plays these streams, from the Play Store:\n'
			printf '  https://play.google.com/store/apps/details?id=org.videolan.vlc\n'
			# the other reason pkg installs nothing is the app it is running in:
			# the Play Store build was abandoned in 2020 and its packages are gone
			printf '\nIf pkg could not install the rest, check where Termux came from. The\n'
			printf 'Play Store build has been abandoned since 2020 and installs nothing;\n'
			printf 'the one that works is from F-Droid:\n'
			printf '  https://f-droid.org/packages/com.termux/\n'
			;;
		dnf)
			printf '\nmpv and the full ffmpeg live in RPM Fusion on older Fedora:\n\n'
			printf '  sudo dnf install https://download1.rpmfusion.org/free/fedora/rpmfusion-free-release-$(rpm -E %%fedora).noarch.rpm\n'
			printf '  sudo dnf install mpv ffmpeg --allowerasing\n'
			;;
		"")
			printf '\nInstall them with your system packages, then run _nime again.\n'
			;;
		*)
			[ "$missing_howto" = yes ] || printf '\nInstall them with your package manager, then run _nime again.\n'
			;;
	esac
	printf '\nWithout fzf the menus are numbered prompts, without mpv the stream URL\nis printed instead of played, and without yt-dlp the downloads are skipped.\n'
fi

if [ -x "$dest/_nime" ]; then
	printf '\n'
	# stdin belongs to this script when it arrived through a pipe, and the check
	# must not read the rest of it away
	"$dest/_nime" --check-deps </dev/null 2>/dev/null || true
fi

case "$pm" in
	termux)
		# downloads and the player app both reach into shared storage, and the
		# player is an app: the command line mpv pkg installs is not what Android
		# hands a stream to
		printf '\nOn Android, termux-setup-storage gives _nime the shared Downloads folder.\n'
		printf 'The player is an app: VLC, from the Play Store.\n'
		printf 'https://play.google.com/store/apps/details?id=org.videolan.vlc\n'
		;;
esac

if [ -n "$path_rc" ]; then
	# said either way: a second run finds the line already there and appends nothing
	printf '\n%s is on your PATH through %s.\n' "$dest" "$path_rc"
	printf 'Open a new terminal (or run: . %s), then:\n\n  _nime\n' "$path_rc"
else
	printf '\nstart it with: _nime\n'
fi
