#!/usr/bin/env bash

NAMA_TOOLS="LAVYNRA VIDEO CUTTER"
TOOLS_VERSION="01.1"
AUTHOR="@LAVYNRA"
OUT_DIRNAME="LAVYNRA_Cutter"   
PER_PAGE=8                     
KF_WINDOW=40                   
VIDEO_EXT=(mp4 mkv mov avi webm 3gp m4v flv mpg mpeg wmv)

RST=$'\e[0m';        BLD=$'\e[1m'
RED=$'\e[38;5;203m'; GRN=$'\e[38;5;84m';  YLW=$'\e[38;5;221m'
CYN=$'\e[38;5;51m';  MAG=$'\e[38;5;207m'; PUR=$'\e[38;5;141m'
GRY=$'\e[38;5;245m'
HIDE=$'\e[?25l';     SHOW=$'\e[?25h'

declare -A GLYPH=(
  [L]="█    |█    |█    |█    |█████"
  [A]=" ███ |█   █|█████|█   █|█   █"
  [V]="█   █|█   █|█   █| █ █ |  █  "
  [Y]="█   █| █ █ |  █  |  █  |  █  "
  [N]="█   █|██  █|█ █ █|█  ██|█   █"
  [R]="████ |█   █|████ |█  █ |█   █"
)

W=46
STORAGE=""; OUT_ROOT=""; WORK=""; PROG=""; LOG=""
FF_PID=""; NEW_OUT=""; RUNNING=0
VID_PATH=(); VID_SIZE=(); VID_TIME=(); ROOTS=()
SEL=""; NAME=""; EXT=""; SAFE=""; DURATION=""; INTERVAL=""
V_CODEC=""; V_W=""; V_H=""; V_FPS=""; A_CODEC=""; A_CH=""; KF_GAP=""
FULL=0; REM=0; EST=0
MODE="lossless"; V_AFR=""; V_RFR=""; WAKE=0; VERIFY_BAD=0
PROG_OFF=0; PART_NO=1; PAD=2; V_DUR=""


calc_width() {
  local c
  c=$(tput cols 2>/dev/null)
  [[ $c =~ ^[0-9]+$ ]] || c=46
  W=$c
  ((W > 48)) && W=48
  ((W < 34)) && W=34
}

rep() {                                   
  local s n=$2
  ((n < 0)) && n=0
  printf -v s '%*s' "$n" ''
  printf '%s' "${s// /$1}"
}

