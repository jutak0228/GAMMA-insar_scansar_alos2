#!/bin/bash -e

#*************************************************************************************************************
#
# @script run_ortho.sh
# @brief ファイル（差分干渉SAR結果、アンラップ結果、コヒーレンス画像、強度画像）のオルソ処理を行う
# 
# @param[in] REGISTMASTER マスターファイル名（拡張子なし)
# @param[in] WAVELENGTH 大域誤差除去フィルタのカットオフ長さ（単位:m）0はフィルタ適用なし 
# @param[in] ADF_NFFT 位相強調フィルタのFFTウィンドウサイズ(2**N, 8 --> 512)
# @param[in] MODE 処理ファイルリストを使用するかどうかの指定(ALL：使用しない ADD：リストにないファイルを処理する)
# @param[in] LIST_ARR_TARGET オルソ処理をするファイル種の指定(スペース区切りで複数指定可能)
#                  (DIFF:干渉縞画像 UNW:アンラップ結果画像 CC:コヒーレンス画像 PWR:強度画像)
#
#*************************************************************************************************************

#####################################################################################################
# arguments
######################################################################################################

workdir="$1"
python="$2"
ref_date="$3"
dem_name="$4"
WAVELENGTH="$5"
ADF_NFFT="$6"
CALFACTOR="$7"

########################################################################
#
# @fn ortho_gamma
# @brief 傾斜補正後方散乱係数画像をオルソ化する
# @param[in] file 強度画像(RMLIファイル)ファイルパス
# @return なし
# @note
# gammaのsigma2gammaを使用；いまいちなので将来的には変更
#
########################################################################
function ortho_gamma()
{
    file="$1"
    lut="${workdir}/DEM/${ref_date}.lt_fine"

    width=`cat ${file}.par | grep "range_samples" | awk -F":" '{print $2}' | sed -e "s/[^0-9]//g"`
    height=`cat ${file}.par | grep "azimuth_lines" | awk -F":" '{print $2}' | sed -e "s/[^0-9]//g"`

    dempar="${workdir}/DEM/EQA.dem_par"
    orthoWidth=`cat ${dempar} | grep "width" | awk -F":" '{print $2}' | sed -e "s/[^0-9]//g"`

    inc="${workdir}/DEM/${ref_date}.inc"

    if [ ! -e ${file%.rmli}_db_gamma.tif ];then
        sigma2gamma ${file} ${inc} ${file%.*}_gamma ${width}
        python ${python}/makeBSImage.py ${file%.*}_gamma ${width} ${height} ${CALFACTOR} ${file%.rmli}_db_gamma
        geocode_back ${file%.rmli}_db_gamma ${width} ${lut} ${file%.*}_db_gamma_ortho ${orthoWidth} - - 0
        data2geotiff ${dempar} ${file%.*}_db_gamma_ortho 2 ${file%.*}_tmp0.tif
        gdal_translate -a_nodata 0 ${file%.*}_tmp0.tif ${pwr_results}/${file%.*}_db_gamma.tif
        rm -rf ${file%.rmli}_db_gamma ${file%.*}_db_gamma_ortho ${file%.*}_tmp0.tif
    else
        echo "ALREADY PROCESSED : ${file%.*}.tif"
    fi
}

