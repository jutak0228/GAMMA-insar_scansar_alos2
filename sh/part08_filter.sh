#!/bin/bash -e

#*************************************************************************************************************
#
# @script run_filter.sh
# @brief フィルタ処理（位相強調フィルタ、大域誤差除去フィルタ）を行う
# @param[in] INPUTDIR 差分干渉SAR結果が格納されたディレクトリの親ディレクトリ
# @param[in] WAVELENGTH 大域誤差除去フィルタのカットオフ長さ（単位:m）0を指定すると大域誤差除去フィルタをかけない
# @param[in] ADF_NFFT 位相強調フィルタのFFTウィンドウサイズ(2**N, 8 --> 512)
# @param[in] MODE 処理ファイルリストを使用するかどうかの指定(ALL：使用しない ADD：リストにないファイルを処理する)
# @return
# @note
#
#*************************************************************************************************************
######################################################################################################
# arguments
######################################################################################################

workdir="$1"
WAVELENGTH="$2"
ADF_NFFT="$3"
python="$4"

########################################################################
#
# @fn filter
# @brief フィルタ処理
# @param[in] dir 差分干渉SARファイルが格納されているディレクトリ
# @return なし
# @note
# 位相強調フィルタ->大域誤差除去フィルタの順に処理を行う
#
########################################################################
function filter()
{
    dir="$1"
    cd ${workdir}/infero/${dir}
    file=`ls *.int`
    file="${file%.int}"
    
    rspc=`cat ${file}.off   | grep "interferogram_range_pixel_spacing"   | awk '{print $2}'       | sed -e "s/[^0-9,\.]//g"`
    aspc=`cat ${file}.off   | grep "interferogram_azimuth_pixel_spacing" | awk '{print $2}'       | sed -e "s/[^0-9,\.]//g"`
    width=`cat ${file}.off  | grep "interferogram_width"                 | awk -F":" '{print $2}' | sed -e "s/[^0-9]//g"`
    height=`cat ${file}.off | grep "interferogram_azimuth_lines"         | awk -F":" '{print $2}' | sed -e "s/[^0-9]//g"`

    if [ "${ADF_NFFT}" -ne 0 ];then
        adf ${file}.diff  ${file}.diff.sm${ADF_NFFT} ${file}_sm${ADF_NFFT}.cc ${width} 1.0 ${ADF_NFFT}
    else
        if [ -L "${file}.diff.sm${ADF_NFFT}" ];then unlink ${file}.diff.sm${ADF_NFFT} >/dev/null 2>&1; fi
        ln -s ${file}.diff ${file}.diff.sm${ADF_NFFT}
        cc_wave ${file}.diff.sm${ADF_NFFT} - - ${file}_sm${ADF_NFFT}.cc ${width} 5 5 0
    fi

    if [ "${WAVELENGTH}" -ne 0 ];then
        python ${python}/hp_flt_mod.py ${file}.diff.sm${ADF_NFFT} ${width} ${height} ${rspc} ${aspc} ${WAVELENGTH} ${file}.diff.sm${ADF_NFFT}.hp${WAVELENGTH}
    else
        if [ -L "${file}.diff.sm${ADF_NFFT}.hp${WAVELENGTH}" ];then unlink ${file}.diff.sm${ADF_NFFT}.hp${WAVELENGTH} >/dev/null 2>&1; fi
        ln -s ${file}.diff.sm${ADF_NFFT} ${file}.diff.sm${ADF_NFFT}.hp${WAVELENGTH}
    fi

}

export -f filter

#######################################################################################################
# main
#######################################################################################################

cd ${workdir}/infero

list=()
counter=0
for dir in `ls -F | grep "/"`
do
    list[${counter}]="${dir%/}"
    counter=`expr ${counter} + 1`
done

if [ "${#list[@]}" -ne 0 ];then
    for dir in ${list[@]};do filter $dir ;done
else
    echo "NO PROCESS DIR"
fi