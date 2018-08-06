#!/usr/bin/env bash


BASE_PATH="./" # Config the base path for all modules, and end it with '/'

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
    repo=""         # Git repo
    checkout=""     # Git checkpoint
    wrap=""         # If some wrapping is needed
    file=""         # CURL file url
    path=""         # Target path relative to `cwd`, ended with '/'
    subpath=""      # Target path relative to `BASE_PATH`, ended with '/'
    cmd=""          # Command to sync the module file, to be executed given the absence of `repo` and `file`
    cmd_before=""   # Command before the sync
    cmd_after=""    # Command after the sync
}

handle_sec_kvs()
{
    cur_sec="$1"

    IFS=$'\n'
    for kv in $(sed -n '/\['$cur_sec'\]/,/^$/p' $CONF_PATH | grep -Ev '\[|\]|^$' | awk -F"=" '{printf "%s=\"%s\"\n", $1, $2}')
    do
        echo $kv
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
        cur_path="${BASE_PATH}"
    fi
    cur_path="${cur_path}${cur_sec}"

    echo "[${cur_sec}] in ${cur_path}"
    rm -rf ${cur_path}
    mkdir -p ${cur_path}
    cd ${cur_path}

    # Execute a command before the sync
    if [[ ! -z "$cmd_before" ]]
    then
        echo "[${cur_sec}] before sync: ${cmd_before}"
        eval "$cmd_before"
    fi

    cd ${cwd}
    cd ${cur_path}

    # Execute the sync command
    if [[ ! -z "$cmd" ]]
    then
        echo "[${cur_sec}] sync cmd: ${cmd}"
        eval "$cmd"

    # CURL
    elif [[ ! -z "$file" ]]
    then
        echo "[${cur_sec}] curl"
        curl -O -J $file

    # Git
    elif [[ ! -z "$repo" ]]
    then
        cd ${cwd}
        git_path="${cur_path}"

        # Git clone
        echo "[${cur_sec}] git clone"
        if [ "$wrap" = "py" ]
        then
            m_name="m_$(md5sum_of_str ${cur_sec})"
            git clone ${repo} ${git_path}/${m_name}
            echo "from ${m_name} import *" > ${git_path}/__init__.py
            git_path="${git_path}/${m_name}"
        else
            git clone ${repo} ${git_path}
        fi
        echo "................"

        # Git checkout
        if [[ ! -z "$checkout" ]]
        then
            cd ${git_path}
            echo "[${cur_sec}] git checkout"
            git checkout ${checkout}
            echo "................"
            cd ${cwd}
        fi

        rm -rf ${git_path}/.git

    else
        echo "section [${cur_sec}]'s sync method not defined!"
    fi

    cd ${cur_path}
    echo "Please do not modify files here!\nGo to the right repository for source codes!" > WARNING

    # Execute a command after the sync
    if [[ ! -z "$cmd_after" ]]
    then
        echo "[${cur_sec}] after sync: ${cmd_after}"
        eval "$cmd_after"
    fi

    echo "[${cur_sec}] done"
    reset_vars
    cd ${cwd}
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
