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
wget "https://github.com/AutoHotkey/AutoHotkey/releases/download/v1.0.48.05/AutoHotkey104805_Install.exe"

cp -Rvp ./*.exe ra-mp/winedata ; cp -Rvp ./*.msi ra-mp/winedata

export ARCH=x86_64; squashfs-root/AppRun -v ./ra-mp -u "gh-releases-zsync|mmtrt|cncra_AppImage|stable|cncra*.AppImage.zsync" cncra_${ARCH}.AppImage

}

cncraswp () {

# Disable FileOpenAssociations
sudo sed -i 's|    LicenseInformation|    LicenseInformation,\\\n    FileOpenAssociations|g;$a \\n[FileOpenAssociations]\nHKCU,Software\\Wine\\FileOpenAssociations,"Enable",,"N"' /opt/wine-stable/share/wine/wine.inf
# Disable winemenubuilder
sudo sed -i 's|    FileOpenAssociations|    FileOpenAssociations,\\\n    DllOverrides|;$a \\n[DllOverrides]\nHKCU,Software\\Wine\\DllOverrides,"*winemenubuilder.exe",,""' /opt/wine-stable/share/wine/wine.inf
sudo sed -i '/\%11\%\\winemenubuilder.exe -a -r/d' /opt/wine-stable/share/wine/wine.inf
# Pre patching DPI setting DPI dword value 240=f0 180=b4 120=78 110=6e 100=64 96=60
sudo sed -i 's|0x00000060|0x00000064|' /opt/wine-stable/share/wine/wine.inf

export WINEDLLOVERRIDES="mshtml="
export WINEARCH="win32"
export WINEPREFIX="/home/runner/.wine"
export WINEDEBUG="-all"

cncras ; rm ./*AppImage*

# Create winetricks & wine cache
mkdir -p /home/runner/.cache/{wine,winetricks}/{dotnet20,ahk} ; cp dotnetfx.exe /home/runner/.cache/winetricks/dotnet20
cp -Rvp *.msi /home/runner/.cache/wine/ ; cp -Rvp AutoHotkey104805_Install.exe /home/runner/.cache/winetricks/ahk

# Create WINEPREFIX
wineboot ; sleep 5
winetricks -q dotnet20 ; sleep 5

# Install game
(wine RedAlert1_Online_Installer.exe /silent ; sleep 20)
ls -al ./

# Launch game
wine ./RedAlert1_Online/RA1MPLauncher.exe &
sleep 10
wineserver -k

cp -Rvp ./RedAlert1_Online "$WINEPREFIX"/drive_c/

# Removing any existing user data
( cd "$WINEPREFIX/drive_c/" ; rm -rf users ; rm windows/temp/* ) || true

cp -Rvp $WINEPREFIX ra-mp/ ; rm -rf $WINEPREFIX ; rm -rf ./ra-mp/winedata

( cd ra-mp ; wget -qO- 'https://gist.github.com/mmtrt/6d111388fadf6a08b7f4c41cdc250080/raw/f8367c582eaf6e286c3844abf80beb168d028b73/cncraswp.patch' | patch -p1 )

export ARCH=x86_64; squashfs-root/AppRun -v ./ra-mp -n -u "gh-releases-zsync|mmtrt|cncra_AppImage|stable-wp|cncra*.AppImage.zsync" cncra_WP-${ARCH}.AppImage

}

if [ "$1" == "stable" ]; then
    cncras
elif [ "$1" == "stablewp" ]; then
    cncraswp
fi
