#!/bin/bash -e

# arguments

workdir="$1"
rglks="$2"
azlks="$3"

# @fn interf: 初期干渉SAR処理

function interf()
{

    master="$1"
    slave="$2"
    rglks="$3"
    alks="$4"

    masdate=`echo ${master} | sed -e "s/[^0-9]//g"`
    slvdate=`echo ${slave}  | sed -e "s/[^0-9]//g"`

    output="${workdir}/infero/${masdate}to${slvdate}" 

    mkdir -p ${output}
    create_offset ${master}.rslc.par ${slave}.rslc.par ${output}/${master}to${slave}.off < ${workdir}/gamma_mod/prm.txt
    SLC_intf ${master}.rslc ${slave}.rslc ${master}.rslc.par ${slave}.rslc.par ${output}/${master}to${slave}.off ${output}/${master}to${slave}.int ${rglks} ${alks}
    # if [ -L "${output}/${master}.rmli" ];then unlink ${output}/${master}.rmli >/dev/null 2>&1; fi
    # ln -s ${workdir}/rmli/${master}.rmli ${output}/${master}.rmli >/dev/null 2>&1
}

# main

export -f interf

# 初期干渉SAR処理

cd ${workdir}
if [ -e rslc ];then rm -r rslc; fi
mkdir -p rslc
if [ -e rmli ];then rm -r rmli; fi
mkdir -p rmli
if [ -e infero ];then rm -r infero; fi
mkdir -p infero

cd ${workdir}/input_files

while read date
do
    cp ${date}.rslc ${workdir}/rslc/
    cp ${date}.rslc.par ${workdir}/rslc/
    cp ${date}.rmli ${workdir}/rmli/
    cp ${date}.rmli.par ${workdir}/rmli/
done < dates

cd ${workdir}/rslc

cp ../dates .

# make array list
LIST_ARR_MASTER=()
LIST_ARR_SLAVE=()
counter=0

rslcNum=`ls -1 *.rslc 2>/dev/null | wc -l`

for rslc_file in `ls -F *.rslc.par`
do
    LIST_ARR_MASTER[${counter}]="${rslc_file%.rslc.par}"
    counter=`expr ${counter} + 1`
done
LIST_ARR_SLAVE=(${LIST_ARR_MASTER[@]})

# interferometry
for master in ${LIST_ARR_MASTER[@]}
do
    for slave in ${LIST_ARR_SLAVE[@]}
    do
        masdate=`echo ${master} | sed -e "s/[^0-9]//g"`
        slvdate=`echo ${slave} | sed -e "s/[^0-9]//g"`
        if [ ${masdate} -lt ${slvdate} ];then
            echo "master date = ${masdate}"
            echo "slave date = ${slvdate}"
            interf ${master} ${slave} ${rglks} ${azlks}
        fi
    done
done

