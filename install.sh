#!/bin/sh
# install.sh - put _nime where your shell can find it.
#
#   sh install.sh                      from a clone
#   curl -fsSL <raw url> | sh          without one
#
# It only copies files around. Nothing is installed system wide, nothing asks
# for a password, and nothing starts on its own later.

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

# say what is missing instead of letting it surprise anyone later
if [ -x "$dest/_nime" ]; then
	_missing=$("$dest/_nime" --check-deps 2>/dev/null | sed -n 's/^  absent   /  missing: /p')
	if [ -n "$_missing" ]; then
		printf 'optional programs not found:\n%s\n' "$_missing"
	fi
fi

printf 'start it with: _nime\n'