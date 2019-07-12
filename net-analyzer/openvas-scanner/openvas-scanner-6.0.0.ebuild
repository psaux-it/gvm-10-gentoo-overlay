# Copyright 1999-2019 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=7

CMAKE_MAKEFILE_GENERATOR="emake"
inherit cmake-utils systemd

MY_PN="openvas"

DESCRIPTION="OpenVAS remote network security scanner"
HOMEPAGE="https://www.greenbone.net/en/"
SRC_URI="https://github.com/greenbone/openvas-scanner/archive/v${PV}.tar.gz -> ${P}.tar.gz"

SLOT="0"
LICENSE="GPL-2 GPL-2+"
KEYWORDS="~amd64 ~x86"
IUSE="extras"

DEPEND="
	app-crypt/gpgme:=
	dev-db/redis
	dev-libs/libgcrypt:=
	dev-libs/libksba
	>=net-analyzer/gvm-libs-10.0.0
	net-analyzer/net-snmp
	net-libs/gnutls:=
	net-libs/libpcap
	net-libs/libssh:=
"

RDEPEND="
	${DEPEND}
	!net-analyzer/openvas-tools"

BDEPEND="
	sys-devel/bison
	sys-devel/flex
	virtual/pkgconfig
	extras? ( app-doc/doxygen[dot]
		  app-doc/xmltoman
		  app-text/htmldoc
		  dev-perl/CGI
		  dev-perl/SQL-Translator
	)"

BUILD_DIR="${WORKDIR}/${MY_PN}-${PV}_build"
S="${WORKDIR}/${MY_PN}-${PV}"

PATCHES=(
	"${FILESDIR}/${P}-execinfo-musl-fix.patch"
	#Revision 6.0.1 cumulative patch.
	"${FILESDIR}/${P}-cumulative.patch"
	#GLIBC malloc-trim patch.
	"${FILESDIR}/${P}-malloc-trim.patch"
)

src_prepare() {
	cmake-utils_src_prepare
	# Fix for correct FHS/Gentoo policy paths for 6.0.0
	sed -i "s*/doc/openvas-scanner/*/doc/openvas-scanner-${PV}/*g" "$S"/src/CMakeLists.txt || die
	if use extras; then
		doxygen -u "$S"/doc/Doxyfile_full.in || die
	fi
}

src_configure() {
	local mycmakeargs=(
		"-DCMAKE_INSTALL_PREFIX=${EPREFIX}/usr"
		"-DLOCALSTATEDIR=${EPREFIX}/var"
		"-DSYSCONFDIR=${EPREFIX}/etc"
	)
	cmake-utils_src_configure
}

src_compile() {
	cmake-utils_src_compile
	if use extras; then
		cmake-utils_src_make -C "${BUILD_DIR}" doc
		cmake-utils_src_make doc-full -C "${BUILD_DIR}" doc
		HTML_DOCS=( "${BUILD_DIR}"/doc/generated/html/. )
	fi
	cmake-utils_src_make rebuild_cache
}

src_install() {
	cmake-utils_src_install

	insinto /etc/openvas
	doins "${FILESDIR}"/openvassd.conf "${FILESDIR}"/redis.conf.example

	insinto /etc/openvas/sysconfig
	doins "${FILESDIR}"/${PN}-daemon.conf

	insinto /etc/openvas/scripts
	doins "${FILESDIR}"/openvas-feed-sync "${FILESDIR}"/first-start
	fperms 0755 /etc/openvas/scripts/{openvas-feed-sync,first-start}

	newinitd "${FILESDIR}/${PN}.init" ${PN}
	newconfd "${FILESDIR}/${PN}-daemon.conf" ${PN}

	insinto /etc/logrotate.d
	newins "${FILESDIR}/${PN}.logrotate" ${PN}

	systemd_newtmpfilesd "${FILESDIR}/${PN}.tmpfiles.d" ${PN}.conf
	systemd_dounit "${FILESDIR}"/${PN}.service

	keepdir /var/lib/openvas/{gnupg,plugins}
	keepdir /var/log/gvm
}
