#!/usr/bin/env bash


BASE_PATH="./vendor/" # Config the base path for all modules, and end it with '/'

CONF_PATH="./mvg.ini"

echo "======== start ========"

cwd=`pwd`
echo "pwd: $cwd"
echo "----------------"

list_ini_secs()
{
    if [ ! -f ${CONF_PATH} ]
    then
        echo "file [${CONF_PATH}] not found!"
        exit
    else
        sections=`sed -n '/\[*\]/p' ${CONF_PATH} | grep -v '^#' | tr -d []`
        for i in ${sections}
        do
          echo $i
        done
    fi
}

md5sum_of_str()
{
    target_str="$1"

    if type "md5" > /dev/null; then
        result=$(printf '%s' "${target_str}" | md5 | cut -d ' ' -f 1)
    elif type "md5sum" > /dev/null; then
        result=$(printf '%s' "${target_str}" | md5sum | cut -d ' ' -f 1)
    else
        result="$target_str"
    fi

    echo ${result:0:8}
}

reset_vars()
{
    repo=""
    checkout=""
    wrap=""
    file=""
    path=""
    subpath=""
}

handle_sec_kvs()
{
    cur_sec="$1"

    for kv in $(sed -n '/\['$cur_sec'\]/,/^$/p' $CONF_PATH | grep -Ev '\[|\]|^$' | awk -F '=' '{printf "%s=\"%s\"\n", $1, $2}')
    do
        eval $kv
    done

    # Get the local path, namely where to save
    if [[ ! -z "$path" ]]
    then
        cur_path="${path}"
    elif [[ ! -z "$subpath" ]]
    then
        cur_path="${BASE_PATH}${subpath}"
    else
        cur_path="${BASE_PATH}${cur_sec}"
    fi

    if [[ -z "$repo" ]]
    then
        if [[ -z "$file" ]]
        then
            echo "section [${cur_sec}]'s 'repo' or 'file' not defined!"
            return 1
        else
            curl $file --output $cur_path --create-dirs
        fi
        return
    fi

    echo "[${cur_sec}] ${repo}, ${cur_path}, ${checkout}"

    git_path=""
    rm -rf ${cur_path}

    echo "[${cur_sec}] clone"
    if [ "$wrap" = "py" ]
    then
        m_name="m_$(md5sum_of_str ${cur_sec})"
        git_path="${cur_path}/${m_name}"
        git clone ${repo} ${git_path}
        echo "from ${m_name} import *" > ${cur_path}/__init__.py
        echo "Please do not modify files here!\nGo to the source place!" > ${cur_path}/WARNING
    else
        git_path=$cur_path
        git clone ${repo} ${git_path}
    fi
    echo "................"

    if [[ ! -z "$checkout" ]]
    then
        cd ${git_path}
        echo "[${cur_sec}] checkout"
        git checkout ${checkout}
        echo "................"
        cd ${cwd}
    fi

    rm -rf ${git_path}/.git

    reset_vars
    echo "[${cur_sec}] done"
}

if [ $# -eq 0 ]
then # No argument
    for sec in `list_ini_secs`
    do
        echo "----------------"
        handle_sec_kvs ${sec}
    done
else # Specified in arguments
    for arg in "$@"
    do
        echo "----------------"
        handle_sec_kvs ${arg}
    done
fi

echo "======== done ========"
