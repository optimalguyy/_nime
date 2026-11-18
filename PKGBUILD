# Maintainer: optimalguyy <https://github.com/optimalguyy>
pkgname=_nime
pkgver=1.9.18
pkgrel=1
pkgdesc="Terminal client for watching anime"
arch=('any')
url="https://github.com/optimalguyy/_nime"
license=('GPL3')
# everything a fresh install needs to search, play and download, so the package
# is usable the moment pacman finishes with no extra steps
depends=(
	'curl'
	'openssl'
	'fzf'
	'mpv'
	'python'
	'yt-dlp'
	'ffmpeg'
)
optdepends=(
	'vlc: alternative player'
	'syncplay: --syncplay'
)
source=('_nime' '_nime-dl' '_nime.1' 'LICENSE')
sha256sums=('SKIP' 'SKIP' 'SKIP' 'SKIP')

package() {
	install -Dm755 _nime "$pkgdir/usr/bin/_nime"
	install -Dm755 _nime-dl "$pkgdir/usr/bin/_nime-dl"
	install -Dm644 _nime.1 "$pkgdir/usr/share/man/man1/_nime.1"
	install -Dm644 LICENSE "$pkgdir/usr/share/licenses/$pkgname/LICENSE"
}