########################################################################
#
# @fn ortho_pwr
# @brief 強度画像をオルソ化する
# @param[in] file 強度画像(RMLIファイル)ファイルパス
# @return なし
# @note
# dB画像を作成->オルソ化
#
########################################################################
function ortho_pwr()
{
    file="$1"
    lut="${workdir}/DEM/${ref_date}.lt_fine"

    width=`cat ${file}.par | grep "range_samples" | awk -F":" '{print $2}' | sed -e "s/[^0-9]//g"`
    height=`cat ${file}.par | grep "azimuth_lines" | awk -F":" '{print $2}' | sed -e "s/[^0-9]//g"`

    dempar="${workdir}/DEM/EQA.dem_par"
    orthoWidth=`cat ${dempar} | grep "width" | awk -F":" '{print $2}' | sed -e "s/[^0-9]//g"`
    
    if [ ! -e ${file%.rmli}_db.tif ];then
        python ${python}/makeBSImage.py ${file} ${width} ${height} ${CALFACTOR} ${file%.rmli}_db
        geocode_back ${file%.rmli}_db ${width} ${lut} ${file%.*}_db_ortho ${orthoWidth} - - 0
        data2geotiff ${dempar} ${file%.*}_db_ortho 2 ${file%.*}_tmp.tif
        gdal_translate -a_nodata 0 ${file%.*}_tmp.tif ${pwr_results}/${file%.*}_db.tif
        rm -rf ${file%.rmli}_db ${file%.*}_db_ortho ${file%.*}_tmp.tif
    else
        echo "ALREADY PROCESSED : ${file%.*}.tif"
    fi
}

########################################################################
#
# @fn ortho_diff
# @brief 差分干渉SAR画像をオルソ化する
# @param[in] dir 差分干渉SARファイルが格納されているディレクトリ
# @return なし
# @note  
#
########################################################################
function ortho_diff()
{
    dir="$1"
    cd ${workdir}/infero/${dir}
    file=`ls *.int`
    file="${file%.int}"

    width=`cat ${file}.off | grep "interferogram_width" | awk -F":" '{print $2}' | sed -e "s/[^0-9]//g"`
    lut="${workdir}/DEM/${ref_date}.lt_fine"
     
    dem="${workdir}/DEM/${ref_date}.hgt"
    dempar="${workdir}/DEM/EQA.dem_par"
    orthoWidth=`cat ${dempar} | grep "width" | awk -F":" '{print $2}' | sed -e "s/[^0-9]//g"`    
   
    ext="diff.sm${ADF_NFFT}.hp${WAVELENGTH}"

    if [ ! -e ${file}_sm${ADF_NFFT}_hp${WAVELENGTH}.tif ];then
        cpx_to_real ${file}.${ext} ${file}_sm${ADF_NFFT}_hp${WAVELENGTH}.phase ${width} 4
        python ${python}/convert_16step.py ${file}_sm${ADF_NFFT}_hp${WAVELENGTH}.phase ${file}_sm${ADF_NFFT}_hp${WAVELENGTH}.stp
        geocode_back ${file}_sm${ADF_NFFT}_hp${WAVELENGTH}.stp ${width} ${lut} ${file}_sm${ADF_NFFT}_hp${WAVELENGTH}.ortho ${orthoWidth} - 0 3
        data2geotiff ${dempar} ${file}_sm${ADF_NFFT}_hp${WAVELENGTH}.ortho 5 ${diff_results}/${file}_sm${ADF_NFFT}_hp${WAVELENGTH}.tif 0
        rm -rf ${file}_sm${ADF_NFFT}_hp${WAVELENGTH}.stp
        rm -rf ${file}_sm${ADF_NFFT}_hp${WAVELENGTH}.phase
        rm -rf ${file}_sm${ADF_NFFT}_hp${WAVELENGTH}.ortho
    else
        echo "ALREADY PROCESSED : ${file}_sm${ADF_NFFT}_hp${WAVELENGTH}.tif"
    fi

}

########################################################################
#
# @fn ortho_cc
# @brief コヒーレンス画像のオルソ化
# @param[in] dir 差分干渉SARファイルが格納されているディレクトリ
# @return なし
# @note
#
########################################################################
function ortho_cc()
{
    dir="$1"
    cd ${workdir}/infero/${dir}
    file=`ls *.int`
    file="${file%.int}"

    lut="${workdir}/DEM/${ref_date}.lt_fine"

    width=`cat ${file}.off | grep "interferogram_width" | awk -F":" '{print $2}' | sed -e "s/[^0-9]//g"`

    dempar="${workdir}/DEM/EQA.dem_par"
    orthoWidth=`cat ${dempar} | grep "width" | awk -F":" '{print $2}' | sed -e "s/[^0-9]//g"`

    if [ ! -e ${file%.*}_cc.tif ];then
        geocode_back ${file%.*}_sm${ADF_NFFT}.cc ${width} ${lut} ${file%.*}_sm${ADF_NFFT}_ortho ${orthoWidth} - 0 0
        data2geotiff ${dempar} ${file%.*}_sm${ADF_NFFT}_ortho 2 ${cc_results}/${file%.*}_sm${ADF_NFFT}_cc.tif
        rm -rf ${file%.*}_sm${ADF_NFFT}_ortho
    else
        echo "ALREADY PROCESSED : ${file}_cc.tif" 
    fi
}

