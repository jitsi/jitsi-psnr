#!/bin/sh

for video_path in "$@"; do
  frames_dirname=`dirname $video_path`/`basename $video_path .mp4`
  frames_map=$frames_dirname.map
  trimmed_map=$frames_map.trimmed
  augmented_map=$frames_dirname.augmented
  video_desc=$frames_dirname.desc

  if [ ! -f $frames_map ]; then
    if [ ! -d $frames_dirname ]; then
      mkdir $frames_dirname
      ffmpeg -i $video_path -f image2 $frames_dirname/%d.png
    fi

    ./map.sh $frames_dirname | tee $frames_map
    # rm -rf $frames_dirname
  fi

  if [ ! -f $trimmed_map ]; then
    cat $frames_map \
      | python3 analyze.py trim | tee $trimmed_map
  fi

  if [ ! -f $augmented_map ]; then
    cat $trimmed_map \
      | python3 analyze.py augment | tee $augmented_map
  fi

  if [ ! -f $frames_dirname.psnr ]; then
    echo skip
    #cat $frames_dirname.map-trimmed \
    #  | python3 analyze.py psnr-map \
    #  | ./compare.sh > $frames_dirname.psnr
  fi

  if [ ! -f $video_desc ]; then
    cat $augmented_map | python3 analyze.py describe | tee $video_desc
  fi
done
