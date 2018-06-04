#!/usr/bin/env bash


BASE_PATH="./vendor/" # Config the base path for all modules, and end it with '/'


echo "======== start ========"

inifile="./mvg.ini"
section="$1"

cwd=`pwd`
echo "pwd: $cwd"
echo "----------------"

list_ini_secs()
{
    if [ ! -f ${inifile} ]
    then
        echo "file [${inifile}] not exist!"
        exit
    else
        sections=`sed -n '/\[*\]/p' ${inifile} | grep -v '^#' | tr -d []`
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

    for kv in $(sed -n '/\['$cur_sec'\]/,/^$/p' $inifile | grep -Ev '\[|\]|^$' | awk -F '=' '{printf "%s=\"%s\"\n", $1, $2}')
    do
        eval $kv
    done

    cur_path="${BASE_PATH}${cur_sec}"
    echo "${repo}, ${cur_path} , ${checkout}"

    rm -rf ${cur_path}

    echo "${cur_sec}: clone"
    git clone ${repo} ${cur_path}
    echo "................"

    if [[ ! -z "$checkout" ]]
    then
        cd ${cur_path}
        echo "${cur_sec}: checkout"
        git checkout ${checkout}
        echo "................"
        cd ${cwd}
    fi

    rm -rf ${cur_path}/.git

    reset_vars
    echo "${cur_sec}: done"
    echo "----------------"
}

for sec in `list_ini_secs`
do
    if [[ -z "$section" ]]
    then
        handle_sec_kvs ${sec}
    else
        if [[ "$sec" = "$section" ]]
        then
            handle_sec_kvs ${sec}
        fi
    fi
done

echo "======== done ========"
