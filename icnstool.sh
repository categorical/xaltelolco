#!/bin/bash

set -euo pipefail

usage(){
    local -r c1="$(printf '%b' '\033[1m')"
    local -r c0="$(printf '%b' '\033[0m')"
    local -r c4="$(printf '%b' '\033[4m')"
    cat <<-EOF
	${c1}SYNOPSIS${c0}
	    $0 ${c1}--icns2iconset${c0} [ ${c1}-o${c0} ${c4}iconset_directory${c0} ] ${c4}icns_file${c0}
	    $0 ${c1}--icns2png${c0} [ ${c1}-o${c0} ${c4}png_file${c0} ] ${c4}icns_file${c0}
	    $0 ${c1}--iconset2icns${c0} [ ${c1}-o${c0} ${c4}icns_file${c0} ] ${c4}iconset_directory${c0}
	    $0 ${c1}--iconset2png${c0} [ ${c1}-o${c0} ${c4}png_file${c0} ] ${c4}iconset_directory${c0}
	    $0 ${c1}--png2icns${c0} [ ${c1}-o${c0} ${c4}icns_file${c0} ] ${c4}png_file${c0}
	    $0 ${c1}--png2iconset${c0} [ ${c1}-o${c0} ${c4}iconset_directory${c0} ] ${c4}png_file${c0}
	EOF
}

_parseargs(){
    declare -a args=("$@");len="${#args[@]}"
    for ((i=0;i<len;i++));do
        v=${args[i]}
        case $v in
            '--icns2iconset')mode=1;;
            '--icns2png')mode=2;;
            '--iconset2icns')mode=3;;
            '--iconset2png')mode=4;;
            '--png2icns')mode=5;;
            '--png2iconset')mode=6;;
            '-o')
                [ "$((++i))" -lt "$len" ]||return 1
                tofile="${args[i]}"
            ;;
            '-'*)return 1;;
            *)
                [ -z "${fromfile+foo}" ]||return 1
                fromfile="$v"
            ;;
        esac
    done
    _parseargsvalidate
}

_parseargsvalidate(){
    [ -n "${fromfile+foo}" ]||return 1
    [ -n "${mode+foo}" ]||return 1
}

_err(){
    local msg="$1"
    echo "$msg" >&2;exit 1
}

_checkexecutables(){
    [ -x "$SIPS" ]||_err 'The required executable `sips'"'"' is not found.'
    [ -x "$ICONUTIL" ]||_err 'The required executable `iconutil'"'"' is not found.'
}

_confirm(){
    [ -t 2 -a -t 0 ]||return 0
    
    printf '\033[32mconfirm\033[0m: %s (y/N):' "$*">&2
    local b;read -r 'b'
    [[ $b =~ ^y|Y|t|yes|Yes$ ]]||_err 'Bye.'
}

_checkfilenameextension(){
    local f="$1"
    local name;name="$(basename "$f")"
    local ext="$2";ext=".${ext#.}"
    [[ "$f" =~ ^.+"$ext"$ ]] \
        ||_err "File not recognised: \`$name'. The filename extension needs to be \`$ext'."
}

_gettofile(){
    local f0="$2"
    local name;name="$(basename "$f0")"
    local plus="$4";plus=".${plus#.}"
    local minus="$3";minus=".${minus#.}"
    local _f1="${name%$minus}$plus"
    if [ -n "${tofile+foo}" ];then
        [ -n "${tofile}" ]||_err 'No such file.'
        _checkfilenameextension "$tofile" "$plus"
        _f1="${tofile}"
    fi
    printf -v "$1" '%s' "$_f1"
}

_getfromfile(){
    local _f0="$fromfile"
    local ext="$2";ext=".${ext#.}"
    case $ext in
        '.iconset')[ -d "$_f0" ]||_err "Directory not found: \`$_f0'.";;
        '.png|.icns')[ -f "$_f0" ]||_err "File not found: \`$_f0'.";;
        *)[ -e "$_f0" ]||_err "File not found: \`$_f0'.";;
    esac
    _checkfilenameextension "$_f0" "$ext"
    
    printf -v "$1" '%s' "$_f0"
}

_icns2iconset(){ 
    local f0;_getfromfile 'f0' '.icns'
    local f1;_gettofile 'f1' "$f0" '.icns' '.iconset' 

    _confirm "Generate \`$f1' from \`$f0'?"
    (set -x;exec "$ICONUTIL" -c iconset "$f0" -o "$f1" 1>/dev/null)
}

_icns2png(){
    local f0;_getfromfile 'f0' '.icns'
    local f1;_gettofile 'f1' "$f0" '.icns' '.png' 

    _confirm "Generate \`$f1' from \`$f0'?"
    (set -x;exec "$SIPS" -s format png "$f0" --out "$f1" 1>/dev/null)
}

