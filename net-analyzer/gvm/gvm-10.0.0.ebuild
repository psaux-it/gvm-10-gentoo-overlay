# Copyright 1999-2019 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=7

inherit eutils

DESCRIPTION="Greenbone Vulnerability Management,previously named OpenVAS"
HOMEPAGE="https://www.greenbone.net/en/"

SLOT="0"
LICENSE="GPL-2"
KEYWORDS="~amd64 ~x86"
IUSE="cli +cron +extras +gsa ldap +ospd postgres radius"

RDEPEND="
	>=net-analyzer/gvm-libs-10.0.0[extras?,ldap?,radius?]
	>=net-analyzer/gvmd-8.0.0[extras?,postgres?]
	>=net-analyzer/openvas-scanner-6.0.0[cron?,extras?]
	!net-analyzer/openvas
	cli? ( >=net-analyzer/gvm-tools-1.4.1 )
	gsa? ( >=net-analyzer/greenbone-security-assistant-8.0.0[extras?] )
	ospd? ( >=net-analyzer/ospd-1.3.2[extras?] )"

pkg_postinst() {
	elog "----------------------------IMPORTANT----------------------------"
	elog " Please read important notes > /usr/share/gvm/GVM.gentoo "
	elog "-----------------------------------------------------------------"
	elog "Additional support for extra checks can be get from"
	optfeature "Web server scanning and testing tool" net-analyzer/nikto
	optfeature "Portscanner" net-analyzer/nmap
	optfeature "IPsec VPN scanning, fingerprinting and testing tool" net-analyzer/ike-scan
	optfeature "Application protocol detection tool" net-analyzer/amap
	optfeature "ovaldi (OVAL) — an OVAL Interpreter" app-forensics/ovaldi
	optfeature "Linux-kernel-based portscanner" net-analyzer/portbunny
	optfeature "Web application attack and audit framework" net-analyzer/w3af
}
