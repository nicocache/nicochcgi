#!/bin/bash
cd `dirname $0`
for d in *
do
if [ -d $d ];then
  cd $d
  if [ ! -e thumbs ]; then mkdir thumbs; fi
  for f in *.mp4
  do
    t="thumbs/${f%.*}.jpg"
    if [ ! -e "$t" ]; then 
      ffmpeg -i "$f" -ss 6 -vframes 1 -f image2 -vf scale=-1:720 "$t"
    fi
  done
  cd ..
fi
done


