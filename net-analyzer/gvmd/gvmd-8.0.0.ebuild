# Copyright 1999-2019 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=7

CMAKE_MAKEFILE_GENERATOR="emake"
inherit cmake-utils flag-o-matic systemd

DESCRIPTION="Greenbone vulnerability manager, previously named openvas-manager"
HOMEPAGE="https://www.greenbone.net/en/"
SRC_URI="https://github.com/greenbone/gvmd/archive/v${PV}.tar.gz -> ${P}.tar.gz"

SLOT="0"
LICENSE="GPL-2+"
KEYWORDS="~amd64 ~x86"
IUSE="extras"

DEPEND="
	dev-db/sqlite:3
	dev-libs/libgcrypt:0=
	dev-libs/libical
	>=net-analyzer/gvm-libs-10.0.0
	net-libs/gnutls:=[tools]
	extras? ( app-text/xmlstarlet
		  dev-texlive/texlive-latexextra )"

RDEPEND="
	${DEPEND}
	!net-analyzer/openvas-manager
	>=net-analyzer/openvas-scanner-6.0.0"

BDEPEND="
	sys-devel/bison
	sys-devel/flex
	virtual/pkgconfig
	extras? ( app-doc/doxygen[dot]
		  app-doc/xmltoman
		  app-text/htmldoc
		  dev-libs/libxslt
	)"

PATCHES=(
	"${FILESDIR}/${P}-sys-siglist.patch"
)

src_prepare() {
	cmake-utils_src_prepare
	# Fix the ebuild to use correct FHS/Gentoo policy paths for 8.0.0
	sed -i "s*share/doc/gvm/html/*share/doc/gvmd-${PV}/html/*g" "$S"/doc/CMakeLists.txt || die
	sed -i "s*/doc/gvm/*/doc/gvmd-${PV}/*g" "$S"/CMakeLists.txt || die
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
	# Fix runtime QA error for 8.0.0
	append-cflags -Wno-nonnull
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
	# Migration from opevas-manager-7 to gvmd-8
	if has_version '=net-analyzer/openvas-manager-7.0.3'; then
	   mv /etc/openvas/{pwpolicy.conf,gsf-access-key} /etc/gvm/
	   mv /etc/openvas/openvasmd_log.conf /etc/gvm/gvmd_log.conf
	   mv /var/lib/openvas/scap-data /var/lib/gvm/scap-data
	   mv /var/lib/openvas/cert-data /var/lib/gvm/cert-data
	   mv /var/lib/openvas/openvasmd /var/lib/gvm/gvmd
	   mv /var/lib/openvas/CA /var/lib/gvm/CA
	   mv /var/lib/openvas/private /var/lib/gvm/private
	   if has version '>=dev-db/sqlite-3.25*'; then
	      mv /var/lib/openvas/mgr/tasks.db /var/lib/gvm/gvmd/gvmd.db
	      gvmd --migrate
	   fi
	fi

	insinto /etc/gvm/sysconfig
	doins "${FILESDIR}"/${PN}-daemon.conf

	newinitd "${FILESDIR}/${PN}.init" ${PN}
	newconfd "${FILESDIR}/${PN}-daemon.conf" ${PN}

	insinto /etc/logrotate.d
	newins "${FILESDIR}/${PN}.logrotate" ${PN}

	systemd_dounit "${FILESDIR}"/${PN}.service

	keepdir /var/lib/gvm/gvmd
}
