developer="http://indiecomputing.com/"
url="http://ubos.net/"
maintainer=${developer}
pkgname=macrobuild
pkgver=0.39
pkgrel=1
pkgdesc="Build framework for large, 'macro' tasks"
arch=('any')
license=('GPL')
depends=('perl')
options=('!strip')
_vendor_perl=$(perl -V::vendorarch: | sed -e "s![' ]!!g")

package() {
    for d in Macrobuild Macrobuild/BasicTasks Macrobuild/CompositeTasks; do
        install -D -m644 ${startdir}/vendor_perl/$d/*.pm -t ${pkgdir}${_vendor_perl}/$d/
    done
    install -D -m755 ${startdir}/bin/macrobuild -t ${pkgdir}/usr/bin/
}
