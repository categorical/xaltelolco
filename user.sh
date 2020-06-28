#!/bin/bash

# Creates a user (and a group) if:
# a) the user name is prefixed with an underscore AND
# b) the user name has not been taken AND
# c) the group name (same as the user name) has not been taken AND
# d) there exists an available user ID in [300,380) AND
# e) there exists an available group ID in [300,380) AND
#
# Deletes a user if:
# a) the user ID belongs to [300,380)
# Deletes a group if:
# b) the group ID belongs to [300,380)
  


usage="$0 add|del|cat _name"
if [[ $# < 2 || $2 != _* ]]; then
    echo $usage
    exit 1
fi

ds=/Local/Default

us=($(dscl $ds -readall /Users UniqueID\
|grep UniqueID\
|awk '{print $2}'))

gs=($(dscl $ds -readall /Groups PrimaryGroupID\
|grep PrimaryGroupID\
|awk '{print $2}'))

ubound=380
lbound=300

echo_info(){
    echo -e "[\033[94minfo\033[0m] $@"
}
echo_error(){
    echo -e "[\033[91mfail\033[0m] $@"
}
echo_ok(){
    echo -e "[\033[32mok\033[0m] $@"
}


if [[ $1 == "add" ]];then


if ! [[ -z $(dscl $ds -list /Groups|grep $2) ]];then
    echo_error "Existing group $2"
    exit
fi
if ! [[ -z $(dscl $ds -list /Users|grep $2) ]];then
    echo_error "Existing user $2"
    exit
fi


for((uid=$lbound;uid<$ubound;uid++))
do
    if ! [[ " ${us[@]} "  =~ " $uid " ]]; then
        break
    fi
done

for((gid=$lbound;gid<$ubound;gid++))
do
    if ! [[ " ${gs[@]} "  =~ " $gid " ]]; then
        break
    fi
done

if [[ $uid -eq $ubound || $gid -eq $ubound ]]; then
    echo "No available ID"
    exit; fi

fi

create_group(){
    dscl $ds -create /Groups/$2
    dscl $ds -create /Groups/$2 PrimaryGroupID $1
    dscl $ds -create /Groups/$2 Password \*
    echo_ok "Create group" $2 "(g:" $1 ")"
}
create_user(){
    dscl $ds -create /Users/$3
    dscl $ds -delete /Users/$3 accountPolicyData
    dscl $ds -delete /Users/$3 AuthenticationAuthority
    dscl $ds -delete /Users/$3 ShadowHashData
    dscl $ds -delete /Users/$3 KerberosKeys
    dscl $ds -delete /Users/$3 HeimdalSRPKey
    dscl $ds -create /Users/$3 UniqueID $2
    dscl $ds -create /Users/$3 UserShell /usr/bin/false
    dscl $ds -create /Users/$3 NFSHomeDirectory /var/empty
    dscl $ds -create /Users/$3 PrimaryGroupID $1
    dscl $ds -create /Users/$3 Password \*
    echo_ok "Create user" $3 "(u:" $2 "g:" $1 ")"
}

delete_group(){
    local gid=$(dscl $ds -read /Groups/$1 PrimaryGroupID\
    |awk '{print $2}')
    [[ $gid -lt $lbound || $gid -ge $ubound ]] && echo_error \
    "Deletion not allowed (g:$gid)" && exit
    
    dscl $ds -delete /Groups/$1 \
    && echo_ok "Delete group" $1
}
delete_user(){
    local uid=$(dscl $ds -read /Users/$1 UniqueID\
    |awk '{print $2}')
    [[ $uid -lt $lbound || $uid -ge $ubound ]] && echo_error \
    "Deletion not allowed (u:$uid)" && exit
    
    dscl $ds -delete /Users/$1 \
    && echo_ok "Delete user" $1
}

cat_user(){
    echo_info "u:" $1
    dscl $ds -read /Users/$1
}
cat_group(){
    echo_info "g:" $1
    dscl $ds -read /Groups/$1
}

case $1 in
    add)
    create_group $gid $2
    create_user $gid $uid $2
    ;;
    del)
    delete_group $2
    delete_user $2
    ;;
    cat)
    cat_user $2
    cat_group $2
    ;;
    *) echo $usage;;
esac

