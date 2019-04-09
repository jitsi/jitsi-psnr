#!/bin/bash
#set -e
#set -x

reference_frames=$1
reconstructed_frames=$2

if [ ! -d "$1" -o ! -d "$2" ] ;then
  echo "Usage: $0 reference-frames reconstructed-frames"
  exit 1
fi


template_file=template.png
tmp=`mktemp -d`
for line in `cat /dev/stdin`
do
  reference_frame_id=`echo $line | cut -d',' -f1`
  reconstructed_frame_id=`echo $line | cut -d',' -f2`
  
  reconstructed_frame="${reconstructed_frames}/$reconstructed_frame_id.png"
  if [ ! -f $reconstructed_frame ]; then
    continue
  fi
  reference_frame="${reference_frames}/$reference_frame_id.y4m"

  rendered="${tmp}/${reconstructed_frame_id}"
  if [ ! -f $rendered.y4m ]; then
    convert "$template_file" "${reconstructed_frame}" -gravity center -compose blend -composite "${rendered}.png"
    ffmpeg -loglevel quiet -i ${rendered}.png -pix_fmt yuv420p ${rendered}.y4m
  fi

  #[Parsed_psnr_0 @ 0x7fa19640cfc0] PSNR y:33.043090 u:47.720991 v:47.155299 average:34.725616 min:34.725616 max:34.725616
  psnr_line=`ffmpeg -i "$reference_frame" -i "${rendered}.y4m" -lavfi psnr -f null - 2>&1 | grep Parsed_psnr`

  #Get the luma value (y:33.043090)
  psnr=`echo $psnr_line | awk '{print $5}' | sed -e 's/.*://'`
  echo $reference_frame_id $reconstructed_frame_id $psnr
done

rm -rf $tmp
