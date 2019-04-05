#!/bin/sh

REFERENCE_DIR=~/Videos/FourPeople_1280x720_60_sequenced_templated

for video_path in "$@"; do
  frames_dirname=`dirname $video_path`/`basename $video_path .mp4`
  frames_map=$frames_dirname.map
  trimmed_map=$frames_map.trimmed
  augmented_map=$frames_dirname.augmented
  video_desc=$frames_dirname.desc
  psnr_result=$frames_dirname.psnr

  if [ ! -f $frames_map ]; then
    if [ ! -d $frames_dirname ]; then
      mkdir $frames_dirname
      ffmpeg -i $video_path -f image2 $frames_dirname/%d.png
    fi
    
    ./map.sh $frames_dirname | tee $frames_map
  fi

  if [ ! -f $trimmed_map ]; then
    cat $frames_map \
      | python3 analyze.py trim | tee $trimmed_map
  fi

  if [ ! -f $augmented_map ]; then
    cat $trimmed_map \
      | python3 analyze.py augment | tee $augmented_map
  fi

  if [ ! -f $psnr_result ]; then
    cat $trimmed_map \
      | python3 psnr.py 2> $frames_dirname.reverse-map-err > $frames_dirname.reverse-map
    ./compare.sh $frames_dirname.reverse-map $frames_dirname $REFERENCE_DIR template.png | tee $psnr_result
  fi

  if [ ! -f $video_desc ]; then
    cat $augmented_map | python3 analyze.py describe | tee $video_desc
  fi
  
  # rm -rf $frames_dirname
done