cls() {
    printf '\033[2J\033[3J\033[H'
}
center() { local n=$(( (W - ${#1}) / 2 )); ((n < 0)) && n=0; printf '%*s%s%s%s\n' "$n" '' "${2:-}" "$1" "$RST"; }
ok()     { printf ' %s✔%s %s\n' "$GRN" "$RST" "$*"; }
err()    { printf ' %s✘%s %s\n' "$RED" "$RST" "$*"; }
warn()   { printf ' %s!%s %s\n' "$YLW" "$RST" "$*"; }
info()   { printf ' %s➜%s %s\n' "$CYN" "$RST" "$*"; }
pause()  { printf '\n %sTekan ENTER untuk lanjut...%s' "$GRY" "$RST"; read -r _ || exit 0; }

trunc() {                                 
  local s="$1" n="$2"
  if ((${#s} > n)); then printf '%s…' "${s:0:n-1}"; else printf '%s' "$s"; fi
}

is_num() { [[ $1 =~ ^[0-9]+(\.[0-9]+)?$ ]]; }

hsize() {                                 
  local b=${1:-0} i=0 r=0 u=(B KB MB GB TB)
  while ((b >= 1024 && i < 4)); do
    r=$(( (b % 1024) * 10 / 1024 ))
    b=$(( b / 1024 ))
    i=$(( i + 1 ))
  done
  if ((i == 0)); then printf '%d B' "$b"; else printf '%d.%d %s' "$b" "$r" "${u[i]}"; fi
}

fmt_hms() {
  awk -v s="$1" 'BEGIN{ s=int(s+0.5); printf "%02d:%02d:%02d", int(s/3600), int((s%3600)/60), s%60 }'
}

num() {                                   
  awk -v n="$1" 'BEGIN{ s=sprintf("%.2f", n); sub(/0+$/, "", s); sub(/\.$/, "", s); print s }'
}

hms_to_sec() {
  awk -v t="$1" 'BEGIN{ n=split(t, a, ":"); if (n==3) printf "%.3f", a[1]*3600 + a[2]*60 + a[3] }'
}

yn() {                                    
  local def="${2:-Y}" a hint="[Y/n]"
  [ "$def" = N ] && hint="[y/N]"
  printf ' %s➜%s %s %s: ' "$CYN" "$RST" "$1" "$hint"
  read -r a || exit 0
  if [ -z "$a" ]; then [ "$def" = Y ]; return; fi
  [[ $a =~ ^[yY] ]]
}

box_top() { printf ' %s╭─ %s%s%s %s%s\n' "$PUR" "$BLD" "$1" "$RST$PUR" "$(rep '─' $((W - ${#1} - 6)))" "$RST"; }
box_sec() { printf ' %s├─ %s%s%s %s%s\n' "$PUR" "$BLD" "$1" "$RST$PUR" "$(rep '─' $((W - ${#1} - 6)))" "$RST"; }
box_bot() { printf ' %s╰%s%s\n' "$PUR" "$(rep '─' $((W - 3)))" "$RST"; }
box_row() { printf ' %s│%s %s\n' "$PUR" "$RST" "$*"; }
box_path() {                              
  local max=$((W - 5)) line="" seg first=1
  local -a segs
  IFS='/' read -r -a segs <<< "$1"
  for seg in "${segs[@]}"; do
    [ -n "$seg" ] || continue
    if [ -z "$line" ]; then
      if ((first)); then line="/$seg"; else line="$seg"; fi
    elif ((${#line} + ${#seg} + 1 > max)); then
      box_row "$line/"; first=0; line="$seg"
    else
      line+="/$seg"
    fi
  done
  [ -n "$line" ] && box_row "$line"
}

header_small() {
  calc_width; cls
  printf '\n %s%s%s\n' "$MAG" "$(rep '━' $((W - 2)))" "$RST"
  center "◆ $NAMA_TOOLS ◆  $AUTHOR" "$BLD$CYN"
  printf ' %s%s%s\n\n' "$MAG" "$(rep '━' $((W - 2)))" "$RST"
}

banner() {
  calc_width; cls
  local word="LAVYNRA" r i ch line pad lw=41
  local -a parts grad=(51 51 51 51 51)
  printf '\n %s%s%s\n' "$MAG" "$(rep '━' $((W - 2)))" "$RST"
  if ((W >= lw + 2)); then
    pad=$(( (W - lw) / 2 ))
    for r in 0 1 2 3 4; do
      line=""
      for ((i = 0; i < ${#word}; i++)); do
        ch="${word:i:1}"
        IFS='|' read -r -a parts <<< "${GLYPH[$ch]}"
        line+="${parts[r]} "
      done
      printf '%*s\e[38;5;%sm%s%s\n' "$pad" '' "${grad[r]}" "${line% }" "$RST"
      sleep 0.06
    done
  else
    center "L A V Y N R A" "$BLD$MAG"
  fi
  printf ' %s%s%s\n' "$MAG" "$(rep '━' $((W - 2)))" "$RST"
  center "VIDEO CUTTER  v$TOOLS_VERSION" "$BLD$CYN"
  center "Author  $AUTHOR" "$YLW"
  printf '\n'
}

welcome() {
  banner
  box_top "SELAMAT DATANG"
  box_row "Selamat datang di ${BLD}${CYN}LAVYNRA${RST} VIDEO CUTTER"
  box_sec "DESKRIPSI"
  box_row "Tools pemotong video yang ringan."
  box_row "Membagi video jadi beberapa bagian"
  box_row "berdurasi sama. Mode ${BLD}LOSSLESS${RST} tidak"
  box_row "mengurangi kualitas gambar & suara."
  box_sec "MEKANISME KERJA"
  box_row "${CYN}1.${RST} Pilih video dari daftar (nomor)"
  box_row "${CYN}2.${RST} Tools menganalisa durasi video"
  box_row "${CYN}3.${RST} Input durasi potongan (detik)"
  box_row "${CYN}4.${RST} Pilih mode potong:"
  box_row "   ${GRN}▸${RST} ${BLD}LOSSLESS${RST} kualitas 100% asli,"
  box_row "     cepat, durasi ikut keyframe"
  box_row "   ${GRN}▸${RST} ${BLD}PRESISI${RST} durasi tepat sama,"
  box_row "     re-encode kualitas tinggi"
  box_row "${CYN}5.${RST} Hasil disimpan di folder:"
  box_row "   ${YLW}LAVYNRA/${OUT_DIRNAME}${RST}"
  box_sec "CONTOH"
  box_row "Video 56 dtk, potong tiap 30 dtk:"
  box_row " ${GRN}▸${RST} Bagian 1 = 30 detik"
  box_row " ${GRN}▸${RST} Bagian 2 = 26 detik (sisa)"
  box_sec "AUTHOR"
  box_row "${YLW}★ ${BLD}${AUTHOR}${RST}"
  box_bot
  printf '\n %sTekan ENTER untuk mulai...%s' "$GRY" "$RST"
  read -r _ || exit 0
}

bye() {
  printf '\n'
  center "Terima kasih telah memakai" "$GRY"
  center "$NAMA_TOOLS" "$BLD$CYN"
  center "by $AUTHOR" "$YLW"
  printf '\n'
}

usage() {
  cat <<EOF
$NAMA_TOOLS v$TOOLS_VERSION  (by $AUTHOR)

Pemakaian:
  bash lavynra-cutter.sh            scan seluruh penyimpanan
  bash lavynra-cutter.sh /folder    scan folder tertentu saja
  bash lavynra-cutter.sh -h         bantuan ini
EOF
}


cleanup() {
  printf '%s' "$SHOW"
  if ((WAKE)); then termux-wake-unlock >/dev/null 2>&1; WAKE=0; fi
  if [ -n "$WORK" ] && [ -d "$WORK" ]; then rm -rf -- "$WORK"; fi
}

discard_output() {                        
  if [ -n "$NEW_OUT" ] && [ -d "$NEW_OUT" ]; then
    find "$NEW_OUT" -maxdepth 1 -type f -delete 2>/dev/null
    rmdir "$NEW_OUT" 2>/dev/null
  fi
  NEW_OUT=""
}

on_interrupt() {
  printf '%s\n\n' "$SHOW"
  if ((RUNNING)); then                    
    if [ -n "$FF_PID" ] && kill -0 "$FF_PID" 2>/dev/null; then
      kill "$FF_PID" 2>/dev/null
      wait "$FF_PID" 2>/dev/null
    fi
    discard_output
    warn "Proses dibatalkan. Hasil yang belum selesai dihapus."
  else
    warn "Keluar."
  fi
  exit 130
}

check_deps() {
  if command -v ffmpeg >/dev/null 2>&1 && command -v ffprobe >/dev/null 2>&1; then
    ok "FFmpeg terdeteksi"
    return 0
  fi
  warn "FFmpeg belum terpasang (wajib untuk memotong video)."
  if ! command -v pkg >/dev/null 2>&1; then
    err "Perintah 'pkg' tidak ada. Pasang ffmpeg secara manual."
    exit 1
  fi
  yn "Pasang FFmpeg sekarang?" Y || { err "Dibatalkan."; exit 1; }
  info "Menjalankan: pkg install -y ffmpeg"
  pkg install -y ffmpeg || { err "Gagal memasang ffmpeg."; exit 1; }
  command -v ffprobe >/dev/null 2>&1 || { err "ffprobe tidak ditemukan."; exit 1; }
  ok "FFmpeg berhasil dipasang"
}

find_storage() {
  local c
  for c in "$HOME/storage/shared" /sdcard /storage/emulated/0; do
    if [ -d "$c" ] && ls "$c" >/dev/null 2>&1; then
      STORAGE=$(readlink -f "$c")
      return 0
    fi
  done
  return 1
}

init_storage() {
  if find_storage; then ok "Akses penyimpanan aktif"; return 0; fi
  warn "Izin penyimpanan belum aktif."
  if command -v termux-setup-storage >/dev/null 2>&1; then
    info "Klik ${BLD}IZINKAN${RST} pada popup yang muncul..."
    termux-setup-storage
    local i
    for i in $(seq 1 30); do
      if find_storage; then ok "Akses penyimpanan aktif"; return 0; fi
      sleep 1
    done
  fi
  warn "Penyimpanan tidak bisa diakses, memakai folder HOME."
  STORAGE="$HOME"
}

scan_videos() {
  local t s p e
  local -a expr=()
  for e in "${VIDEO_EXT[@]}"; do expr+=(-o -iname "*.$e"); done
  expr=("${expr[@]:1}")

  VID_PATH=(); VID_SIZE=(); VID_TIME=()
  printf ' %s⟳ Memindai video...%s' "$CYN" "$RST"
  while IFS=$'\t' read -r t s p; do
    [ -n "$p" ] || continue
    VID_TIME+=("${t%.*}"); VID_SIZE+=("$s"); VID_PATH+=("$p")
  done < <(
    find "${ROOTS[@]}" -maxdepth 9 \
      \( -path '*/Android/data' -o -path '*/Android/obb' -o -path '*/.*' \
         -o -name node_modules -o -path "$OUT_ROOT" \) -prune -o \
      -type f -size +0 \( "${expr[@]}" \) \
      -printf '%T@\t%s\t%p\n' 2>/dev/null | sort -t $'\t' -k1,1nr
  )
  printf '\r\e[K'
}

draw_list() {                             
  local page=$1 pages=$2 total=${#VID_PATH[@]} start end i p name dir d dw
  dw=$((W - 31)); ((dw < 6)) && dw=6; ((dw > 14)) && dw=14
  start=$(( page * PER_PAGE )); end=$(( start + PER_PAGE ))
  ((end > total)) && end=$total
  header_small
  box_top "DAFTAR VIDEO"
  if ((total == 0)); then
    box_row "${YLW}Tidak ada video ditemukan.${RST}"
    box_row "${GRY}Ketik path file video secara manual.${RST}"
  else
    box_row "${GRY}Ditemukan${RST} ${BLD}${total}${RST} ${GRY}video • Hal $((page + 1))/${pages}${RST}"
  fi
  for ((i = start; i < end; i++)); do
    p="${VID_PATH[i]}"; name="${p##*/}"; dir="${p%/*}"; dir="${dir##*/}"
    printf -v d '%(%d/%m/%y)T' "${VID_TIME[i]}"
    box_row "${BLD}${CYN}$(printf '%2d' $((i + 1)))${RST}  $(trunc "$name" $((W - 11)))"
    box_row "    ${GRY}$(trunc "$dir" "$dw") • $(hsize "${VID_SIZE[i]}") • ${d}${RST}"
  done
  box_bot
  printf ' %sn%s=lanjut  %sp%s=balik  %sr%s=scan  %sq%s=keluar\n' \
    "$CYN" "$GRY" "$CYN" "$GRY" "$CYN" "$GRY" "$CYN" "$RST"
}

pick_video() {                            
  local page=0 pages total ans idx p msg=""
  while true; do
    total=${#VID_PATH[@]}
    pages=$(( (total + PER_PAGE - 1) / PER_PAGE ))
    ((pages < 1)) && pages=1
    ((page >= pages)) && page=$((pages - 1))
    draw_list "$page" "$pages"
    [ -n "$msg" ] && { printf ' %s\n' "$msg"; msg=""; }
    printf ' %s➜%s Pilih nomor video: ' "$CYN" "$RST"
    read -r ans || exit 0
    case "${ans,,}" in
      q|quit|exit|keluar) return 1 ;;
      n|'>')
        if ((page + 1 < pages)); then page=$((page + 1)); else msg="${YLW}! Ini halaman terakhir.${RST}"; fi ;;
      p|'<')
        if ((page > 0)); then page=$((page - 1)); else msg="${YLW}! Ini halaman pertama.${RST}"; fi ;;
      r) scan_videos; page=0 ;;
      '') ;;
      *)
        if [[ $ans =~ ^[0-9]{1,6}$ ]]; then
          idx=$((10#$ans))
          if ((idx >= 1 && idx <= total)); then SEL="${VID_PATH[idx-1]}"; return 0; fi
          msg="${RED}✘ Nomor $idx tidak ada di daftar.${RST}"
        else
          p="${ans/#\~/$HOME}"
          if [ -f "$p" ]; then SEL=$(readlink -f -- "$p"); return 0; fi
          msg="${RED}✘ Input tidak dikenal. Masukkan nomor video.${RST}"
        fi ;;
    esac
  done
}

get_duration() {
  local f="$1" d t
  d=$(ffprobe -v error -show_entries format=duration -of default=nw=1:nk=1 "$f" 2>/dev/null | head -n 1)
  is_num "$d" || d=$(ffprobe -v error -select_streams v:0 -show_entries stream=duration -of default=nw=1:nk=1 "$f" 2>/dev/null | head -n 1)
  if ! is_num "$d"; then               # cadangan: baca stream (tanpa decode)
    t=$(ffmpeg -nostdin -v error -nostats -progress pipe:1 -i "$f" -map 0:v:0 -c copy -f null - 2>/dev/null \
        | grep -a '^out_time=' | tail -n 1)
    d=$(hms_to_sec "${t#out_time=}")
  fi
  if is_num "$d" && awk -v d="$d" 'BEGIN{ exit !(d > 0) }'; then printf '%s' "$d"; fi
}

probe_info() {
  local f="$1" k v afr="" rfr="" fr rot=""
  V_CODEC=""; V_W=""; V_H=""; V_FPS=""; A_CODEC=""; A_CH=""

  while IFS='=' read -r k v; do
    case "$k" in
      codec_name)     V_CODEC="$v" ;;
      width)          V_W="$v" ;;
      height)         V_H="$v" ;;
      avg_frame_rate) afr="$v" ;;
      r_frame_rate)   rfr="$v" ;;
      rotation)       rot="$v" ;;
    esac
  done < <(ffprobe -v error -select_streams v:0 \
             -show_entries 'stream=codec_name,width,height,avg_frame_rate,r_frame_rate:stream_side_data=rotation' \
             -of default=nw=1 "$f" 2>/dev/null)
  [ -n "$V_CODEC" ] || return 1

  while IFS='=' read -r k v; do
    case "$k" in
      codec_name) A_CODEC="$v" ;;
      channels)   A_CH="$v" ;;
    esac
  done < <(ffprobe -v error -select_streams a:0 -show_entries stream=codec_name,channels \
             -of default=nw=1 "$f" 2>/dev/null)

  DURATION=$(get_duration "$f")
  [ -n "$DURATION" ] || return 1
  V_DUR=$(ffprobe -v error -select_streams v:0 -show_entries stream=duration -of default=nw=1:nk=1 "$f" 2>/dev/null | head -n 1)
  is_num "$V_DUR" || V_DUR=""

  V_AFR="$afr"; V_RFR="$rfr"
  fr="$afr"; { [ -z "$fr" ] || [ "$fr" = "0/0" ]; } && fr="$rfr"
  V_FPS=$(awk -v r="$fr" 'BEGIN{ split(r, a, "/"); if (a[2]+0 > 0) { s=sprintf("%.2f", a[1]/a[2]); sub(/0+$/, "", s); sub(/\.$/, "", s); print s } }')

  rot="${rot%.*}"; rot="${rot#-}"        
  if [ "$rot" = 90 ] || [ "$rot" = 270 ]; then k="$V_W"; V_W="$V_H"; V_H="$k"; fi
  return 0
}

probe_keyframes() {                       
  KF_GAP=$(ffprobe -v error -select_streams v:0 -read_intervals "%+$KF_WINDOW" \
             -show_entries packet=pts_time,flags -of csv=p=0 "$1" 2>/dev/null \
           | awk -F, '$2 ~ /K/ && $1 ~ /^[0-9]+(\.[0-9]+)?$/ { print $1 }' \
           | sort -n \
           | awk 'NR > 1 { g = $1 - p; if (g > m) m = g } { p = $1; n++ }
                  END { if (n >= 2) printf "%.1f", m; else if (n == 1) printf "-1" }')
}

analyze_video() {
  local f="$1" size mbps kf_txt res audio
  NAME="${f##*/}"
  header_small
  info "Menganalisa video..."
  if ! probe_info "$f"; then
    err "Video tidak bisa dibaca (rusak / bukan file video)."
    return 1
  fi
  probe_keyframes "$f"

  size=$(stat -c %s "$f" 2>/dev/null || echo 0)
  mbps=$(awk -v s="$size" -v d="$DURATION" 'BEGIN{ printf "%.1f", s*8/d/1000000 }')
  res="${V_CODEC} • ${V_W}x${V_H}"
  [ -n "$V_FPS" ] && res+=" • ${V_FPS} fps"
  if [ -n "$A_CODEC" ]; then audio="${A_CODEC}"; [ -n "$A_CH" ] && audio+=" • ${A_CH} ch"; else audio="tidak ada"; fi
  case "$KF_GAP" in
    '')  kf_txt="-" ;;
    -1)  kf_txt="sangat jarang" ;;
    *)   kf_txt="maks ${KF_GAP} detik" ;;
  esac

  header_small
  box_top "ANALISA VIDEO"
  box_row "${GRY}File     :${RST} $(trunc "$NAME" $((W - 15)))"
  box_row "${GRY}Ukuran   :${RST} $(hsize "$size")"
  box_row "${GRY}Durasi   :${RST} ${BLD}${GRN}$(fmt_hms "$DURATION")${RST}  ($(num "$DURATION") detik)"
  box_row "${GRY}Video    :${RST} $(trunc "$res" $((W - 15)))"
  box_row "${GRY}Audio    :${RST} $(trunc "$audio" $((W - 15)))"
  box_row "${GRY}Bitrate  :${RST} ${mbps} Mbps"
  box_row "${GRY}Keyframe :${RST} ${kf_txt}"
  box_bot
  return 0
}

ask_interval() {                          # return 0 = ok | 1 = keluar | 2 = kembali
  local ans
  while true; do
    printf '\n %sMau dipotong tiap berapa detik?%s\n' "$BLD" "$RST"
    printf ' %s(contoh: 30 | b=kembali | q=keluar)%s\n' "$GRY" "$RST"
    printf ' %s➜%s Masukkan detik: ' "$CYN" "$RST"
    read -r ans || exit 0
    case "${ans,,}" in
      q) return 1 ;;
      b) return 2 ;;
    esac
    if [[ ! $ans =~ ^[0-9]{1,7}$ ]]; then
      err "Masukkan angka bulat saja, contoh: 30"; continue
    fi
    ans=$((10#$ans))
    if ((ans < 1)); then err "Minimal 1 detik."; continue; fi
    if ! awk -v a="$ans" -v d="$DURATION" 'BEGIN{ exit !(a < d) }'; then
      err "Durasi video hanya $(num "$DURATION") detik. Masukkan angka yang lebih kecil."
      continue
    fi
    INTERVAL=$ans
    return 0
  done
}

precise_fps() {                          # fps keluaran mode PRESISI (CFR)
  awk -v a="$V_AFR" -v r="$V_RFR" '
    function val(s,  p) { split(s, p, "/"); return (p[2] + 0 > 0) ? p[1] / p[2] : 0 }
    BEGIN {
      av = val(a); rv = val(r)
      if (rv <= 0) { rv = av; r = a }
      if (av <= 0) { av = rv; a = r }
      if (rv <= 0) { print "30"; exit }
      d = (rv > av) ? rv - av : av - rv
      if (d / rv <= 0.05) { if (av > 120) print "120"; else print a }   # CFR: pakai fps asli
      else                { if (rv > 60) print "60"; else if (rv < 24) print "24"; else print r }   # VFR (rekaman layar): fps nominal, 24-60
    }'
}

verify_parts() {                          
  local -a files
  local i n d
  mapfile -t files < <(find "$NEW_OUT" -maxdepth 1 -type f 2>/dev/null | sort -V)
  n=${#files[@]}
  for ((i = 0; i < n - 1 && i < 40; i++)); do
    d=$(ffprobe -v error -show_entries format=duration -of default=nw=1:nk=1 "${files[i]}" 2>/dev/null | head -n 1)
    is_num "$d" || return 1
    awk -v d="$d" -v iv="$INTERVAL" 'BEGIN{ x = d - iv; if (x < 0) x = -x; exit !(x <= 0.35) }' || return 1
  done
  return 0
}

ask_mode() {                              
  local ans slow
  MODE="lossless"
  # keyframe sangat rapat (mis. all-intra) -> lossless sudah akurat, tidak perlu bertanya
  if [ -n "$KF_GAP" ] && [ "$KF_GAP" != "-1" ] && awk -v g="$KF_GAP" 'BEGIN{ exit !(g <= 0.1) }'; then
    return 0
  fi
  case "$KF_GAP" in
    '')  slow="durasi bisa meleset" ;;
    -1)  slow="bisa meleset jauh" ;;
    *)   slow="meleset s/d ${KF_GAP} dtk" ;;
  esac
  while true; do
    printf '\n %sPilih mode potong:%s\n' "$BLD" "$RST"
    printf '  %s1%s %sLOSSLESS%s kualitas 100%% asli\n' "$CYN" "$RST" "$BLD" "$RST"
    printf '    %scepat, %s%s\n' "$GRY" "$slow" "$RST"
    printf '  %s2%s %sPRESISI%s  durasi tepat sama\n' "$CYN" "$RST" "$BLD" "$RST"
    printf '    %sre-encode, lebih lama%s\n' "$GRY" "$RST"
    printf ' %s➜%s Pilih [1/2] (Enter = 1): ' "$CYN" "$RST"
    read -r ans || exit 0
    case "${ans,,}" in
      ''|1) MODE="lossless"; return 0 ;;
      2)
        if ffmpeg -hide_banner -encoders 2>/dev/null | grep -q libx264; then MODE="presisi"; return 0; fi
        err "Encoder libx264 tidak ada di ffmpeg ini." ;;
      b) return 2 ;;
      q) return 1 ;;
      *) err "Ketik 1 atau 2." ;;
    esac
  done
}

