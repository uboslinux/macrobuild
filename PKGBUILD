developer="http://indiecomputing.com/"
url="http://ubos.net/"
maintainer=${developer}
pkgname=macrobuild
pkgver=0.40
pkgrel=1
pkgdesc="Build framework for large, 'macro' tasks"
arch=('any')
license=('GPL')
depends=('perl' 'ubos-perl-utils')
checkdepends=('perl-test-simple')
options=('!strip')
_vendor_perl=$(perl -V::vendorarch: | sed -e "s![' ]!!g")

check() {
    cd ${startdir}/tests

    for t in \
            'test1-inputoutput.pl' \
            'test2-macros.pl' \
            'test3-splitjoin.pl' \
            'test4-delegating.pl' \
    ; do
        echo Running test $t
        perl $t
    done
}

package() {
    for d in Macrobuild Macrobuild/BasicTasks Macrobuild/CompositeTasks; do
        install -D -m644 ${startdir}/vendor_perl/$d/*.pm -t ${pkgdir}${_vendor_perl}/$d/
    done
    install -D -m755 ${startdir}/bin/macrobuild -t ${pkgdir}/usr/bin/
}
