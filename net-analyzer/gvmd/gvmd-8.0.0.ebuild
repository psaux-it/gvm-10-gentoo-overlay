# Copyright 1999-2019 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=7

CMAKE_MAKEFILE_GENERATOR="emake"
inherit cmake-utils flag-o-matic systemd toolchain-funcs

DESCRIPTION="Greenbone vulnerability manager daemon, previously named openvas-manager"
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
	# QA-Fix | Use correct FHS/Gentoo policy paths for 8.0.0
	sed -i "s*share/doc/gvm/html/*share/doc/gvmd-${PV}/html/*g" "$S"/doc/CMakeLists.txt || die
	sed -i "s*/doc/gvm/*/doc/gvmd-${PV}/*g" "$S"/CMakeLists.txt || die
	# QA-Fix | Remove Doxygen warnings for !CLANG
	if use extras; then
		if ! tc-is-clang; then
		   for f in doc/*.in
		   do
			sed \
			-e "s*CLANG_ASSISTED_PARSING = NO*#CLANG_ASSISTED_PARSING = NO*g" \
			-e "s*CLANG_OPTIONS*#CLANG_OPTIONS*g" \
			-i "${f}" || die "couldn't disable CLANG parsing"
		   done
		fi
	fi
}

src_configure() {
	local mycmakeargs=(
		"-DCMAKE_INSTALL_PREFIX=${EPREFIX}/usr"
		"-DLOCALSTATEDIR=${EPREFIX}/var"
		"-DSYSCONFDIR=${EPREFIX}/etc"
	)
	# QA-Fix | Disable false-positive warnings for 8.0.0
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

	insinto /etc/gvm/sysconfig
	doins "${FILESDIR}/${PN}-daemon.conf"

	newinitd "${FILESDIR}/${PN}.init" "${PN}"
	newconfd "${FILESDIR}/${PN}-daemon.conf" "${PN}"

	insinto /etc/logrotate.d
	newins "${FILESDIR}/${PN}.logrotate" "${PN}"

	systemd_dounit "${FILESDIR}/${PN}.service"

	keepdir /var/lib/gvm/gvmd
}