########################################################################
#
# @fn ortho_unw
# @brief アンラップ画像を変動量に変換し、オルソ化する
# @param[in] dir 差分干渉SARファイルが格納されているディレクトリ
# @return なし
# @note
#
########################################################################
function ortho_unw()
{
    dir="$1"
    cd ${workdir}/infero/${dir}
    file=`ls *.int`
    file="${file%.int}"
    masterSlcPar="${workdir}/rslc/${ref_date}.rslc.par"

    width=`cat ${file}.off | grep "interferogram_width" | awk -F":" '{print $2}' | sed -e "s/[^0-9]//g"`

    lut="${workdir}/DEM/${ref_date}.lt_fine"

    dem="${workdir}/DEM/${ref_date}.hgt"
    dempar="${workdir}/DEM/EQA.dem_par"
    orthoWidth=`cat ${dempar} | grep "width" | awk -F":" '{print $2}' | sed -e "s/[^0-9]//g"`

    ext="diff.sm${ADF_NFFT}.hp${WAVELENGTH}"

    if [ ! -e ${file}_sm${ADF_NFFT}_hp${WAVELENGTH}_disp.tif ];then
        dispmap ${file}.${ext}.unw ${dem} ${masterSlcPar} ${file}.off ${file}.disp
        geocode_back ${file}.disp ${width} ${lut} ${file}.disp.ortho ${orthoWidth} - 0 0
        data2geotiff ${dempar} ${file}.disp.ortho 2 ${unw_results}/${file}_sm${ADF_NFFT}_hp${WAVELENGTH}_disp.tif
        rm -rf ${file}.disp
        rm -rf ${file}.disp.ortho
    else
        echo "ALREADY PROCESSED : ${file}_sm${ADF_NFFT}_hp${WAVELENGTH}_disp.tif"        
    fi
}

# 関数を環境変数に設定（並列処理（paralellコマンド）用）
export -f ortho_unw
export -f ortho_cc
export -f ortho_diff
export -f ortho_pwr
export -f ortho_gamma

#######################################################################################################
# main
#######################################################################################################

# create result directory
cd ${workdir}
if [ -e results ];then rm -r results; fi
mkdir -p results
mkdir -p results/pwr
pwr_results="${workdir}/results/pwr"
mkdir -p results/cc
cc_results="${workdir}/results/cc"
mkdir -p results/diff
diff_results="${workdir}/results/diff"
mkdir -p results/unw
unw_results="${workdir}/results/unw"

# 干渉縞画像、コヒーレンス画像、アンラップ結果のオルソ化
cd ${workdir}/infero

list=()
counter=0
for dir in `ls -F | grep "/"`
do
    list[${counter}]="${dir%/}"
    counter=`expr ${counter} + 1`
done

if [ "${#list[@]}" -ne 0 ];then
    for dir in ${list[@]};do ortho_diff $dir ;done
    for dir in ${list[@]};do ortho_cc $dir ;done
    for dir in ${list[@]};do ortho_unw $dir ;done
else
    echo "NO PROCESS DIR"
fi

# 強度画像のオルソ化処理
cd ${workdir}/rmli
for rmli in `ls *.rmli`;do ortho_pwr $rmli ;done
for rmli in `ls *.rmli`;do ortho_gamma $rmli ;done
