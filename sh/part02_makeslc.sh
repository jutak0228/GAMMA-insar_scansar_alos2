#!/bin/bash -e

# Step 2: Generation of SLC mosaic and MLI mosaic (for the reference 20161018)

workdir="$1"
ref_date="$2"
polar="$3"
rglks="$4"
azlks="$5"

cd ${workdir}/input_files

# ref_dir=`cat fileIDs | head -n 1 | tail -n 1`

# cd ${ref_dir}

SLC_mosaic_ScanSAR ${ref_date}_${polar}.SLC_tab ${ref_date}.slc ${ref_date}.slc.par $rglks $azlks 1
multi_look ${ref_date}.slc ${ref_date}.slc.par ${ref_date}.mli ${ref_date}.mli.par $rglks $azlks - - 0.000001
range_samples=`cat ${ref_date}.mli.par | grep "range_samples" | awk -F":" '{print $2}' | tr -d [:space:] | sed -e "s/[^0-9]//g"`
azimuth_lines=`cat ${ref_date}.mli.par | grep "azimuth_lines" | awk -F":" '{print $2}' | tr -d [:space:] | sed -e "s/[^0-9]//g"`
ras_dB ${ref_date}.mli $range_samples 1 $azimuth_lines 1 1 -15 15 gray.cm ${ref_date}.mli.bmp 0 0

cd ${workdir}
