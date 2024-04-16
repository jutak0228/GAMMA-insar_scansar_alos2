#!/bin/bash

workdir="$1"
ref_date="$2"

cd ${workdir}/slc

for file in `ls *_${polar}.slc`
do
	date=`echo $line | sed -e "s/[^0-9]//g"`
	# mkdir -p ${date}
	# cd ${date}
	ionosphere_check ${file} ${file}.par 256 256 0.1 64 64

done
