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

mkdir -p ra-mp/usr/bin ; cp wine ra-mp/usr/bin ; cp wineserver ra-mp/usr/bin ; cp cncra.desktop ra-mp ; cp AppRun ra-mp ;

# Convert and copy icon which is needed for desktop integration into place:
wget https://github.com/mmtrt/cncra/raw/master/snap/gui/cncra.png &>/dev/null
for width in 8 16 22 24 32 36 42 48 64 72 96 128 192 256; do
    dir=icons/hicolor/${width}x${width}/apps
    mkdir -p $dir
    convert cncra.png -resize ${width}x${width} $dir/cncra.png
done

cp -r icons ra-mp/usr/share ; cp cncra.png ra-mp

apt download libfuse2 unionfs-fuse && ls -al
wget -q https://github.com/Winetricks/winetricks/raw/master/src/winetricks && chmod +x winetricks && cp -Rvp winetricks "$HOME/bin"
find ./ -name '*.deb' -exec dpkg -x {} . \;
cp -Rvp ./usr/{bin,sbin} ra-mp/usr/ && cp -Rvp ./lib ra-mp/usr/

(mkdir -p $HOME/.cache/wine ; cd $HOME/.cache/wine ; wget -q "https://dl.winehq.org/wine/wine-mono/4.9.4/wine-mono-4.9.4.msi")

export WINEDLLOVERRIDES="mshtml="
export WINEARCH="win32"
export WINEPREFIX=$(readlink -f ./.wine)

# Create WINEPREFIX
wineboot && sleep 5
winetricks --unattended dotnet20 && sleep 5

(wget -q "https://downloads.cncnet.org/RedAlert1_Online_Installer.exe" ; wine RedAlert1_Online_Installer.exe /silent ; sleep 20)

cp -Rvp ./RedAlert1_Online ./.wine/drive_c/

# Disable WINEPREFIX changes
echo "disable" > "$WINEPREFIX/.update-timestamp"

# Removing any existing user data
( cd "$WINEPREFIX/drive_c/" ; rm -rf users ; rm windows/Installer/* ) || true

# Pre patching dpi setting in WINEPREFIX
# DPI dword value 240=f0 180=b4 120=78 110=6e 96=60
( cd "$WINEPREFIX"; sed -i 's|"LogPixels"=dword:00000060|"LogPixels"=dword:00000078|' user.reg ; sed -i '/"WheelScrollLine*/a\\"LogPixels"=dword:00000078' user.reg ) || true

cp -Rvp ./.wine ra-mp/ ;

wget -c "https://github.com/AppImage/AppImageKit/releases/download/continuous/appimagetool-x86_64.AppImage"
chmod +x ./appimagetool-x86_64.AppImage
./appimagetool-x86_64.AppImage --appimage-extract

export ARCH=x86_64; squashfs-root/AppRun -v ./ra-mp -u "gh-releases-zsync|mmtrt|cncra_AppImage|continuous-testing|cncra*.AppImage.zsync" cncra_${ARCH}.AppImage