plan_parts() {                            
  local d="$DURATION"
  # video lebih pendek dari audio/container -> jumlah bagian mengikuti panjang video
  # (sisa audio di ujung ikut bagian terakhir, bukan jadi file audio-saja)
  if [ -n "$V_DUR" ] && awk -v v="$V_DUR" -v d="$DURATION" -v i="$INTERVAL" 'BEGIN{ exit !(v >= i && v < d - 0.05) }'; then d="$V_DUR"; fi
  FULL=$(awk -v d="$d" -v s="$INTERVAL" 'BEGIN{ printf "%d", int(d / s) }')
  REM=$(awk -v d="$d" -v s="$INTERVAL" -v f="$FULL" 'BEGIN{ r = d - f * s; if (r < 0.05) r = 0; printf "%.2f", r }')
  EST=$FULL
  if awk -v r="$REM" 'BEGIN{ exit !(r > 0) }'; then EST=$((FULL + 1)); fi
}

make_names() {
  local base="${NAME%.*}"
  EXT="${NAME##*.}"; EXT="${EXT,,}"
  [[ $NAME == *.* ]] || EXT="mp4"
  [ "$EXT" = m4v ] && EXT="mp4"
  [ "$MODE" = presisi ] && EXT="mp4"       # hasil re-encode selalu H.264 di .mp4
  SAFE="${base//%/_}"; SAFE="${SAFE//\//_}"
  [ -n "$SAFE" ] || SAFE="video"
}