_iconset2icns(){
    local f0;_getfromfile 'f0' '.iconset'
    local f1;_gettofile 'f1' "$f0" '.iconset' '.icns'

    _confirm "Generate \`$f1' from \`$f0'?"
    (set -x;exec "$ICONUTIL" -c icns "$f0" -o "$f1" 1>/dev/null)
}

_iconset2png(){
    :
    local f0;_getfromfile 'f0' '.iconset'
    local f1;_gettofile 'f1' "$f0" '.iconset' '.png'

    _confirm "Generate \`$f1' from \`$f0'?"
    
    local f;f=$(find "$f0" \
        -mindepth 1 \
        -maxdepth 1 \
        -type 'f' \
        -name '*.png' \
        -exec stat -f '%N %z' {} \; \
        |sort -t' ' -k2 -n \
        |tail -n1\
        |cut -d' ' -f1)
    
    [ -n "$f" -a -f "$f" ]||_err "File not recognised: \`$f0'. Does it contain any PNG files?"
    (set -x;cp "$f" "$f1")
}

_pngresample(){
    local f=$1;f="$(cd "`dirname "$f"`" && pwd)/`basename "$f"`"
    local d=$2
    
    local sx;[ -z "${-//[^x]}" ]||sx='t'

    [ -d "$d" ]||{ set -x;mkdir -p "$d";{ set +x;} 2>/dev/null;}
    pushd "$d" 1>/dev/null||exit
        local ws=(16 32 128 256 512)
        local w
        for w in "${ws[@]}";do
            "$SIPS" -s format png \
                --resampleWidth "$w" \
                --out "icon_${w}x${w}.png" \
                "$f" 1>/dev/null
        done
        for w in "${ws[@]}";do
            if [ -f "icon_$((w*2))x$((w*2)).png" ];then
                cp "icon_$((w*2))x$((w*2)).png" "icon_${w}x${w}@2x.png"
                continue
            fi
            "$SIPS" -s format png \
                --resampleWidth "$((w*2))" \
                --out "icon_${w}x${w}@2x.png" \
                "$f" 1>/dev/null
        done

        local v;while IFS= read -d $'\0' -r v;do
            #_pngprobe "$v"
            stat -f '%-20N %z' "$v"
        done < <(find . -mindepth 1 -maxdepth 1 -type f -name '*.png' -print0);
    popd 1>/dev/null
   
    if [ "$sx" == 't' ];then set -x;else set +x;fi
}

_pngprobe(){
    local f=$1
    
    local l x k v;for l in \
        '_w pixelWidth' \
        '_h pixelHeight' \
        '_format format' \
        'spp samplesPerPixel' \
        'bps bitsPerSample';do
        x="${l%%[[:space:]]*}";k="${l#*[[:space:]]}"
        v="$("$SIPS" -g "$k" "$f"|tail -n1|rev|cut -d' ' -f1|rev)"
        eval "local $x;$x=\$v"
    done
    
    local t="$(cat <<-'EOF'
	Probed %s: 
	    \033[93m%-15s\033[0m: %d
	    \033[93m%-15s\033[0m: %d
	    \033[93m%-15s\033[0m: %d
	EOF
    )\n"
    printf "$t" "$f" 'width' "$_w" 'height' "$_h" 'colour depth' "$((bps*spp))"
    
    [ -z "${2+foo}" ]||printf -v "$2" '%d' "$_w"
    [ -z "${3+foo}" ]||printf -v "$3" '%d' "$_h"
    [ -z "${4+foo}" ]||printf -v "$4" '%s' "$_format"
}

_png2icns(){
    :
    local f0;_getfromfile 'f0' '.png'
    local f1;_gettofile 'f1' "$f0" '.png' '.icns'

    _pngprobe "$f0"
    _confirm "Generate \`$f1' from \`$f0'?"

    local t;t="$(mktemp -d)"||exit 1
    trap '{ (set -x;rm -R "$t");trap - RETURN;}' RETURN
    local d="$t/foo.iconset";mkdir "$d"
    _pngresample "$f0" "$d"
    (set -x;exec "$ICONUTIL" -c icns "$d" -o "$f1" 1>/dev/null)
}

_png2iconset(){
    :
    local f0;_getfromfile 'f0' '.png'
    local f1;_gettofile 'f1' "$f0" '.png' '.iconset'

    _pngprobe "$f0"
    _confirm "Generate \`$f1' from \`$f0'?"
    _pngresample "$f0" "$f1"

}

[ "${BASH_SOURCE[0]}" == "$0" ]||exit 1

declare -r SIPS=${SIPS:-'/usr/bin/sips'}
declare -r ICONUTIL=${ICONUTIL:='/usr/bin/iconutil'}

_checkexecutables
if ! _parseargs "$@";then usage;exit 1;fi

case $mode in
    1) _icns2iconset;;
    2) _icns2png;;
    3) _iconset2icns;;
    4) _iconset2png;;
    5) _png2icns;; 
    6) _png2iconset;;
    *);;
esac




