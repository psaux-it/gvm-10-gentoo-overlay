# Copyright 1999-2019 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=7

CMAKE_MAKEFILE_GENERATOR="emake"
inherit cmake-utils systemd toolchain-funcs

MY_PN="gsa"
MY_NODE_N="node_modules"

DESCRIPTION="Greenbone security assistant"
HOMEPAGE="https://www.greenbone.net/en/"
SRC_URI="https://github.com/greenbone/${MY_PN}/archive/v${PV}.tar.gz -> ${P}.tar.gz
	 https://github.com/greenbone/${MY_PN}/releases/download/v${PV}/${MY_PN}-${MY_NODE_N}-${PV}.tar.gz -> ${P}-${MY_NODE_N}.tar.gz"

SLOT="0"
LICENSE="GPL-2+"
KEYWORDS="~amd64 ~x86"
IUSE="extras"

DEPEND="
	dev-libs/libgcrypt:0=
	dev-libs/libxslt
	dev-python/polib
	>=net-analyzer/gvm-libs-10.0.0
	net-libs/gnutls:=
	net-libs/libmicrohttpd[messages]
	>=net-libs/nodejs-8.12.0
	>=sys-apps/yarn-1.15.2"

RDEPEND="
	${DEPEND}
	!=net-analyzer/greenbone-security-assistant-7.0*
	>=net-analyzer/openvas-scanner-6.0.0
	>=net-analyzer/gvmd-8.0.0"

BDEPEND="
	virtual/pkgconfig
	extras? ( app-doc/doxygen[dot]
		  app-doc/xmltoman
		  app-text/htmldoc
		  sys-devel/gettext
	)"

BUILD_DIR="${WORKDIR}/${MY_PN}-${PV}_build"
S="${WORKDIR}/${MY_PN}-${PV}"
MY_NODE_DIR="${S}/gsa/"

PATCHES=(
	# QA fix for 8.0.0.
	"${FILESDIR}/${P}-pid.patch"
	# Disable yarn-fetch during compile.
	"${FILESDIR}/${P}-yarn-install.patch"
	# Fix react-env path.
	"${FILESDIR}/${P}-react-env.patch"
	# Fix build error for 8.0.0.
	"${FILESDIR}/${P}-revision_8.0.1.patch"
	# Remove yarn terminal output.
	"${FILESDIR}/${P}-command.patch"
)

src_prepare() {
	cmake-utils_src_prepare
	# We will use pre-fetched node_modules.
	mv "${WORKDIR}/${MY_NODE_N}" "${MY_NODE_DIR}" || die "couldn't move node_modules"
	# Update .yarnrc accordingly.
	echo "--modules-folder ${MY_NODE_DIR}" >> "${S}"/gsa/.yarnrc || die "echo failed"
	# QA-Fix doxygen warning for CLANG.
	if use extras; then
		if ! tc-is-clang; then
		   for f in gsad/doc/*.in
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
	cmake-utils_src_configure
}

src_compile() {
	cmake-utils_src_compile
	if use extras; then
		cmake-utils_src_make -C "${BUILD_DIR}" doc
		cmake-utils_src_make doc-full -C "${BUILD_DIR}" doc
		HTML_DOCS=( "${BUILD_DIR}"/gsad/doc/generated/html/. )
	fi
	cmake-utils_src_make rebuild_cache
}

src_install() {
	cmake-utils_src_install

	insinto /etc/gvm/sysconfig
	doins "${FILESDIR}/${MY_PN}-daemon.conf"

	insinto /etc/gvm/reverse-proxy
	doins "${FILESDIR}"/gsa.nginx.reverse.proxy.example

	newinitd "${FILESDIR}/${MY_PN}.init" "${MY_PN}"
	newconfd "${FILESDIR}/${MY_PN}-daemon.conf" "${MY_PN}"

	insinto /etc/logrotate.d
	newins "${FILESDIR}/${MY_PN}.logrotate" "${MY_PN}"

	systemd_newtmpfilesd "${FILESDIR}/${MY_PN}.tmpfiles.d" "${MY_PN}".conf
	systemd_dounit "${FILESDIR}/${MY_PN}.service"
}
