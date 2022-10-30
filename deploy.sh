#!/bin/bash

cncras () {

# Download icon:
wget -q https://github.com/mmtrt/cncra/raw/master/snap/gui/cncra.png

wget -q "https://github.com/AppImageCrafters/appimage-builder/releases/download/v1.0.3/appimage-builder-1.0.3-x86_64.AppImage" -O builder ; chmod +x builder

mkdir -p ra-mp/usr/share/icons ra-mp/winedata ; cp cncra.desktop ra-mp ; cp wrapper ra-mp ; cp cncra.png ra-mp/usr/share/icons

wget -q "https://dl.winehq.org/wine/wine-mono/4.7.5/wine-mono-4.7.5.msi"
wget -q "https://downloads.cncnet.org/RedAlert1_Online_Installer.exe"
wget -q "https://download.lenovo.com/ibmdl/pub/pc/pccbbs/thinkvantage_en/dotnetfx.exe"
wget -q "https://github.com/AutoHotkey/AutoHotkey/releases/download/v1.0.48.05/AutoHotkey104805_Install.exe"

cp -Rp ./*.exe ra-mp/winedata ; cp -Rp ./*.msi ra-mp/winedata

mkdir -p AppDir/winedata ; cp -r "ra-mp/"* AppDir

NVDV=$(wget "https://launchpad.net/~graphics-drivers/+archive/ubuntu/ppa/+packages?field.name_filter=&field.status_filter=published&field.series_filter=kinetic" -qO- | grep -Eo drivers-.*changes | sed -r "s|_| |g;s|-| |g" | tail -n1 | awk '{print $9}')

sed -i "s|520|$NVDV|" cncra.yml

./builder --recipe cncra.yml

}

cncraswp () {

export WINEDLLOVERRIDES="mshtml="
export WINEARCH="win32"
export WINEPREFIX="/home/runner/work/cncra_AppImage/cncra_AppImage/AppDir/winedata/.wine"
export WINEDEBUG="-all"

wget -q https://github.com/mmtrt/cncra/raw/master/snap/gui/cncra.png

wget -q "https://github.com/AppImageCrafters/appimage-builder/releases/download/v1.0.3/appimage-builder-1.0.3-x86_64.AppImage" -O builder ; chmod +x builder

mkdir -p ra-mp/usr/share/icons ra-mp/winedata ; cp cncra.desktop ra-mp ; cp wrapper ra-mp ; cp cncra.png ra-mp/usr/share/icons

wget -q "https://dl.winehq.org/wine/wine-mono/4.7.5/wine-mono-4.7.5.msi"
wget -q "https://downloads.cncnet.org/RedAlert1_Online_Installer.exe"
wget -q "https://download.lenovo.com/ibmdl/pub/pc/pccbbs/thinkvantage_en/dotnetfx.exe"
wget -q "https://github.com/AutoHotkey/AutoHotkey/releases/download/v1.0.48.05/AutoHotkey104805_Install.exe"

wget -q https://github.com/mmtrt/WINE_AppImage/releases/download/continuous-stable-4-i386/wine-stable-i386_4.0.4-x86_64.AppImage
chmod +x *.AppImage ; mv wine-stable-i386_4.0.4-x86_64.AppImage wine-stable.AppImage

# Create winetricks & wine cache
mkdir -p /home/runner/.cache/{wine,winetricks}/{dotnet20,ahk} ; cp dotnetfx.exe /home/runner/.cache/winetricks/dotnet20
cp -Rp *.msi /home/runner/.cache/wine/ ; cp -Rp AutoHotkey104805_Install.exe /home/runner/.cache/winetricks/ahk ; mv wrapper bak

# Create WINEPREFIX
./wine-stable.AppImage winetricks -q dotnet20 ; sleep 5

# Install game
( ./wine-stable.AppImage RedAlert1_Online_Installer.exe /silent ; sleep 5 )

# Download game updates manually
for pkgs in CnCNet5Version.txt cncnet5.7z GeoIP.7z hints.7z _Servers.7z; do
wget -q "https://downloads.cncnet.org/updates/cncnet5/${pkgs}"
if [[ $pkgs = "CnCNet5Version.txt" ]]; then
mkdir -p tmp/CnCNet5/Others ; mv $pkgs tmp/CnCNet5/Others
elif [[ $pkgs = "_Servers.7z" || $pkgs = "GeoIP.7z" || $pkgs = "hints.7z" ]]; then
7z x -aos "$pkgs" "-otmp/CnCNet5/Others" &>/dev/null
elif [[ $pkgs = "Icons.7z" || $pkgs = "LAN.7z" || $pkgs = "Language.7z" || $pkgs = "Sounds.7z" ]]; then
7z x -aos "$pkgs" "-otmp/CnCNet5" &>/dev/null
elif [[ $pkgs = "cncnet5.7z" ]]; then
7z x "$pkgs" -so > "tmp/cncnet5.exe"
else
7z x -aos "$pkgs" "-otmp" &>/dev/null
fi
done

cp -Rp tmp/* RedAlert1_Online/ ; rm ./*.7z
cp -Rp ./RedAlert1_Online "$WINEPREFIX"/drive_c/

# Removing any existing user data
( cd "$WINEPREFIX/drive_c/" ; rm -rf users ) || true

echo "disabled" > $WINEPREFIX/.update-timestamp

mkdir -p AppDir/winedata ; cp -r "ra-mp/"* AppDir

NVDV=$(wget "https://launchpad.net/~graphics-drivers/+archive/ubuntu/ppa/+packages?field.name_filter=&field.status_filter=published&field.series_filter=kinetic" -qO- | grep -Eo drivers-.*changes | sed -r "s|_| |g;s|-| |g" | tail -n1 | awk '{print $9}')

sed -i "s|520|$NVDV|" cncra.yml

sed -i "22s/"1.0"/"1.0_WP"/" cncra.yml

sed -i 's/stable|/stable-wp|/' cncra.yml

./builder --recipe cncra.yml

}

if [ "$1" == "stable" ]; then
    cncras
    ( mkdir -p dist ; mv cncra*.AppImage* dist/. ; cd dist || exit ; chmod +x ./*.AppImage )
elif [ "$1" == "stablewp" ]; then
    cncraswp
    ( mkdir -p dist ; mv cncra*.AppImage* dist/. ; cd dist || exit ; chmod +x ./*.AppImage )
fi
