#!/bin/sh
# uninstall.sh - take _nime back out, and everything it put there for itself.
#
#   curl -fsSL https://raw.githubusercontent.com/optimalguyy/_nime/master/uninstall.sh | sh
#   curl -fsSL <same> | sh -s -- --all             also the downloaded episodes
#   curl -fsSL <same> | sh -s -- --keep-history    keep what you were watching
#   sh uninstall.sh -y                            from a clone, no questions
#
# It removes the two scripts, a yt-dlp copy the installer fetched, the man page,
# the PATH lines the installer added and the history and cache. The packages the
# installer installed (fzf, mpv, ffmpeg, yt-dlp) are left alone, because
# something else on the machine may be using them: the last lines print the one
# command that removes those as well. Set _NIME_DEST to match an install that
# went somewhere other than ~/.local/bin.

set -e

# Termux installs its own programs in $PREFIX/bin, and that is where the
# installer puts the scripts there
if [ -n "${_NIME_DEST:-}" ]; then
	dest=$_NIME_DEST
elif [ -n "${PREFIX:-}" ] && [ -e "${PREFIX}/bin/_nime" ]; then
	dest="${PREFIX}/bin"
else
	dest="${HOME}/.local/bin"
fi
mandir="${_NIME_MAN_DIR:-${HOME}/.local/share/man/man1}"
histdir="${_NIME_HIST_DIR:-${XDG_STATE_HOME:-$HOME/.local/state}/_nime}"
cachedir="${XDG_CACHE_HOME:-$HOME/.cache}/_nime"

all=0
keep_hist=0
assume_yes=0

say() {
	printf '%s\n' "$*"
}

usage() {
	cat <<'EOF'
usage: uninstall.sh [-y] [--all] [--keep-history]

  -y, --yes       do not ask anything, take the defaults
  --all           remove the downloaded episodes too (_nime downloads)
  --keep-history  leave the watch history alone
  -h, --help      this

The scripts, the man page, the PATH lines and the history go either way.
EOF
}

for _arg in "$@"; do
	case "$_arg" in
		-y | --yes) assume_yes=1 ;;
		--all) all=1 ;;
		--keep-history) keep_hist=1 ;;
		-h | --help)
			usage
			exit 0
			;;
		*)
			printf 'uninstall.sh: unknown option: %s\n' "$_arg" >&2
			usage >&2
			exit 1
			;;
	esac
done

# the script arrives through a pipe, so stdin is the rest of it: a question has
# to be asked on the terminal, and with no terminal the answer is the default
ask() {
	if [ "$assume_yes" = 1 ]; then
		return 1
	fi
	if ( : </dev/tty ) 2>/dev/null; then
		printf '%s [y/N] ' "$1" >/dev/tty
		read -r _ans </dev/tty || return 1
		case "$_ans" in
			y | Y | yes | YES) return 0 ;;
		esac
	fi
	return 1
}

drop() {
	[ -e "$1" ] || return 0
	if rm -rf "$1" 2>/dev/null; then
		say "removed $1"
	else
		say "could not remove $1"
	fi
}

# the episodes, found where they would be rather than guessed from a config.
# one per line, because "_nime downloads" has a space in it
dl_found=""
for _b in /storage/emulated/0/Download "$HOME/Downloads" "$HOME/Download" "$HOME/Desktop" "$HOME/desktop" "$HOME"; do
	[ -d "$_b/_nime downloads" ] || continue
	dl_found="$dl_found$_b/_nime downloads
"
done

say "Removing _nime:"
say ""

drop "$dest/_nime"
drop "$dest/_nime-dl"
drop "$dest/_nime.bak"
# the same files in the other place an install may have left them
drop "${HOME}/.local/bin/_nime"
drop "${HOME}/.local/bin/_nime-dl"
drop "${HOME}/.local/bin/_nime.bak"
# a stand-alone yt-dlp the installer fetched lands in the same directory; a
# yt-dlp from a package manager is somewhere else and is not touched
drop "$dest/yt-dlp"
drop "${HOME}/.local/bin/yt-dlp"
drop "$mandir/_nime.1"

# the PATH lines, by their exact text so nothing else in the file goes
strip_rc() {
	_rc=$1
	[ -f "$_rc" ] || return 0
	_new="$_rc.nime-uninstall.$$"
	# grep exits 1 when every line was one of ours, which is not a failure here
	grep -vF -e "export PATH=\"$dest:\$PATH\"" -e "fish_add_path $dest" \
		-e "# created by the _nime installer" "$_rc" >"$_new" 2>/dev/null
	if [ "$?" -le 1 ] && [ -f "$_new" ]; then
		_before=$(wc -l <"$_rc" 2>/dev/null || echo 0)
		_after=$(wc -l <"$_new" 2>/dev/null || echo 0)
		if [ "$_before" -eq "$_after" ]; then
			rm -f "$_new"
			return 0
		fi
		# a file the installer created itself goes entirely, rather than
		# staying behind as an empty one
		if grep -q '[^[:space:]]' "$_new" 2>/dev/null; then
			mv "$_new" "$_rc"
			say "removed the PATH line from $_rc"
		else
			rm -f "$_new" "$_rc"
			say "removed $_rc (the installer had created it)"
		fi
	else
		rm -f "$_new"
	fi
}

strip_rc "$HOME/.profile"
strip_rc "$HOME/.bashrc"
strip_rc "$HOME/.zshrc"
strip_rc "${XDG_CONFIG_HOME:-$HOME/.config}/fish/config.fish"

if [ "$keep_hist" = 1 ]; then
	if [ -d "$histdir" ]; then
		say "kept $histdir"
	fi
else
	drop "$histdir"
fi
drop "$cachedir"

if [ -n "$dl_found" ]; then
	printf '%s' "$dl_found" | while IFS= read -r _d; do
		[ -n "$_d" ] || continue
		if [ "$all" = 1 ] || ask "Delete the downloaded episodes in $_d?"; then
			drop "$_d"
		else
			say "kept $_d"
		fi
	done
fi

# an install that did not come from this script: a package, or system wide
for _p in /usr/local/bin/_nime /usr/bin/_nime "${PREFIX:-/usr}/bin/_nime"; do
	[ -e "$_p" ] || continue
	case "$_p" in
		"$dest/_nime") continue ;;
	esac
	say ""
	say "$_p is still there; it belongs to something else, remove it with:"
	say "  rm $_p"
done

say ""
say "The scripts are gone. What is left are the programs the installer installed,"
say "because something else on the machine may use them too. To remove those:"
if [ -n "${TERMUX_VERSION:-}" ] || [ -n "${ANDROID_ROOT:-}" ]; then
	say "  pkg uninstall fzf mpv ffmpeg python python-yt-dlp termux-am"
elif command -v pacman >/dev/null 2>&1; then
	say "  sudo pacman -Rns fzf mpv ffmpeg yt-dlp python"
elif command -v apt-get >/dev/null 2>&1; then
	say "  sudo apt remove fzf mpv ffmpeg yt-dlp python3"
elif command -v dnf >/dev/null 2>&1; then
	say "  sudo dnf remove fzf mpv ffmpeg yt-dlp python3"
elif command -v zypper >/dev/null 2>&1; then
	say "  sudo zypper remove fzf mpv ffmpeg yt-dlp python3"
elif command -v apk >/dev/null 2>&1; then
	say "  sudo apk del fzf mpv ffmpeg yt-dlp python3"
elif command -v brew >/dev/null 2>&1; then
	say "  brew uninstall fzf mpv ffmpeg yt-dlp python"
else
	say "  nothing to do by hand: no package manager was found"
fi
