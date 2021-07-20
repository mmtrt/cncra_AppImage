#!/bin/bash

cncras () {

# Convert and copy icon which is needed for desktop integration into place:
wget -q https://github.com/mmtrt/cncra/raw/master/snap/gui/cncra.png
for width in 8 16 22 24 32 36 42 48 64 72 96 128 192 256; do
    dir=icons/hicolor/${width}x${width}/apps
    mkdir -p $dir
    convert cncra.png -resize ${width}x${width} $dir/cncra.png
done

wget -q "https://github.com/AppImage/AppImageKit/releases/download/continuous/appimagetool-x86_64.AppImage"
chmod +x ./appimagetool-x86_64.AppImage
./appimagetool-x86_64.AppImage --appimage-extract &>/dev/null

mkdir -p ra-mp/usr ra-mp/winedata ; cp cncra.desktop ra-mp ; cp AppRun ra-mp ;
cp -r icons ra-mp/usr/share ; cp cncra.png ra-mp

wget -q "https://dl.winehq.org/wine/wine-mono/5.1.1/wine-mono-5.1.1-x86.msi"
wget -q "https://downloads.cncnet.org/RedAlert1_Online_Installer.exe"
wget -q "https://download.lenovo.com/ibmdl/pub/pc/pccbbs/thinkvantage_en/dotnetfx.exe"
wget -q "https://github.com/AutoHotkey/AutoHotkey/releases/download/v1.0.48.05/AutoHotkey104805_Install.exe"

cp -Rp ./*.exe ra-mp/winedata ; cp -Rp ./*.msi ra-mp/winedata

export ARCH=x86_64; squashfs-root/AppRun -v ./ra-mp -u "gh-releases-zsync|mmtrt|cncra_AppImage|stable|cncra*.AppImage.zsync" cncra_${ARCH}.AppImage &>/dev/null

}

cncraswp () {

export WINEDLLOVERRIDES="mshtml="
export WINEARCH="win32"
export WINEPREFIX="/home/runner/.wine"
export WINEDEBUG="-all"

cncras ; rm ./*AppImage*

WINE_VER="$(wget -qO- https://dl.winehq.org/wine-builds/ubuntu/dists/focal/main/binary-i386/ | grep wine-stable | sed 's|_| |g;s|~| |g' | awk '{print $5}' | tail -n1)"
wget -q https://github.com/mmtrt/WINE_AppImage/releases/download/continuous-stable/wine-stable_${WINE_VER}-x86_64.AppImage
chmod +x *.AppImage ; mv wine-stable_${WINE_VER}-x86_64.AppImage wine-stable.AppImage

# Create winetricks & wine cache
mkdir -p /home/runner/.cache/{wine,winetricks}/{dotnet20,ahk} ; cp dotnetfx.exe /home/runner/.cache/winetricks/dotnet20
cp -Rp *.msi /home/runner/.cache/wine/ ; cp -Rp AutoHotkey104805_Install.exe /home/runner/.cache/winetricks/ahk

# Create WINEPREFIX
./wine-stable.AppImage winetricks -q dotnet20 ; sleep 5

# Install game
( ./wine-stable.AppImage wine RedAlert1_Online_Installer.exe /silent ; sleep 5 )

cp -Rp ./RedAlert1_Online "$WINEPREFIX"/drive_c/

# Removing any existing user data
( cd "$WINEPREFIX/drive_c/" ; rm -rf users ) || true

cp -Rp $WINEPREFIX ra-mp/ ; rm -rf $WINEPREFIX ; rm -rf ./ra-mp/winedata ; rm ./*.AppImage

( cd ra-mp ; wget -qO- 'https://gist.github.com/mmtrt/6d111388fadf6a08b7f4c41cdc250080/raw/f8367c582eaf6e286c3844abf80beb168d028b73/cncraswp.patch' | patch -p1 )

export ARCH=x86_64; squashfs-root/AppRun -v ./ra-mp -n -u "gh-releases-zsync|mmtrt|cncra_AppImage|stable-wp|cncra*.AppImage.zsync" cncra_WP-${ARCH}.AppImage &>/dev/null

}

if [ "$1" == "stable" ]; then
    cncras
    ( mkdir -p dist ; mv cncra*.AppImage* dist/. ; cd dist || exit ; chmod +x ./*.AppImage )
elif [ "$1" == "stablewp" ]; then
    cncraswp
    ( mkdir -p dist ; mv cncra*.AppImage* dist/. ; cd dist || exit ; chmod +x ./*.AppImage )
fi
