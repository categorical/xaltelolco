



usage() {
cat << EOF 1>&2

usage: $0 command
command:
    vminfo      vmname
    hduuid      vmname
    hdinfo      uuid|filename
    hdremake    uuid|filename   [variant]
        variant:    fixed|standard
    hdresize    uuid|filename   size
        size:       size in megabytes

to resize fixed hard disk:
    hdremake to dynamic
    hdresize to desired size
    hdremake to fixed
reload hard disk using virtual media manager after each command
    
EOF
}

vboxm=/usr/local/sbin/VBoxManage

vmname() {
    case $@ in
        'win7') echo Win7_Ult_SP1_English_x64;;
        'ubuntu') echo Ubuntu 14.04 LTS;;
        *)echo 'win7|ubuntu' && return 1;;
    esac
}


case $@ in
    'vminfo '*)
    vmname=`vmname $2` || exit 1
    cmd="$vboxm showvminfo '$vmname'"
    eval $cmd
    ;;
    'hduuid '*)
    vmname=`vmname $2` || exit 1
    hduuid=`$vboxm showvminfo "$vmname"|grep vdi|awk '{print $NF}'|sed 's/)//g'`
    echo $hduuid
    ;;
    'hdinfo '*)
    hduuid=$2
    cmd="$vboxm showhdinfo $hduuid"
    eval $cmd
    ;;
    'hdremake '*)
    hduuid=$2
    filename=`$vboxm showhdinfo $hduuid|grep Location|awk '{print $NF}'`
    hduuid=`$vboxm showhdinfo $hduuid|grep -v Parent|grep ^UUID|awk '{print $NF}'`
    variant=${3:-'Fixed'}
    cmd="$vboxm clonehd $hduuid $filename.tmp --variant $variant"
    eval $cmd \
    && mv $filename $filename.old \
    && mv $filename.tmp $filename
    ;;
    'hdresize '*)
    hduuid=$2
    size=$3
    cmd="$vboxm modifyhd $hduuid --resize $size"
    eval $cmd
    ;;
    *)
    usage
    ;;
esac







