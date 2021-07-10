#!/bin/bash

# Convert and copy icon which is needed for desktop integration into place:
wget https://github.com/mmtrt/cncra/raw/master/snap/gui/cncra.png &>/dev/null
for width in 8 16 22 24 32 36 42 48 64 72 96 128 192 256; do
    dir=icons/hicolor/${width}x${width}/apps
    mkdir -p $dir
    convert cncra.png -resize ${width}x${width} $dir/cncra.png
done

wget -c "https://github.com/AppImage/AppImageKit/releases/download/continuous/appimagetool-x86_64.AppImage"
chmod +x ./appimagetool-x86_64.AppImage
./appimagetool-x86_64.AppImage --appimage-extract

cncras () {

mkdir -p ra-mp/usr ra-mp/winedata ; cp cncra.desktop ra-mp ; cp AppRun ra-mp ;
cp -r icons ra-mp/usr/share ; cp cncra.png ra-mp

wget "https://dl.winehq.org/wine/wine-mono/5.1.1/wine-mono-5.1.1-x86.msi"
wget "https://downloads.cncnet.org/RedAlert1_Online_Installer.exe"
wget "https://download.lenovo.com/ibmdl/pub/pc/pccbbs/thinkvantage_en/dotnetfx.exe"

cp -Rvp ./*.exe ra-mp/winedata ; cp -Rvp ./*.msi ra-mp/winedata

export ARCH=x86_64; squashfs-root/AppRun -v ./ra-mp -u "gh-releases-zsync|mmtrt|cncra_AppImage|stable|cncra*.AppImage.zsync" cncra_${ARCH}.AppImage

}

cncraswp () {

export WINEDLLOVERRIDES="mscoree,mshtml="
export WINEARCH="win32"
export WINEPREFIX="/home/runner/.wine"
export WINEDEBUG="-all"

cncras ; rm ./*AppImage*

# Create WINEPREFIX
wineboot ; sleep 5
winetricks -q dotnet20 ; sleep 5

# Install game
(wine /ra-mp/winedata/RedAlert1_Online_Installer.exe /silent ; sleep 20)
ls -al ./

# Launch game
wine ./RedAlert1_Online/RA1MPLauncher.exe &
sleep 10
wineserver -k

cp -Rvp ./RedAlert1_Online "$WINEPREFIX"/drive_c/

# Removing any existing user data
( cd "$WINEPREFIX/drive_c/" ; rm -rf users ; rm windows/temp/* ) || true

# Pre patching dpi setting in WINEPREFIX & Pre patching to disable winemenubuilder
# DPI dword value 240=f0 180=b4 120=78 110=6e 96=60
( cd "$WINEPREFIX"; sed -i 's|"LogPixels"=dword:00000060|"LogPixels"=dword:0000006e|' ./user.reg ; sed -i 's|"LogPixels"=dword:00000060|"LogPixels"=dword:0000006e|' ./system.reg ; sed -i 's/winemenubuilder.exe -a -r/winemenubuilder.exe -r/g' ./system.reg ) || true

cp -Rvp $WINEPREFIX ra-mp/ ; rm -rf $WINEPREFIX ; rm -rf /ra-mp/winedata

# ( cd ra-mp ; wget -qO- 'https://gist.github.com/mmtrt/df659de58e36ee091e203ab3c1460619/raw/6dda9c96673307366dd8070c5ad9683b622bb60c/nppswp.patch' | patch -p1 )

export ARCH=x86_64; squashfs-root/AppRun -v ./ra-mp -n -u "gh-releases-zsync|mmtrt|cncra_AppImage|stable-wp|cncra*.AppImage.zsync" cncra_WP-${ARCH}.AppImage

}

if [ "$1" == "stable" ]; then
    cncras
elif [ "$1" == "stablewp" ]; then
    cncraswp
fi