#!/bin/bash -e

# Step 1: Read in the original data

workdir="$1"
ref_date="$2"
polar="$3"
sw_start_num="$4"
swn_number="$5"

cd ${workdir}
if [ -e input_files ];then rm -r input_files; fi
mkdir -p input_files
cd ${workdir}/input_files

rm -f dates dates_tmp0 tmp_dates tmp_fileID tmp_polar

cd ${workdir}/input_files_orig
for zip_file in `ls -F *.zip`
do
	fileID=`echo ${zip_file%.zip}`
	date=`echo $fileID | awk -F"-" '{print "20"$2}'`
	echo ${fileID} >> ${workdir}/input_files/tmp_fileID
	echo ${date} >> ${workdir}/input_files/tmp_dates
	echo ${polar} >> ${workdir}/input_files/tmp_polar
	echo ${sw_start_num} >> ${workdir}/input_files/tmp_sw_start_num
	echo ${swn_number} >> ${workdir}/input_files/tmp_swn_number
done
cd ${workdir}/input_files
sort tmp_dates | uniq >> dates
sort tmp_fileID | uniq >> fileIDs

paste dates fileIDs tmp_polar tmp_sw_start_num tmp_swn_number > dates_tmp0

rm tmp_dates tmp_fileID tmp_polar tmp_sw_start_num tmp_swn_number

# Data imported in SCOMPLEX format to spare disk space
# run_all.pl dates_tmp0 'PALSAR_import_SLC_from_zipfile.py ../input_files_orig/*$2*.zip $1 --pol $3 --sw_start $4 --swn $5 --scpx --out_dir $2 --refine --kml --clean'
run_all.pl dates_tmp0 'PALSAR_import_SLC_from_zipfile.py ../input_files_orig/*$2*.zip $1 --pol $3 --sw_start $4 --swn $5 --scpx --refine --kml --clean'

rm -f dates_tmp0

cd ../


