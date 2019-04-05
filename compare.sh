#!/bin/bash
#set -e
#set -x

if [[ -z "$1" || -z "$2" ]] ;then
  echo "Usage: $0 <file.png> <reference-frame-id>"
  exit 1
fi

capture_dir=$2
reference_dir=$3
template_file=$4
tmp=`mktemp -d`
# while read source_frame capture_frame; do
for line in `cat $1`
do
  source_frame=`echo $line | cut -d',' -f1`
  capture_frame=`echo $line | cut -d',' -f2`
  
  capture_file="${capture_dir}/$capture_frame.png"
  if [ ! -f $capture_file ]; then
    continue
  fi
  reference_file="${reference_dir}/$source_frame.y4m"

  rendered="${tmp}/${capture_frame}"
  if [ ! -f $rendered.y4m ]; then
    convert "$template_file" "${capture_file}" -gravity center -compose blend -composite "${rendered}.png"
    ffmpeg -loglevel quiet -i ${rendered}.png -pix_fmt yuv420p ${rendered}.y4m
  fi

  #[Parsed_psnr_0 @ 0x7fa19640cfc0] PSNR y:33.043090 u:47.720991 v:47.155299 average:34.725616 min:34.725616 max:34.725616
  psnr_line=`ffmpeg -i "$reference_file" -i "${rendered}.y4m" -lavfi psnr -f null - 2>&1 | grep Parsed_psnr`

  #Get the luma value (y:33.043090)
  psnr=`echo $psnr_line | awk '{print $5}' | sed -e 's/.*://'`
  echo $source_frame $capture_frame $psnr
done

rm -rf $tmp
