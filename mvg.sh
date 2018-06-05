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

repo=""
checkout=""

reset_vars()
{
    repo=""
    checkout=""
}

handle_sec_kvs()
{
    cur_sec="$1"

    for kv in $(sed -n '/\['$cur_sec'\]/,/^$/p' $CONF_PATH | grep -Ev '\[|\]|^$' | awk -F '=' '{printf "%s=\"%s\"\n", $1, $2}')
    do
        eval $kv
    done

    if [[ -z "$repo" ]]
    then
        echo "section [${cur_sec}] not defined!"
        return 1
    fi

    cur_path="${BASE_PATH}${cur_sec}"
    echo "[${cur_sec}] ${repo}, ${cur_path} , ${checkout}"

    rm -rf ${cur_path}

    echo "[${cur_sec}] clone"
    git clone ${repo} ${cur_path}
    echo "................"

    if [[ ! -z "$checkout" ]]
    then
        cd ${cur_path}
        echo "[${cur_sec}] checkout"
        git checkout ${checkout}
        echo "................"
        cd ${cwd}
    fi

    rm -rf ${cur_path}/.git

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
