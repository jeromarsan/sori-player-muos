#!/bin/sh
# HELP: Sori Player - lecteur de musique (albums, pochettes, L1/R1)
# ICON: music
# GRID: Sori Player
. /opt/muos/script/var/func.sh
APPDIR="$(cd "$(dirname "$0")" && pwd)"
LOG="$APPDIR/sori.log"
cd "$APPDIR" || exit 1
: > "$LOG"
{
  echo "== Sori Player diagnostic $(date) =="
  echo "APPDIR=$APPDIR"
  echo "-- love trouve :"; command -v love
  echo "-- fichiers love* (profondeur 6) :"
  find /mnt /run/muos/storage /opt -maxdepth 6 \( -iname 'love*' -o -iname '*love*.squashfs' \) 2>/dev/null | head -n 20
  echo "-- PortMaster libs :"; ls /mnt/mmc/MUOS/PortMaster/libs /mnt/sdcard/MUOS/PortMaster/libs 2>&1 | head -n 20
  echo "-- bin/ de l'appli :"; ls -la "$APPDIR/bin" 2>&1 | head
  echo "-- musique :"; ls -d /mnt/mmc/MUSIC /mnt/sdcard/MUSIC /run/muos/storage/music 2>&1
  echo "-- langue console :"
  for f in /run/muos/global/settings/general/language /opt/muos/config/settings/general/language /opt/muos/config/language; do
    [ -f "$f" ] && echo "$f = $(cat "$f")"
  done
  grep -i '^ *language' /opt/muos/config/config.ini 2>/dev/null
  echo "LANG=$LANG LC_ALL=$LC_ALL LANGUAGE=$LANGUAGE"
} >>"$LOG" 2>&1
export XDG_DATA_HOME="$APPDIR/save"; mkdir -p "$XDG_DATA_HOME"
export SORI_FULLSCREEN=1 SORI_DIR="$APPDIR"
# luminosité enregistrée dans muOS : l'appli la remet en rallumant l'écran (veille écran pendant la lecture)
SORI_BRIGHT="$(GET_VAR "config" "settings/general/brightness" 2>/dev/null)"; export SORI_BRIGHT
echo "SORI_BRIGHT=$SORI_BRIGHT" >>"$LOG"
[ -f "$APPDIR/gamecontrollerdb.txt" ] && export SDL_GAMECONTROLLERCONFIG_FILE="$APPDIR/gamecontrollerdb.txt"
LOVE=""
addlib() { [ -d "$1" ] && export LD_LIBRARY_PATH="$1:$LD_LIBRARY_PATH"; }
use() { # $1 = binaire ; reste = dossiers de libs
  B="$1"; shift
  [ -f "$B" ] || return 1
  if [ ! -x "$B" ]; then cp "$B" /tmp/sori_love 2>>"$LOG" && chmod +x /tmp/sori_love && B=/tmp/sori_love; fi
  [ -x "$B" ] || return 1
  LOVE="$B"; for d in "$@"; do addlib "$d"; done; return 0
}
# 1) binaire fourni avec l'appli
use "$APPDIR/bin/love" "$APPDIR/bin/lib"
# 2) runtime PortMaster déjà extrait (cas de la RG40XXV sous muOS)
if [ -z "$LOVE" ]; then
  for RT in /mnt/mmc/MUOS/PortMaster/runtimes/love_11* /mnt/sdcard/MUOS/PortMaster/runtimes/love_11* /run/muos/storage/MUOS/PortMaster/runtimes/love_11*; do
    [ -d "$RT" ] || continue
    use "$RT/love.aarch64" "$RT/libs.aarch64" "$RT/lib" "$RT" && break
  done
fi
# 3) runtime PortMaster en squashfs
if [ -z "$LOVE" ]; then
  SQ="$(find /mnt/mmc /mnt/sdcard /run/muos/storage -maxdepth 6 -name 'love_11*.squashfs' 2>/dev/null | head -n 1)"
  if [ -n "$SQ" ]; then
    MNT=/tmp/sori_mnt; mkdir -p "$MNT"
    mountpoint -q "$MNT" 2>/dev/null || mount -t squashfs -o loop "$SQ" "$MNT" >>"$LOG" 2>&1
    use "$MNT/love.aarch64" "$MNT/libs.aarch64" "$MNT/lib" || use "$MNT/love" "$MNT/libs.aarch64" "$MNT/lib"
  fi
fi
# 4) love d'une autre appli installée, ou du système
[ -z "$LOVE" ] && use /run/muos/storage/application/XMPlayer/.xmplayer/bin/love /run/muos/storage/application/XMPlayer/.xmplayer/bin/lib
[ -z "$LOVE" ] && command -v love >/dev/null 2>&1 && LOVE="$(command -v love)"
echo "LOVE choisi : $LOVE" >>"$LOG"
echo "LD_LIBRARY_PATH=$LD_LIBRARY_PATH" >>"$LOG"
ls -la /mnt/mmc/MUOS/PortMaster/runtimes/love_11.5 >>"$LOG" 2>&1
[ -z "$LOVE" ] && { echo "LOVE 11.x aarch64 introuvable : copie-le dans $APPDIR/bin/love" >>"$LOG"; exit 1; }
SETUP_APP "love" "" >>"$LOG" 2>&1
echo "Lancement : $LOVE $APPDIR" >>"$LOG"
"$LOVE" "$APPDIR" >>"$LOG" 2>&1
CODE=$?
# sécurité : si l'appli s'est fermée écran éteint, on le rallume
if [ -x /opt/muos/script/device/bright.sh ] && [ -n "$SORI_BRIGHT" ] && [ "$SORI_BRIGHT" -gt 0 ] 2>/dev/null; then
  /opt/muos/script/device/bright.sh "$SORI_BRIGHT" >>"$LOG" 2>&1
fi
echo "LOVE termine, code $CODE" >>"$LOG"
