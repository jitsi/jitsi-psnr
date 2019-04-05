#!/bin/sh
for i in $1/*.png; do
  ffmpeg -i $i -pix_fmt yuv420p `dirname $i`/`basename $i .png`.y4m
done
