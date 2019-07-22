# Copyright 1999-2019 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=7

CMAKE_MAKEFILE_GENERATOR="emake"
inherit cmake-utils flag-o-matic systemd toolchain-funcs user

MY_PN="openvas"

DESCRIPTION="Open Vulnerability Assessment Scanner"
HOMEPAGE="https://www.greenbone.net/en/"
SRC_URI="https://github.com/greenbone/openvas-scanner/archive/v${PV}.tar.gz -> ${P}.tar.gz"

SLOT="1"
LICENSE="GPL-2 GPL-2+"
KEYWORDS="~amd64 ~x86"
IUSE="cron extras"

DEPEND="
	app-crypt/gpgme:=
	dev-db/redis
	dev-libs/libgcrypt:=
	dev-libs/libksba
	>=net-analyzer/gvm-libs-10.0.1
	net-analyzer/net-snmp
	net-libs/gnutls:=
	net-libs/libpcap
	net-libs/libssh:=
"

RDEPEND="
	${DEPEND}
	!net-analyzer/openvas-scanner:0
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
	# Security fix for 6.0.1.
	"${FILESDIR}/${P}-sbin.patch"
)


pkg_setup() {
	enewgroup gvm
	enewuser gvm 1453 /bin/bash /var/lib/gvm gvm,redis
}

src_prepare() {
	cmake-utils_src_prepare
	# QA-Fix | Correct FHS/Gentoo policy paths for 6.0.1
	sed -i -e "s*/doc/openvas-scanner/*/doc/openvas-scanner-${PV}/*g" "$S"/src/CMakeLists.txt || die
	# QA-Fix | Remove !CLANG doxygen warnings for 6.0.1
	if use extras; then
		if ! tc-is-clang; then
		   local f
		   for f in doc/*.in
		   do
			sed -i \
				-e "s*CLANG_ASSISTED_PARSING = NO*#CLANG_ASSISTED_PARSING = NO*g" \
				-e "s*CLANG_OPTIONS*#CLANG_OPTIONS*g" \
				"${f}" || die "couldn't disable CLANG parsing"
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
	# Add release hardening flags for 6.0.1
	append-cflags -Wno-format-truncation -Wformat -Wformat-security -D_FORTIFY_SOURCE=2 -fstack-protector
	append-ldflags -Wl,-z,relro -Wl,-z,now
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

	dodir /etc/openvas
	insinto /etc/openvas
	doins "${FILESDIR}"/openvassd.conf "${FILESDIR}"/redis.conf.example

	dodir /etc/openvas/sysconfig
	insinto /etc/openvas/sysconfig
	doins "${FILESDIR}/${PN}-daemon.conf"

	if use cron; then
		# Install the cron job if they want it.
		exeinto /etc/cron.daily
		newexe "${FILESDIR}/gvm-feed-sync.cron" \
		gvm-feed-sync
	fi

	newinitd "${FILESDIR}/${PN}.init" "${PN}"
	newconfd "${FILESDIR}/${PN}-daemon.conf" "${PN}"

	dodir /etc/logrotate.d
	insinto /etc/logrotate.d
	newins "${FILESDIR}/${PN}.logrotate" "${PN}"

	systemd_newtmpfilesd "${FILESDIR}/${PN}.tmpfiles.d" "${PN}".conf
	systemd_dounit "${FILESDIR}/${PN}.service"

	keepdir /var/lib/openvas
	keepdir /var/lib/openvas/{gnupg,plugins}
	fowners -R gvm:gvm /var/lib/openvas
	keepdir /var/log/gvm
	fowners -R gvm:gvm /var/log/gvm
	keepdir /etc/openvas
	fowners -R gvm:gvm /etc/openvas
}
