#!/bin/sh
# install.sh - put _nime where your shell can find it.
#
#   sh install.sh                      from a clone
#   curl -fsSL <raw url> | sh          without one
#
# It copies files into your home directory and installs whatever _nime needs
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
		echo "install.sh: curl is needed to download _nime" >&2
		exit 1
	fi
	tmp=$(mktemp -d 2>/dev/null || mktemp -d -t nime) || exit 1
	src=$tmp
	for _f in _nime _nime-dl _nime.1; do
		curl -fsSL "$repo/$_f" -o "$src/$_f" || {
			echo "install.sh: could not download $_f" >&2
			exit 1
		}
	done
fi

mkdir -p "$dest" || {
	echo "install.sh: cannot create $dest" >&2
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

case ":${PATH}:" in
	*":${dest}:"*) ;;
	*)
		printf '\n%s is not on your PATH yet, add it once:\n\n' "$dest"
		printf '  bash:  echo '\''export PATH="%s:$PATH"'\'' >> ~/.bashrc\n' "$dest"
		printf '  zsh:   echo '\''export PATH="%s:$PATH"'\'' >> ~/.zshrc\n' "$dest"
		printf '  fish:  fish_add_path %s\n' "$dest"
		printf '\n'
		;;
esac

# ---------------------------------------------------------------------------
# dependencies: a picker, a player, and the two programs downloads are made with
# ---------------------------------------------------------------------------
want="fzf mpv yt-dlp ffmpeg python3 openssl"

missing=""
for _d in $want; do
	command -v "$_d" >/dev/null 2>&1 || missing="$missing $_d"
done

if [ -z "$missing" ]; then
	printf 'everything _nime uses is already installed\n'
elif [ "${_NIME_NO_DEPS:-0}" = 1 ]; then
	printf 'skipped installing:%s\n' "$missing"
else
	# the names are the same package names everywhere except on a Mac, where
	# brew and the menu program live in their own formulas
	if [ -n "${TERMUX_VERSION:-}" ] && command -v pkg >/dev/null 2>&1; then
		pm="install"; pm_quiet="-y"
	elif command -v pacman >/dev/null 2>&1; then
		pm="pacman"; pm_quiet="--needed --noconfirm"
	elif command -v apt-get >/dev/null 2>&1; then
		pm="apt-get"; pm_quiet="install -y"
	elif command -v dnf >/dev/null 2>&1; then
		pm="dnf"; pm_quiet="install -y"
	elif command -v zypper >/dev/null 2>&1; then
		pm="zypper"; pm_quiet="install -y"
	elif command -v apk >/dev/null 2>&1; then
		pm="apk"; pm_quiet="add"
	elif command -v brew >/dev/null 2>&1; then
		pm="brew"; pm_quiet="install"
	else
		pm=""
	fi

	if [ -z "$pm" ]; then
		printf '\nNo package manager found. Install these yourself:%s\n' "$missing"
	elif [ "$pm" = brew ]; then
		printf 'installing:%s (brew)\n' "$missing"
		for _p in fzf mpv yt-dlp ffmpeg python openssl@3; do
			case "$missing " in
				*" ${_p%@*} "*) brew install "$_p" || true ;;
			esac
		done
		printf 'done\n'
	else
		pkgs="$missing"

		if [ "$(id -u)" = 0 ]; then
			privileged=""
		elif command -v sudo >/dev/null 2>&1; then
			privileged="sudo"
		else
			privileged=""
		fi

		# `curl | sh` hands the script to stdin, so sudo has nowhere to ask for
		# the password unless it is pointed at the terminal
		ask=0
		if [ "$privileged" = sudo ] && ! sudo -n true 2>/dev/null; then
			if ( : </dev/tty ) 2>/dev/null; then
				ask=1
			elif [ -z "$privileged" ]; then
				ask=-1
			else
				ask=-1
			fi
		fi

		if [ "$ask" = -1 ]; then
			printf '\nInstalling these needs a password, run:\n\n  sudo %s %s%s\n' \
				"$pm" "$pm_quiet" "$pkgs"
		elif [ -z "$privileged" ] && [ "$(id -u)" != 0 ]; then
			printf '\nNo sudo here, install these yourself:\n\n  %s %s%s\n' "$pm" "$pm_quiet" "$pkgs"
		else
			printf 'installing:%s (%s)\n' "$pkgs" "$pm"
			[ "$pm" = apt-get ] && { $privileged apt-get update -qq || true; }
			if [ "$ask" = 1 ]; then
				$privileged "$pm" $pm_quiet $pkgs </dev/tty
			else
				$privileged "$pm" $pm_quiet $pkgs
			fi && printf 'done\n' ||
				printf '\nCould not install:%s\nInstall them with:\n\n  sudo %s %s%s\n' \
					"$pkgs" "$pm" "$pm_quiet" "$pkgs"
		fi
	fi
fi

printf 'start it with: _nime\n'
