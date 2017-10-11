developer="http://indiecomputing.com/"
url="http://ubos.net/"
maintainer=${developer}
pkgname=macrobuild
pkgver=0.46
pkgrel=1
pkgdesc="Build framework for large, 'macro' tasks"
arch=('any')
license=('GPL')
depends=('perl' 'ubos-perl-utils')
checkdepends=('perl-test-simple')
options=('!strip')
_vendor_perl=$(perl -V::vendorarch: | sed -e "s![' ]!!g")
_tests=(
    'test1/test1-inputoutput.pl'
    'test2/test2-macros.pl'
    'test3/test3-splitjoin.pl'
    'test4/test4-delegating.pl'
    'test5/test5-vars.pl'
    'test6/test6-vars.pl'
    'test7/test7-valuetrace.pl'
    'test8/test8-fail.pl'
)

check() {
    cd ${startdir}/tests

    for t in ${_tests[@]} ; do
        echo Running test $t
        ( cd $(dirname $t); perl -I ../../vendor_perl $(basename $t) )
    done
}

package() {
    for d in Macrobuild Macrobuild/BasicTasks Macrobuild/CompositeTasks; do
        install -D -m644 ${startdir}/vendor_perl/$d/*.pm -t ${pkgdir}${_vendor_perl}/$d/
    done
    install -D -m755 ${startdir}/bin/macrobuild -t ${pkgdir}/usr/bin/
}
