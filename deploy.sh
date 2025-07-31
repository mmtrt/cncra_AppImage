#!/bin/bash

cncras () {

# Download icon:
wget -q https://github.com/mmtrt/cncra/raw/master/snap/gui/cncra.png

wget -q "https://github.com/AppImageCrafters/appimage-builder/releases/download/v1.1.0/appimage-builder-1.1.0-x86_64.AppImage" -O builder ; chmod +x builder ; ./builder --appimage-extract &>/dev/null

# add custom mksquashfs
wget -q "https://github.com/mmtrt/WINE_AppImage/raw/master/runtime/mksquashfs" -O squashfs-root/usr/bin/mksquashfs

# force zstd format in appimagebuilder for appimages
rm builder ; sed -i 's|xz|zstd|;s|AppImageKit|type2-runtime|' squashfs-root/usr/lib/python3.8/site-packages/appimagebuilder/modules/prime/appimage_primer.py

mkdir -p ra-mp/usr/share/icons ra-mp/winedata ; cp cncra.desktop ra-mp ; cp wrapper ra-mp ; cp cncra.png ra-mp/usr/share/icons

wget -q "https://dl.winehq.org/wine/wine-mono/4.7.5/wine-mono-4.7.5.msi"
wget -q "https://downloads.cncnet.org/RedAlert1_Online_Installer.exe"
wget -q "https://download.lenovo.com/ibmdl/pub/pc/pccbbs/thinkvantage_en/dotnetfx.exe"
wget -q "https://github.com/AutoHotkey/AutoHotkey/releases/download/v1.0.48.05/AutoHotkey104805_Install.exe"

cp -Rp ./*.exe ra-mp/winedata ; cp -Rp ./*.msi ra-mp/winedata

mkdir -p AppDir/winedata ; cp -r "ra-mp/"* AppDir

# NVDV=$(wget "https://launchpad.net/~graphics-drivers/+archive/ubuntu/ppa/+packages?field.name_filter=&field.status_filter=published&field.series_filter=kinetic" -qO- | grep -Eo drivers-.*changes | sed -r "s|_| |g;s|-| |g" | tail -n1 | awk '{print $9}')

# sed -i "s|520|$NVDV|" cncra.yml

./squashfs-root/AppRun --skip-appimage --recipe cncra.yml

rm *.AppImage

export ARCH="$(uname -m)"
export APPIMAGE_EXTRACT_AND_RUN=1
UPINFO="gh-releases-zsync|$(echo "$GITHUB_REPOSITORY" | tr '/' '|')|stable|*$ARCH.AppImage.zsync"
VERSION="1.0"
URUNTIME="https://github.com/VHSgunzo/uruntime/releases/latest/download/uruntime-appimage-dwarfs-$ARCH"
URUNTIME_LITE="https://github.com/VHSgunzo/uruntime/releases/latest/download/uruntime-appimage-dwarfs-lite-$ARCH"
wget --retry-connrefused --tries=30 "$URUNTIME" -O ./uruntime
wget --retry-connrefused --tries=30 "$URUNTIME_LITE" -O ./uruntime-lite
chmod +x ./uruntime*

# Keep the mount point (speeds up launch time)
sed -i 's|URUNTIME_MOUNT=[0-9]|URUNTIME_MOUNT=0|' ./uruntime-lite

# Add udpate info to runtime
echo "Adding update information \"$UPINFO\" to runtime..."
./uruntime-lite --appimage-addupdinfo "$UPINFO"

echo "Generating AppImage..."
./uruntime --appimage-mkdwarfs -f --set-owner 0 --set-group 0 --no-history --no-create-timestamp --compression zstd:level=22 -S26 -B8 --header uruntime-lite -i AppDir -o ./cncra-"$VERSION"-"$ARCH".AppImage

echo "Generating zsync file..."
zsyncmake *.AppImage -u *.AppImage
ls -al
}

cncraswp () {

export WINEDLLOVERRIDES="mshtml="
export WINEARCH="win32"
export WINEPREFIX="/home/runner/work/cncra_AppImage/cncra_AppImage/AppDir/winedata/.wine"
export WINEDEBUG="-all"

wget -q https://github.com/mmtrt/cncra/raw/master/snap/gui/cncra.png

wget -q "https://github.com/AppImageCrafters/appimage-builder/releases/download/v1.1.0/appimage-builder-1.1.0-x86_64.AppImage" -O builder ; chmod +x builder ; ./builder --appimage-extract &>/dev/null

# add custom mksquashfs
wget -q "https://github.com/mmtrt/WINE_AppImage/raw/master/runtime/mksquashfs" -O squashfs-root/usr/bin/mksquashfs

# force zstd format in appimagebuilder for appimages
rm builder ; sed -i 's|xz|zstd|;s|AppImageKit|type2-runtime|' squashfs-root/usr/lib/python3.8/site-packages/appimagebuilder/modules/prime/appimage_primer.py

mkdir -p ra-mp/usr/share/icons ra-mp/winedata ; cp cncra.desktop ra-mp ; cp wrapper ra-mp ; cp cncra.png ra-mp/usr/share/icons

wget -q "https://downloads.cncnet.org/RedAlert1_Online_Installer.exe"
wget -q "https://download.lenovo.com/ibmdl/pub/pc/pccbbs/thinkvantage_en/dotnetfx.exe"
wget -q "https://github.com/AutoHotkey/AutoHotkey/releases/download/v1.0.48.05/AutoHotkey104805_Install.exe"

wget -q https://github.com/mmtrt/WINE_AppImage/releases/download/continuous-stable-4-i386/wine-stable-i386_4.0.4-x86_64.AppImage
chmod +x *.AppImage ; mv wine-stable-i386_4.0.4-x86_64.AppImage wine-stable.AppImage

# Create winetricks & wine cache
mkdir -p /home/runner/.cache/{wine,winetricks}/{dotnet20,ahk} ; cp dotnetfx.exe /home/runner/.cache/winetricks/dotnet20
cp -Rp AutoHotkey104805_Install.exe /home/runner/.cache/winetricks/ahk ; mv wrapper bak

# Create WINEPREFIX
./wine-stable.AppImage wineboot -i ; sleep 5
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

# NVDV=$(wget "https://launchpad.net/~graphics-drivers/+archive/ubuntu/ppa/+packages?field.name_filter=&field.status_filter=published&field.series_filter=kinetic" -qO- | grep -Eo drivers-.*changes | sed -r "s|_| |g;s|-| |g" | tail -n1 | awk '{print $9}')

# sed -i "s|520|$NVDV|" cncra.yml

sed -i "17s/"1.0"/"1.0_WP"/" cncra.yml

sed -i 's/stable|/stable-wp|/' cncra.yml

./squashfs-root/AppRun --skip-appimage --recipe cncra.yml

rm *.AppImage

export ARCH="$(uname -m)"
export APPIMAGE_EXTRACT_AND_RUN=1
UPINFO="gh-releases-zsync|$(echo "$GITHUB_REPOSITORY" | tr '/' '|')|stable-wp|*$ARCH.AppImage.zsync"
VERSION="1.0"
URUNTIME="https://github.com/VHSgunzo/uruntime/releases/latest/download/uruntime-appimage-dwarfs-$ARCH"
URUNTIME_LITE="https://github.com/VHSgunzo/uruntime/releases/latest/download/uruntime-appimage-dwarfs-lite-$ARCH"
wget --retry-connrefused --tries=30 "$URUNTIME" -O ./uruntime
wget --retry-connrefused --tries=30 "$URUNTIME_LITE" -O ./uruntime-lite
chmod +x ./uruntime*

# Keep the mount point (speeds up launch time)
sed -i 's|URUNTIME_MOUNT=[0-9]|URUNTIME_MOUNT=0|' ./uruntime-lite

echo "Adding update information \"$UPINFO\" to runtime..."
./uruntime-lite --appimage-addupdinfo "$UPINFO"

echo "Generating AppImage..."
./uruntime --appimage-mkdwarfs -f --set-owner 0 --set-group 0 --no-history --no-create-timestamp --compression zstd:level=22 -S26 -B8 --header uruntime-lite -i AppDir -o ./cncra-"$VERSION"_WP-"$ARCH".AppImage

echo "Generating zsync file..."
zsyncmake *.AppImage -u *.AppImage
ls -al

}

if [ "$1" == "stable" ]; then
    cncras
    ( mkdir -p dist ; mv cncra*.AppImage* dist/. ; cd dist || exit ; chmod +x ./*.AppImage )
elif [ "$1" == "stablewp" ]; then
    cncraswp
    ( mkdir -p dist ; mv cncra*.AppImage* dist/. ; cd dist || exit ; chmod +x ./*.AppImage )
fi