make_outdir() {
  local base="$OUT_ROOT/${SAFE}_per${INTERVAL}s" d n=1
  [ "$MODE" = presisi ] && base+="_presisi"
  d="$base"
  while [ -e "$d" ]; do n=$((n + 1)); d="${base}_$n"; done
  mkdir -p "$d" 2>/dev/null || return 1
  NEW_OUT="$d"
}

confirm_plan() {
  plan_parts
  make_names
  header_small
  box_top "RINGKASAN"
  box_row "${GRY}Video    :${RST} $(trunc "$NAME" $((W - 15)))"
  box_row "${GRY}Durasi   :${RST} $(fmt_hms "$DURATION") ($(num "$DURATION") detik)"
  box_row "${GRY}Potong   :${RST} tiap ${BLD}${INTERVAL}${RST} detik"
  box_row "${GRY}Estimasi :${RST} ${BLD}${GRN}${EST} bagian${RST}"
  ((FULL > 0)) && box_row "  ${GRN}▸${RST} ${FULL} bagian × ${INTERVAL} detik"
  awk -v r="$REM" 'BEGIN{ exit !(r > 0) }' && box_row "  ${GRN}▸${RST} 1 bagian × $(num "$REM") detik (sisa)"
  if [ "$MODE" = presisi ]; then
    box_row "${GRY}Mode     :${RST} ${YLW}PRESISI${RST} (re-encode)"
  else
    box_row "${GRY}Mode     :${RST} LOSSLESS (stream-copy)"
  fi
  box_bot
  plan_notes
  printf '\n'
  yn "Mulai memotong?" Y
}

