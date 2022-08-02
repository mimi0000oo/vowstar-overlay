# Copyright 2022 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=8

inherit desktop unpacker xdg

DESCRIPTION="Wemeet - Tencent Video Conferencing"
HOMEPAGE="https://wemeet.qq.com"
# no arm64 for 3.9.0.1 release yet
SRC_URI="
	amd64? ( mirror+https://updatecdn.meeting.qq.com/OTRhY2YwZTUtMzE5Ni00NDQyLTg0MTMtOTBjYzQzNzcxYTQz/TencentMeeting_0300000000_${PV}_x86_64_default.publish.deb -> ${P}_amd64.deb )
"

LICENSE="wemeet_license"
SLOT="0"
KEYWORDS="-* ~amd64"

RESTRICT="bindist test"

DEPEND="
	dev-qt/qtwebengine:5
	dev-qt/qtx11extras:5
	media-sound/pulseaudio
	x11-libs/libXinerama
	x11-libs/libXrandr
"
RDEPEND="${DEPEND}"
BDEPEND="dev-util/patchelf"

S="${WORKDIR}"
QA_PREBUILT="opt/${PN}/*"

src_install() {
	# To fix bug, remove unused lib, use system lib instead
	mv opt/${PN}/lib opt/${PN}/lib.orig || die
	mkdir opt/${PN}/lib || die
	cp -rf opt/${PN}/lib.orig/{libwemeet*,libxcast.so,libxnn*,libui*,libdesktop_common.so,libImSDK.so,libxcast_codec.so,libnxui*} opt/${PN}/lib/ || die
	rm -r opt/${PN}/lib.orig || die
	# Fix RPATHs to ensure the libraries can be found
	for f in $(find "opt/${PN}/bin" "opt/${PN}/plugins") ; do
		[[ -f ${f} && $(od -t x1 -N 4 "${f}") == *"7f 45 4c 46"* ]] || continue
		patchelf --set-rpath "/opt/${PN}/lib" ${f} || die "patchelf failed on ${f}"
	done
	for f in $(find "opt/${PN}/lib") ; do
		[[ -f ${f} && $(od -t x1 -N 4 "${f}") == *"7f 45 4c 46"* ]] || continue
		patchelf --set-rpath '$ORIGIN' ${f} || die "patchelf failed on ${f}"
	done

	# Force X11
	# If wayland is used, wemeet will just die:
	# /opt/wemeet/bin/wemeetapp: symbol lookup error: /usr/lib64/libwayland-cursor.so.0: undefined symbol: wl_proxy_marshal_flags
	# tested with 2.8.0.3 and dev-libs/wayland-1.20.0
	cat > "opt/${PN}/wemeetapp.sh" <<- EOF || die
#!/bin/sh
export XDG_SESSION_TYPE=x11
export QT_QPA_PLATFORM=xcb
export QT_AUTO_SCREEN_SCALE_FACTOR=1
export QT_STYLE_OVERRIDE=fusion # 解决使用自带qt情况下，字体颜色全白看不到的问题
export IBUS_USE_PORTAL=1 # fix ibus
FONTCONFIG_DIR=\$HOME/.config/fontconfig
unset WAYLAND_DISPLAY

# if pipewire-pulse installed
if [ -f /usr/bin/pipewire-pulse ]; then
    export PULSE_LATENCY_MSEC=20 # 解决Pipewire播放声音卡顿的问题
fi;

if [ -f "/usr/bin/bwrap" ];then
    mkdir -p \$FONTCONFIG_DIR
    bwrap --dev-bind / / --tmpfs \$HOME/.config --ro-bind \$FONTCONFIG_DIR \$FONTCONFIG_DIR /opt/wemeet/bin/wemeetapp \$*;
else
    exec /opt/wemeet/bin/wemeetapp \$*;
fi;
	EOF

	insinto "/opt/${PN}"
	exeinto "/opt/${PN}"
	doins -r "opt/${PN}/bin" "opt/${PN}/icons" "opt/${PN}/lib" "opt/${PN}/plugins" "opt/${PN}/resources"  "opt/${PN}/translations"
	doexe "opt/${PN}/wemeetapp.sh"
	fperms +x "/opt/${PN}/bin/wemeetapp"

	# put launcher into PATH
	dosym "../../opt/${PN}/wemeetapp.sh" /usr/bin/wemeetapp

	sed -i "s/^Icon=.*/Icon=wemeetapp/g" "usr/share/applications/wemeetapp.desktop" || die
	sed -i "s/^Exec=.*/Exec=wemeetapp %u/g" "usr/share/applications/wemeetapp.desktop" || die
	sed -i '$i Comment=Tencent Meeting Linux Client\nComment[zh_CN]=腾讯会议Linux客户端\nKeywords=wemeet;tencent;meeting;' "usr/share/applications/wemeetapp.desktop" || die
	domenu "usr/share/applications/wemeetapp.desktop"
	newicon -s scalable "opt/${PN}/wemeet.svg" "wemeetapp.svg"
	for i in 16 32 64 128 256; do
		png_file="opt/${PN}/icons/hicolor/${i}x${i}/mimetypes/wemeetapp.png"
		if [ -e "${png_file}" ]; then
			newicon -s "${i}" "${png_file}" wemeetapp
		fi
	done
}
