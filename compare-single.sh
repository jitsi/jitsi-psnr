#!/bin/bash
set -e
#set -x

if [[ -z "$1" || -z "$2" ]] ;then
  echo "Usage: $0 <file.png> <reference-frame-id>"
  exit 1
fi

. env.sh

echo "Compare single $1 $2" >&2
reference_file="${SEQUENCE_TEMPLATE_DIR}/$2.y4m"

tmp=`mktemp -d`
rendered="${tmp}/rendered"
$CONVERT "$TEMPLATE_FILE" "$1" -gravity center -compose blend -composite "${rendered}.png"
$FFMPEG -i "${rendered}.png" -pix_fmt yuv420p "${rendered}.y4m" 2> /dev/null > /dev/null

#[Parsed_psnr_0 @ 0x7fa19640cfc0] PSNR y:33.043090 u:47.720991 v:47.155299 average:34.725616 min:34.725616 max:34.725616
psnr_line=`$FFMPEG -i "$reference_file" -i "${rendered}.y4m" -lavfi psnr -f null - 2>&1 | grep Parsed_psnr`

#Get the luma value (y:33.043090)
psnr=`echo $psnr_line | awk '{print $5}' | sed -e 's/.*://'`

rm -rf $tmp

echo -n $psnr
