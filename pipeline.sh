#!/bin/bash

for video in "$@"; do
  video_dir=`dirname $video`/`basename $video .mp4`
  mkdir $video_dir
  ffmpeg -i $video -f image2 $video_dir/%d.png
  ./map.sh $video_dir
  rm -rf $video_dir
done
