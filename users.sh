#!/bin/bash

usage="$(cat <<EOF
SYNOPSIS
    $0 [-u | -g]
DESCRIPTION    
    -u Lists users.
    -g Lists groups.
EOF)"

arg="${1:--u}"
case $arg in
    -u)
        dscl /Local/Default list /Users
        ;;
    -g)
        dscl /Local/Default list /Groups        
        ;;
    *)
        echo "$usage"
        ;;
esac

