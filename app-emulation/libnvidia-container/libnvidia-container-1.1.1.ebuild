# Copyright 1999-2020 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=7

DESCRIPTION="NVIDIA container runtime library"
HOMEPAGE="https://github.com/NVIDIA/libnvidia-container"

if [[ "${PV}" == "9999" ]] ; then
	inherit git-r3
	EGIT_REPO_URI="https://github.com/NVIDIA/${PN}.git"
else
	SRC_URI="https://github.com/NVIDIA/${PN}/archive/v${PV}.tar.gz -> ${P}.tar.gz"
	KEYWORDS="~amd64"
fi

LICENSE="Apache-2.0"
SLOT="0"

IUSE=""

RDEPEND="
	sys-libs/libcap
	sys-libs/libseccomp
	net-libs/libtirpc
"

DEPEND="${RDEPEND}"

BDEPEND="
	net-libs/rpcsvc-proto
	sys-apps/lsb-release
	sys-devel/bmake
	virtual/pkgconfig
"
