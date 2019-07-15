# Copyright 1999-2019 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=7

CMAKE_MAKEFILE_GENERATOR="emake"
inherit cmake-utils toolchain-funcs

DESCRIPTION="Greenbone vulnerability management libraries, previously named openvas-libraries"
HOMEPAGE="https://www.greenbone.net/en/"
SRC_URI="https://github.com/greenbone/gvm-libs/archive/v${PV}.tar.gz -> ${P}.tar.gz"

SLOT="0"
LICENSE="GPL-2+"
KEYWORDS="~amd64 ~x86"
IUSE="extras ldap radius"

DEPEND="
	app-crypt/gpgme:=
	dev-libs/hiredis
	dev-libs/libgcrypt:=
	dev-perl/UUID
	net-libs/gnutls:=
	net-libs/libssh:=
	sys-libs/zlib
	ldap? ( net-nds/openldap )
	radius? ( net-dialup/freeradius-client )"

RDEPEND="
	${DEPEND}
	!net-analyzer/openvas-libraries"

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

PATCHES=(
	# GLIBC malloc-trim patch.
	"${FILESDIR}/${P}-malloc-trim.patch"
	# Fix pid dir.
	"${FILESDIR}/${P}-pid.patch"
)

src_prepare() {
	cmake-utils_src_prepare
	if use extras; then
		if ! tc-is-clang; then
		   # QA-Fix doxygen warning for CLANG.
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
		$(usex ldap -DBUILD_WITHOUT_LDAP=0 -DBUILD_WITHOUT_LDAP=1)
		$(usex radius -DBUILD_WITHOUT_RADIUS=0 -DBUILD_WITHOUT_RADIUS=1)
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

	insinto /usr/share/gvm
	doins "${FILESDIR}"/GVM.gentoo

	keepdir /var/lib/gvm/gnupg
	keepdir /var/log/gvm
}
