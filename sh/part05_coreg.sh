#!/bin/bash -e

# Step 5: Co-registration of the second scene to the reference
# (this is done for the ScanSAR format data using the script ScanSAR_coreg.py)

workdir="$1"
ref_date="$2"
polar="$3"
rglks="$4"
azlks="$5"

cd ${workdir}/input_files

cp ../DEM/${ref_date}.hgt .

# set parameters
range_samples=`cat ${ref_date}.mli.par | grep "range_samples" | awk -F":" '{print $2}' | tr -d [:space:] | sed -e "s/[^0-9]//g"`
azimuth_lines=`cat ${ref_date}.mli.par | grep "azimuth_lines" | awk -F":" '{print $2}' | tr -d [:space:] | sed -e "s/[^0-9]//g"`

while read date
do
    if [ ${date} = ${ref_date} ];then
        echo "master date is ${date}"
    elif [ ${date} != ${ref_date} ];then
        ScanSAR_coreg.py ${ref_date}_${polar}.SLC_tab ${ref_date} ${date}_${polar}.SLC_tab ${date} ${date}_${polar}.RSLC_tab ${ref_date}.hgt $rglks $azlks --it1 2 --it2 0 --npoly 3 --no_check
        # Generate co-registered rmli file
        multi_look ${date}.rslc ${date}.rslc.par ${date}.rmli ${date}.rmli.par $rglks $azlks - - 0.000001
        ras_dB ${date}.rmli $range_samples 1 $azimuth_lines 1 1 -15 15 gray.cm ${date}.rmli.bmp 0 0
    fi
done < dates