plan_notes() {
  if [ "$MODE" = presisi ]; then
    printf ' %sDurasi tiap bagian dibuat tepat.\n Video di-encode ulang (H.264).\n Lebih lama & HP bisa hangat.%s\n' "$GRY" "$RST"
    if [ "$V_CODEC" = hevc ]; then warn "Video HEVC jadi H.264,"; printf '   ukuran file bisa lebih besar.\n'; fi
    return 0
  fi
  case "$KF_GAP" in
    '')  printf ' %sPotongan mengikuti keyframe,\n durasi bisa meleset sedikit.%s\n' "$GRY" "$RST" ;;
    -1)  warn "Keyframe sangat jarang,"; printf '   potongan bisa meleset jauh.\n' ;;
    *)
      if awk -v g="$KF_GAP" -v i="$INTERVAL" 'BEGIN{ exit !(g > i) }'; then
        warn "Keyframe ${KF_GAP} dtk > durasi potong,"; printf '   hasil potongan kurang akurat.\n'
      else
        printf ' %sPotongan mengikuti keyframe,\n durasi bisa meleset s/d %s dtk.%s\n' "$GRY" "$KF_GAP" "$RST"
      fi ;;
  esac
}

read_out_time() {                         
  local t
  t=$(tail -n 30 "$1" 2>/dev/null | grep -a '^out_time=' | tail -n 1)
  t=${t#out_time=}
  if [[ $t =~ ^[0-9]+:[0-9]{2}:[0-9]{2}(\.[0-9]+)?$ ]]; then hms_to_sec "$t"; else echo 0; fi
}

render_bar() {                            
  local pct=$1 shown=$2 total=$3 extra="${4:-}" bw f e
  bw=$((W - 24 - ${#extra})); ((bw < 8)) && bw=8; ((bw > 30)) && bw=30
  f=$((pct * bw / 100)); e=$((bw - f))
  printf '\r\e[K %s%s%s%s%s %3d%% %s•%s %d/%d %s•%s %ds%s' \
    "$GRN" "$(rep '█' "$f")" "$GRY" "$(rep '░' "$e")" "$RST" \
    "$pct" "$GRY" "$RST" "$shown" "$total" "$GRY" "$RST" "$SECONDS" "$extra"
}

draw_progress() {
  local cur pct n shown sp=""
  cur=$(read_out_time "$PROG")
  pct=$(awk -v t="$cur" -v o="$PROG_OFF" -v d="$DURATION" 'BEGIN{ p = (d > 0) ? int((t + o) * 100 / d) : 0; if (p > 99) p = 99; if (p < 0) p = 0; print p }')
  if [ "$MODE" = presisi ]; then
    shown=$PART_NO
    sp=$(tail -n 30 "$PROG" 2>/dev/null | grep -a '^speed=' | tail -n 1)
    sp=${sp#speed=}; sp=${sp// /}
    if [[ $sp =~ ^[0-9.]+x$ ]]; then sp=" • $sp"; else sp=""; fi
  else
    n=$(find "$NEW_OUT" -maxdepth 1 -type f 2>/dev/null | wc -l)
    shown=$((n))
  fi
  ((shown > EST)) && shown=$EST
  ((shown < 1)) && shown=1
  render_bar "$pct" "$shown" "$EST" "$sp"
}

show_result() {
  local -a files
  local f n i d s lbl total
  mapfile -t files < <(find "$NEW_OUT" -maxdepth 1 -type f 2>/dev/null | sort -V)
  n=${#files[@]}
  total=$(find "$NEW_OUT" -maxdepth 1 -type f -printf '%s\n' 2>/dev/null | awk '{ t += $1 } END { printf "%d", t }')

  header_small
  box_top "SELESAI"
  box_row "${GRN}✔ Berhasil!${RST} ${BLD}${n}${RST} bagian tersimpan"
  box_row "${GRY}Dipotong tiap :${RST} ${INTERVAL} detik"
  box_row "${GRY}Mode          :${RST} ${MODE^^}"
  box_row "${GRY}Total ukuran  :${RST} $(hsize "$total")"
  box_row "${GRY}Waktu proses  :${RST} ${SECONDS} detik"
  box_sec "LOKASI"
  box_path "$NEW_OUT"
  box_sec "BAGIAN"
  for ((i = 0; i < n; i++)); do
    if ((n > 10 && i >= 7 && i < n - 2)); then
      ((i == 7)) && box_row "${GRY}... $((n - 9)) bagian lainnya ...${RST}"
      continue
    fi
    f="${files[i]}"
    d=$(ffprobe -v error -show_entries format=duration -of default=nw=1:nk=1 "$f" 2>/dev/null | head -n 1)
    if is_num "$d"; then d=$(awk -v d="$d" 'BEGIN{ printf "%.1f", d }'); else d="?"; fi
    s=$(stat -c %s "$f" 2>/dev/null || echo 0)
    lbl="${f##*_}"
    box_row "$(printf '%-11s %6s dtk %9s' "$(trunc "$lbl" 11)" "$d" "$(hsize "$s")")"
  done
  box_bot
}

scan_media() {                            
  command -v termux-media-scan >/dev/null 2>&1 || return 0
  ( timeout 10 termux-media-scan -r "$NEW_OUT" >/dev/null 2>&1 & ) 2>/dev/null
}

split_lossless() {                        
  local pattern="$1"
  PROG_OFF=0; PART_NO=1
  ffmpeg -nostdin -hide_banner -loglevel error -nostats -progress "$PROG" -y \
         -i "$SEL" -map 0:v:0 -map '0:a?' -c copy \
         -f segment -segment_time "$INTERVAL" -segment_time_delta 0.05 \
         -reset_timestamps 1 -segment_start_number 1 \
         "$pattern" 2>"$LOG" </dev/null &
  FF_PID=$!
  while kill -0 "$FF_PID" 2>/dev/null; do
    draw_progress
    sleep 0.25
  done
  wait "$FF_PID"
}

split_precise() {                         
  local k start fps out rc left
  local -a tflag aenc
  fps=$(precise_fps)
  case "$A_CODEC" in aac|mp3|'') aenc=(-c:a copy) ;; *) aenc=(-c:a aac -b:a 192k) ;; esac
  for ((k = 0; k < EST; k++)); do
    start=$((k * INTERVAL))
    printf -v out '%s/%s_part%0*d.%s' "$NEW_OUT" "$SAFE" "$PAD" $((k + 1)) "$EXT"
    tflag=()
    ((k < EST - 1)) && tflag=(-t "$INTERVAL")        # bagian terakhir: sampai akhir video
    PROG_OFF=$start; PART_NO=$((k + 1))
    : > "$PROG"
    # -noaccurate_seek + fps(start_time=0): layar yang tampil di detik awal tetap benar
    # meski rekaman layar (VFR) sedang diam; fps di dalam filter agar frame terisi sampai batas -t
    ffmpeg -nostdin -hide_banner -loglevel error -nostats -progress "$PROG" -y \
           -noaccurate_seek -ss "$start" -i "$SEL" "${tflag[@]}" \
           -map 0:v:0 -map '0:a?' -vf "fps=fps=${fps}:start_time=0" \
           -c:v libx264 -preset veryfast -crf 16 -pix_fmt yuv420p "${aenc[@]}" \
           "$out" 2>"$LOG" </dev/null &
    FF_PID=$!
    while kill -0 "$FF_PID" 2>/dev/null; do
      draw_progress
      sleep 0.25
    done
    wait "$FF_PID"; rc=$?
    if ((rc != 0)); then
      left=$(awk -v d="$DURATION" -v s="$start" 'BEGIN{ print (d - s < 1) ? 1 : 0 }')
      if ((k == EST - 1 && k > 0 && left == 1)); then   # sisa ekor < 1 detik tanpa gambar: abaikan
        rm -f -- "$out"
        EST=$k
        return 0
      fi
      return "$rc"
    fi
  done
  return 0
}

run_split() {
  local pad t rc l pattern n
  t=$((EST + 2)); pad=${#t}; ((pad < 2)) && pad=2
  PAD=$pad

  if ! make_outdir; then err "Gagal membuat folder hasil: $OUT_ROOT"; return 1; fi
  pattern="$NEW_OUT/${SAFE}_part%0${pad}d.${EXT}"

  header_small
  info "Memotong : ${BLD}$(trunc "$NAME" $((W - 16)))${RST}"
  if [ "$MODE" = presisi ]; then info "Mode     : PRESISI (re-encode)"; else info "Mode     : LOSSLESS (stream-copy)"; fi
  printf '\n'

  : > "$PROG"; : > "$LOG"
  RUNNING=1
  SECONDS=0
  printf '%s' "$HIDE"
  if [ "$MODE" = presisi ]; then
    if command -v termux-wake-lock >/dev/null 2>&1; then termux-wake-lock >/dev/null 2>&1; WAKE=1; fi
    split_precise; rc=$?
  else
    split_lossless "$pattern"; rc=$?
  fi
  RUNNING=0
  FF_PID=""
  if ((WAKE)); then termux-wake-unlock >/dev/null 2>&1; WAKE=0; fi
  printf '%s' "$SHOW"

  n=$(find "$NEW_OUT" -maxdepth 1 -type f 2>/dev/null | wc -l)
  if ((rc != 0 || n == 0)); then
    printf '\r\e[K\n'
    err "Gagal memotong video (kode $rc)."
    if [ -s "$LOG" ]; then
      tail -n 6 "$LOG" | while IFS= read -r l; do printf '   %s%s%s\n' "$GRY" "$(trunc "$l" $((W - 4)))" "$RST"; done
    fi
    discard_output
    return 1
  fi

  ((n > EST)) && EST=$n
  render_bar 100 "$n" "$n"; printf '\n'
  VERIFY_BAD=0
  if [ "$MODE" = presisi ] && ! verify_parts; then VERIFY_BAD=1; fi
  sleep 0.5
  scan_media
  show_result
  if ((VERIFY_BAD)); then
    printf '\n'; warn "Durasi sebagian bagian belum tepat."
    printf '   Coba ulangi atau pakai mode LOSSLESS.\n'
  fi
  return 0
}

main() {
  case "${1:-}" in -h|--help) usage; exit 0 ;; esac

  trap cleanup EXIT
  trap on_interrupt INT TERM

  welcome
  header_small
  info "Memeriksa sistem..."
  check_deps
  init_storage
  OUT_ROOT="$STORAGE/LAVYNRA/$OUT_DIRNAME"

  if [ -n "${1:-}" ]; then
    if [ -d "$1" ]; then ROOTS=("$(readlink -f "$1")"); else err "Folder tidak ditemukan: $1"; exit 1; fi
  else
    ROOTS=("$STORAGE")
    [ "$STORAGE" != "$HOME" ] && ROOTS+=("$HOME")
  fi

  WORK=$(mktemp -d 2>/dev/null) || { err "Gagal membuat folder sementara."; exit 1; }
  PROG="$WORK/progress.txt"; LOG="$WORK/ffmpeg.log"

  scan_videos
  while true; do
    pick_video || break
    analyze_video "$SEL" || { pause; continue; }
    ask_interval
    case $? in 1) break ;; 2) continue ;; esac
    ask_mode
    case $? in 1) break ;; 2) continue ;; esac
    confirm_plan || continue
    run_split || { pause; continue; }
    printf '\n'
    yn "Potong video lain?" Y || break
  done
  bye
}

main "$@"
