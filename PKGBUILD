developer="http://indiecomputing.com/"
url="http://ubos.net/"
maintainer=$developer
pkgname=macrobuild
pkgver=0.35
pkgrel=1
pkgdesc="Build framework for large, 'macro' tasks"
arch=('any')
license=('GPL')
depends=('perl')
options=('!strip')

package() {
    for d in Macrobuild Macrobuild/BasicTasks Macrobuild/CompositeTasks; do
        mkdir -p $pkgdir/usr/lib/perl5/vendor_perl/$d
        install -m644 $startdir/vendor_perl/$d/*.pm $pkgdir/usr/lib/perl5/vendor_perl/$d
    done
    mkdir -p $pkgdir/usr/bin
    install -m755 $startdir/bin/macrobuild $pkgdir/usr/bin/
}
