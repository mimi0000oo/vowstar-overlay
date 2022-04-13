# Copyright 1999-2022 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI="8"

inherit xdg

DESCRIPTION="A open source IP-XACT-based tool"
HOMEPAGE="
	http://funbase.cs.tut.fi
	https://github.com/kactus2/kactus2dev
"

if [[ "${PV}" == "9999" ]] ; then
	inherit git-r3
	EGIT_REPO_URI="https://github.com/${PN}/${PN}dev.git"
else
	SRC_URI="https://github.com/${PN}/${PN}dev/archive/v${PV}.tar.gz -> ${P}.tar.gz"
	KEYWORDS="~amd64 ~arm ~arm64 ~hppa ~m68k ~mips ~ppc ~ppc64 ~s390 ~sparc ~x86"
	S="${WORKDIR}/${PN}dev-${PV}"
fi

LICENSE="GPL-2"
SLOT="0"

RDEPEND="
	dev-qt/qtcore:5
	dev-qt/qtgui:5
	dev-qt/qthelp:5
	dev-qt/qtprintsupport:5
	dev-qt/qtsvg:5
	dev-qt/qtwidgets:5
	dev-qt/qtxml:5
"

DEPEND="
	${RDEPEND}
"

PATCHES=(
	"${FILESDIR}"/${PN}-3.9.333-install.patch # Fix install problem
)

src_prepare() {
	default

	# Fix QTBIN_PATH
	sed -i -e "s|QTBIN_PATH=.*|QTBIN_PATH=\"$(get_libdir)\"/qt5/bin/|" configure || die
}

src_install() {
	# Can't use default, set INSTALL_ROOT
	emake INSTALL_ROOT="${D}" install
}
