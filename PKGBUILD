# Maintainer: DEXTER <dexter@example.com>

# This is a VCS package, so we use a -git suffix.
# See: https://wiki.archlinux.org/title/VCS_package_guidelines
_pkgname=arduino-cli-manager
pkgname=${_pkgname}-git

pkgver() {
  cd "$_pkgname"
  printf "r%s.%s" "$(git rev-list --count HEAD)" "$(git rev-parse --short HEAD)"
}

pkgrel=1
pkgdesc="A powerful interactive shell script to manage Arduino CLI projects"
arch=('any')
url="https://github.com/abod8639/${_pkgname}"
license=('MIT')
depends=('bash' 'arduino-cli')
optdepends=(
  'fzf: for enhanced interactive menus'
  'jq: for update notifications'
)
provides=("${_pkgname}")
conflicts=("${_pkgname}")
source=("${_pkgname}::git+https://github.com/abod8639/${_pkgname}.git")
sha256sums=('SKIP')

package() {
  cd "${srcdir}/${_pkgname}"
  
  # Install the main script
  install -Dm755 "arduino-cli-manager.sh" "${pkgdir}/usr/bin/${_pkgname}"
  
  # Install documentation and license
  install -Dm644 "README.md" "${pkgdir}/usr/share/doc/${pkgname}/README.md"
  install -Dm644 "LICENSE" "${pkgdir}/usr/share/licenses/${pkgname}/LICENSE"
}