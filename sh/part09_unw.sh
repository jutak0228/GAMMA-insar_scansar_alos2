#!/bin/bash -e

#*************************************************************************************************************
#
# @script run_unw.sh
# @brief アンラップ処理を行う
# @param[in] INPUTDIR 差分干渉SAR結果が格納されたディレクトリの親ディレクトリ
# @param[in] WAVELENGTH 大域誤差除去フィルタのカットオフ長さ(単位:m) 0を指定すると大域誤差除去フィルタをかけない
# @param[in] ADF_NFFT 位相強調フィルタのFFTウィンドウサイズ
# @param[in] INIT アンラップ開始点（不動点）のレンジ、アジマス座標
# @param[in] CCTHRES 0H コヒーレンスマスクの閾値
# @param[in] MODE 処理ファイルリストを使用するかどうかの指定(ALL：ファイルリストを使用しない ADD：リストにないファイルを処理する)
# @param[in] UNW_METHOD MCF法とBC法によるアンラップ処理の指定(MCF:MCF法 BC:BC法)
# @return
# @note
# MCF法とBC法によるアンラップ処理を実装している。サービスにはMCF法を使用する想定で、BC法は使用しない。
#
#*************************************************************************************************************

######################################################################################################
# arguments
######################################################################################################

workdir="$1"
WAVELENGTH="$2"
ADF_NFFT="$3"
range_ref="$4"
azimuth_ref="$5"
cc_thres="$6"
unw_method="$7"

########################################################################
#
# @fn unw_mcf 
# @brief MCF法によるアンラップ処理
# @param[in] dir 差分SARファイルが格納されているディレクトリ
# @return なし
# @note
# コヒーレンスマスク適用
# アンラップ開始点（不動点）の位相は初期値のまま（0にしない設定）
#
########################################################################
function unw_mcf()
{
    dir="$1"
    echo ${dir}
    cd ${workdir}/infero/${dir}
    file=`ls *.int`
    file="${file%.int}"

    width=`cat ${file}.off | grep "interferogram_width" | awk -F":" '{print $2}' | sed -e "s/[^0-9]//g"`

    rascc_mask ${file}_sm${ADF_NFFT}.cc - ${width} - - - - - ${cc_thres} - - - - - - ${file}_sm${ADF_NFFT}.ras
    mcf ${file}.diff.sm${ADF_NFFT}.hp${WAVELENGTH} ${file}_sm${ADF_NFFT}.cc ${file}_sm${ADF_NFFT}.ras ${file}.diff.sm${ADF_NFFT}.hp${WAVELENGTH}_mcf.unw ${width} 0 0 0 - - 1 1 - ${range_ref} ${azimuth_ref} 1

    # check bias of unwrap

    if [ -L ${file}.diff.sm${ADF_NFFT}.hp${WAVELENGTH}.unw ];then
        unlink ${file}.diff.sm${ADF_NFFT}.hp${WAVELENGTH}.unw >/dev/null 2>&1
    fi
    ln -s ${file}.diff.sm${ADF_NFFT}.hp${WAVELENGTH}_mcf.unw ${file}.diff.sm${ADF_NFFT}.hp${WAVELENGTH}.unw >/dev/null 2>&1
}

########################################################################
#
# @fn unw_bc
# @brief Branch Cut法によるアンラップ処理
# @param[in] dir 差分干渉SARファイルが格納されているディレクトリ
# @return なし
# @note
# サービスでは基本的にBC法によるアンラップは使用しない
#
########################################################################
function unw_bc()
{
    dir="$1"
    cd ${workdir}/infero/${dir}
    file=`ls *.int`
    file="${file%.int}"

    width=`cat ${file}.off | grep "interferogram_width" | awk -F":" '{print $2}' | sed -e "s/[^0-9]//g"`

    corr_flag ${file}_sm${ADF_NFFT}.cc ${file}_sm${ADF_NFFT}.flag ${width} ${cc_thres}
    neutron *.rmli ${file}_sm${ADF_NFFT}.flag ${width}
    residue_cc ${file}.diff.sm${ADF_NFFT}.hp${WAVELENGTH} ${file}_sm${ADF_NFFT}.flag ${width}
    tree_cc ${file}_sm${ADF_NFFT}.flag ${width} 64
    grasses ${file}.diff.sm${ADF_NFFT}.hp${WAVELENGTH} ${file}_sm${ADF_NFFT}.flag ${file}.diff.sm${ADF_NFFT}.hp${WAVELENGTH}_bc.unw ${width} - - - - ${INIT} 0
    rastree ${file}_sm${ADF_NFFT}.flag ${file}.diff.sm${ADF_NFFT}.hp${WAVELENGTH}_bc.unw ${file}.diff.sm${ADF_NFFT}.hp${WAVELENGTH} ${width} - - - ${file}.diff.sm${ADF_NFFT}.hp${WAVELENGTH}_bc.unw.tree.ras

    if [ -L ${file}.diff.sm${ADF_NFFT}.hp${WAVELENGTH}.unw ];then
       unlink ${file}.diff.sm${ADF_NFFT}.hp${WAVELENGTH}.unw >/dev/null 2>&1
    fi
    ln -s ${file}.diff.sm${ADF_NFFT}.hp${WAVELENGTH}_bc.unw ${file}.diff.sm${ADF_NFFT}.hp${WAVELENGTH}.unw >/dev/null 2>&1

 }

export -f unw_mcf
export -f unw_bc

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
    case ${unw_method} in
    MCF)
        for dir in ${list[@]};do unw_mcf $dir ;done
        ;;
    BC)
        for dir in ${list[@]};do unw_bc $dir ;done
        ;;
    esac
else
    echo "NO PROCESS DIR"
fi
