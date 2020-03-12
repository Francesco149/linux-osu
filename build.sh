#!/bin/sh

cd "$(dirname "$0")" || exit
mkdir ./bak >/dev/null 2>&1

if ! [ -d ./wine/.git ]; then
  rm -rf ./wine >/dev/null 2>&1
  git clone \
    --depth=1 \
    https://github.com/wine-mirror/wine \
    --branch wine-5.3 \
    --single-branch || exit
else
  echo "=== wine repository already found. delete $(pwd)/wine"
  echo "===   if you think it's broken or want to force an update"
fi

if ! [ -d ./wrk ]; then
  cp -r ./wine ./wrk || exit
  cd ./wrk || exit
  for p in ../*.patch; do
    patch -p1 < "$p" || exit
  done
  ./configure
  make "-j$(nproc)" dlls/winealsa.drv dlls/winepulse.drv || exit
else
  echo "=== patched binaries already found. delete $(pwd)/wrk"
  echo "===   if you think it's broken or want to force a rebuild"
fi

if ! [ -f ./winetricks ]; then
  wget https://raw.githubusercontent.com/Winetricks/winetricks/master/src/winetricks || exit
  chmod +x ./winetricks || exit
else
  echo "=== winetricks already found. delete $(pwd)/winetricks"
  echo "===   if you think it's broken or want to force an update"
fi

WINEPREFIX="$(pwd)/pfx" || exit
export WINEPREFIX
wineserver -k

necho() {
  echo "=== $* ==="
  notify-send "$@"
}

if ! [ -d ./pfx ]; then
  necho "cancel the wine gecko/mono installs"
  wineboot || exit
  ./winetricks -q dotnet48 cjkfonts gdiplus || exit
  curl 'https://m1.ppy.sh/r/osu!install.exe' > 'osu!install.exe' || exit
  necho "please don't change the osu install location. close the game after it starts"
  WINEDEBUG=-all wine './osu!install.exe'
  wineserver -w
  wineserver -k
  WINEDEBUG=-all wine regedit ./dsound.reg
  wineserver -w
  wineserver -k
  osuexe=$(find ./pfx/drive_c -name 'osu!.exe') || exit
  osufolder="$(realpath "$(dirname "$osuexe")")"
  if [ -d ./folder ]; then
    rm -rf "$osufolder"
  else
    mv "$osufolder" ./folder
  fi
  ln -sv "$(pwd)/folder" "$osufolder"
else
  echo "=== wine prefix already found. delete $(pwd)/pfx"
  echo "===   if you think it's broken or want to force an update"
fi

winealsa=$(find /usr/lib32 -name "winealsa.drv.so" -print -quit) || exit
winepulse=$(find /usr/lib32 -name "winepulse.drv.so" -print -quit) || exit

if ! cmp ./wrk/dlls/winealsa.drv/winealsa.drv.so "$winealsa" ||
   ! cmp ./wrk/dlls/winepulse.drv/winepulse.drv.so "$winepulse"; then
  if ! cmp ./wrk/dlls/winealsa.drv/winealsa.drv.so "$winealsa"; then
    cp -i -v "$winealsa" "./bak/winealsa.drv-$(date "+%F_%H-%M-%S")" || exit
    sudo cp -i -v ./wrk/dlls/winealsa.drv/winealsa.drv.so "$winealsa"  || exit
  fi
  if ! cmp ./wrk/dlls/winepulse.drv/winepulse.drv.so "$winepulse"; then
    cp -i -v "$winepulse" "./bak/winepulse.drv-$(date "+%F_%H-%M-%S")" || exit
    sudo cp -i -v ./wrk/dlls/winepulse.drv/winepulse.drv.so "$winepulse" || exit
  fi
else
  echo "=== patched wine dlls appear to match. move/delete $winealsa and $winepulse"
  echo "===   if you think it's broken or want to force an update"
fi

osuexe="$(pwd)/folder/osu!.exe" || exit
cat > osu << EOF
#!/bin/sh

export WINEDEBUG=-all
export WINEPREFIX="$(pwd)/pfx"
export WINEARCH=win32
export vblank_mode=0
export STAGING_AUDIO_DURATION=\${STAGING_AUDIO_DURATION:-50000}
export STAGING_AUDIO_DEFAULT_PERIOD=\${STAGING_AUDIO_DEFAULT_PERIOD:-10000}
export STAGING_AUDIO_MIN_PERIOD=\${STAGING_AUDIO_MIN_PERIOD:-100}
export STAGING_AUDIO_EXTRA_SAFE_RT=\${STAGING_AUDIO_EXTRA_SAFE_RT:-500}

case "\$1" in
  kill) exec wineserver -k ;;
esac

exec nice -99 wine "$(realpath "$osuexe")"
EOF

chmod +x ./osu
sudo cp -i ./osu /usr/bin/osu

echo "===================================================================="
echo "=== you can run the game by running 'osu'"
echo "=== the symlink located at '$(pwd)/folder' points to your osu folder"
echo "=== if you want to ensure osu and wine processes are killed, run 'osu kill'"
echo "===================================================================="
