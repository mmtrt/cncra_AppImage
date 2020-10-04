#!/bin/bash

cat > wine <<'EOF'
#!/bin/bash
export winecmd=$(find $HOME/Downloads $HOME/bin $HOME/.local/bin -type f \( -name '*.appimage' -o -name '*.AppImage' \) 2>/dev/null | grep -e "wine-stable" -e 'Wine-stable' | head -n 1)
$winecmd "$@"
EOF
chmod +x wine

cat > wineserver <<'EOF1'
#!/bin/bash
export winecmd=$(find $HOME/Downloads $HOME/bin $HOME/.local/bin -type f \( -name '*.appimage' -o -name '*.AppImage' \) 2>/dev/null | grep -e "wine-stable" -e 'Wine-stable' | head -n 1)
$winecmd "$@"
EOF1
chmod +x wineserver

mkdir -p ra-mp/usr/bin ra-mp/winedata ; cp wine ra-mp/usr/bin ; cp wineserver ra-mp/usr/bin ; cp cncra.desktop ra-mp ; cp AppRun ra-mp ;

# Convert and copy icon which is needed for desktop integration into place:
wget https://github.com/mmtrt/cncra/raw/master/snap/gui/cncra.png &>/dev/null
for width in 8 16 22 24 32 36 42 48 64 72 96 128 192 256; do
    dir=icons/hicolor/${width}x${width}/apps
    mkdir -p $dir
    convert cncra.png -resize ${width}x${width} $dir/cncra.png
done

cp -r icons ra-mp/usr/share ; cp cncra.png ra-mp

wget "https://dl.winehq.org/wine/wine-mono/4.9.4/wine-mono-4.9.4.msi"
wget "https://downloads.cncnet.org/RedAlert1_Online_Installer.exe"
wget "https://download.lenovo.com/ibmdl/pub/pc/pccbbs/thinkvantage_en/dotnetfx.exe"

cp -Rvp ./*.exe ra-mp/winedata ; cp -Rvp ./*.msi ra-mp/winedata

wget -c "https://github.com/AppImage/AppImageKit/releases/download/continuous/appimagetool-x86_64.AppImage"
chmod +x ./appimagetool-x86_64.AppImage
./appimagetool-x86_64.AppImage --appimage-extract

export ARCH=x86_64; squashfs-root/AppRun -v ./ra-mp -u "gh-releases-zsync|mmtrt|cncra_AppImage|continuous-testing|cncra*.AppImage.zsync" cncra_${ARCH}.AppImage
